// lib/services/transaction_service.dart
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../models/inventory.dart';
import '../models/inventory_movement.dart';
import 'api_service.dart';
import 'database_service.dart';
import '../config/constants.dart';

class TransactionService {
  final Logger logger = Logger();
  late DatabaseService _databaseService;
  late ApiService _apiService;
  
  // Singleton pattern
  static final TransactionService _instance = TransactionService._internal();
  
  factory TransactionService() {
    return _instance;
  }
  
  TransactionService._internal() {
    _databaseService = DatabaseService();
    _apiService = ApiService(baseUrl: AppConstants.apiBaseUrl);
  }
  
  // Get inventory items with optional filtering
  Future<List<InventoryItem>> getInventoryItems({
    int? branchId,
    int? productId,
    bool? lowStock,
    String? search,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    try {
      // Try to get from API first
      try {
        final queryParams = <String, String>{
          'page': page.toString(),
          'limit': limit.toString(),
        };
        
        if (branchId != null) {
          queryParams['branch_id'] = branchId.toString();
        }
        
        if (productId != null) {
          queryParams['product_id'] = productId.toString();
        }
        
        if (lowStock != null) {
          queryParams['low_stock'] = lowStock ? '1' : '0';
        }
        
        if (search != null) {
          queryParams['search'] = search;
        }
        
        final response = await _apiService.get(
          '/inventory',
          queryParams: queryParams,
          token: token,
        );
        
        final List<dynamic> data = response['data'];
        final List<InventoryItem> items = data
            .map((item) => InventoryItem.fromJson(item))
            .toList();
        
        // Save to local database for offline use
        _saveInventoryItemsToLocalDB(items);
        
        return items;
      } catch (e) {
        logger.w('Failed to get inventory from API, using local data: $e');
      }
      
      // If offline or API call fails, get from local database
      final db = await _databaseService.database;
      
      // Build the query
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (branchId != null) {
        whereClause += 'i.branch_id = ?';
        whereArgs.add(branchId);
      }
      
      if (productId != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'i.product_id = ?';
        whereArgs.add(productId);
      }
      
      if (lowStock == true) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'i.quantity <= i.min_stock_level';
      }
      
      if (search != null && search.isNotEmpty) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += '(p.name LIKE ? OR p.sku LIKE ? OR p.barcode LIKE ?)';
        whereArgs.add('%$search%');
        whereArgs.add('%$search%');
        whereArgs.add('%$search%');
      }
      
      // Join with products and branches
      String query = '''
      SELECT i.*, p.name as product_name, p.sku as product_sku, b.name as branch_name
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      JOIN branches b ON i.branch_id = b.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY ${lowStock == true ? 'i.quantity / i.min_stock_level ASC' : 'p.name ASC'}
      LIMIT ? OFFSET ?
      ''';
      
      whereArgs.add(limit);
      whereArgs.add((page - 1) * limit);
      
      final results = await db.rawQuery(query, whereArgs);
      
      return results.map((item) {
        final inventoryMap = Map<String, dynamic>.from(item);
        // Add product and branch name
        inventoryMap['product_name'] = item['product_name'];
        inventoryMap['branch_name'] = item['branch_name'];
        
        return InventoryItem.fromJson(inventoryMap);
      }).toList();
    } catch (e) {
      logger.e('Error getting inventory items: $e');
      rethrow;
    }
  }
  
  // Get inventory item by product and branch
  Future<InventoryItem?> getInventoryItemByProductAndBranch(
    int productId,
    int branchId,
  ) async {
    try {
      // Get from local database
      final db = await _databaseService.database;
      
      final query = '''
      SELECT i.*, p.name as product_name, p.sku as product_sku, b.name as branch_name
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      JOIN branches b ON i.branch_id = b.id
      WHERE i.product_id = ? AND i.branch_id = ?
      LIMIT 1
      ''';
      
      final results = await db.rawQuery(query, [productId, branchId]);
      
      if (results.isEmpty) {
        return null;
      }
      
      final inventoryMap = Map<String, dynamic>.from(results.first);
      // Add product and branch name
      inventoryMap['product_name'] = results.first['product_name'];
      inventoryMap['branch_name'] = results.first['branch_name'];
      
      return InventoryItem.fromJson(inventoryMap);
    } catch (e) {
      logger.e('Error getting inventory item by product and branch: $e');
      rethrow;
    }
  }
  
  // Create or update inventory item
  Future<InventoryItem> createOrUpdateInventoryItem(
    InventoryItem item,
    {String? token}
  ) async {
    try {
      // Try to create/update via API first
      try {
        final endpoint = item.id != 0 ? 
          '/inventory/${item.id}' : 
          '/inventory';
        
        final method = item.id != 0 ? 'put' : 'post';
        
        final response = method == 'put' ? 
          await _apiService.put(endpoint, item.toJson(), token: token) : 
          await _apiService.post(endpoint, item.toJson(), token: token);
        
        final updatedItem = InventoryItem.fromJson(response['data']);
        
        // Save to local database
        await _saveInventoryItemToLocalDB(updatedItem);
        
        return updatedItem;
      } catch (e) {
        logger.w('Failed to create/update inventory item via API, saving locally: $e');
      }
      
      // If offline or API call fails, save to local database
      final db = await _databaseService.database;
      
      // Check if item exists
      final existingItems = await db.query(
        'inventory',
        where: 'product_id = ? AND branch_id = ?',
        whereArgs: [item.productId, item.branchId],
        limit: 1,
      );
      
      final now = DateTime.now().toIso8601String();
      
      if (existingItems.isEmpty) {
        // Create new item
        final id = await db.insert(
          'inventory',
          {
            'product_id': item.productId,
            'branch_id': item.branchId,
            'quantity': item.quantity,
            'reserved_quantity': item.reservedQuantity,
            'min_stock_level': item.minStockLevel,
            'max_stock_level': item.maxStockLevel,
            'reorder_point': item.reorderPoint,
            'shelf_location': item.shelfLocation,
            'last_stock_update': now,
            'created_at': now,
            'updated_at': now,
          },
        );
        
        // Create a new instance with updated properties
        return InventoryItem(
          id: id,
          productId: item.productId,
          branchId: item.branchId,
          branchName: item.branchName,
          quantity: item.quantity,
          reservedQuantity: item.reservedQuantity,
          minStockLevel: item.minStockLevel,
          maxStockLevel: item.maxStockLevel,
          reorderPoint: item.reorderPoint,
          shelfLocation: item.shelfLocation,
          lastStockUpdate: now,
          lastCountingDate: item.lastCountingDate,
          createdAt: now,
          updatedAt: now
        );
      } else {
        // Update existing item
        final existingItem = existingItems.first;
        await db.update(
          'inventory',
          {
            'quantity': item.quantity,
            'reserved_quantity': item.reservedQuantity,
            'min_stock_level': item.minStockLevel,
            'max_stock_level': item.maxStockLevel,
            'reorder_point': item.reorderPoint,
            'shelf_location': item.shelfLocation,
            'last_stock_update': now,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [existingItem['id']],
        );
        
        // Create a new instance with updated properties
        return InventoryItem(
          id: existingItem['id'] as int,
          productId: item.productId,
          branchId: item.branchId,
          branchName: item.branchName,
          quantity: item.quantity,
          reservedQuantity: item.reservedQuantity,
          minStockLevel: item.minStockLevel,
          maxStockLevel: item.maxStockLevel,
          reorderPoint: item.reorderPoint,
          shelfLocation: item.shelfLocation,
          lastStockUpdate: now,
          lastCountingDate: item.lastCountingDate,
          createdAt: existingItem['created_at'] as String,
          updatedAt: now
        );
      }
    } catch (e) {
      logger.e('Error creating/updating inventory item: $e');
      rethrow;
    }
  }
  
  // Update inventory quantity
  Future<bool> updateInventoryQuantity(
    int productId,
    int branchId,
    double newQuantity,
    {String? token}
  ) async {
    try {
      // Try to update via API first
      try {
        final response = await _apiService.post(
          '/inventory/update-quantity',
          {
            'product_id': productId,
            'branch_id': branchId,
            'quantity': newQuantity,
          },
          token: token,
        );
        
        final success = response['success'] == true;
        
        if (success) {
          // Update local database
          await _updateLocalInventoryQuantity(productId, branchId, newQuantity);
        }
        
        return success;
      } catch (e) {
        logger.w('Failed to update inventory quantity via API, updating locally: $e');
      }
      
      // If offline or API call fails, update local database only
      return await _updateLocalInventoryQuantity(productId, branchId, newQuantity);
    } catch (e) {
      logger.e('Error updating inventory quantity: $e');
      rethrow;
    }
  }
  
  // Update local inventory quantity
  Future<bool> _updateLocalInventoryQuantity(
    int productId,
    int branchId,
    double newQuantity,
  ) async {
    try {
      final db = await _databaseService.database;
      
      // Check if inventory item exists
      final existingItems = await db.query(
        'inventory',
        where: 'product_id = ? AND branch_id = ?',
        whereArgs: [productId, branchId],
        limit: 1,
      );
      
      final now = DateTime.now().toIso8601String();
      
      if (existingItems.isEmpty) {
        // Create new inventory item if it doesn't exist
        await db.insert(
          'inventory',
          {
            'product_id': productId,
            'branch_id': branchId,
            'quantity': newQuantity,
            'reserved_quantity': 0.0,
            'min_stock_level': 0,
            'last_stock_update': now,
            'created_at': now,
            'updated_at': now,
          },
        );
      } else {
        // Update existing item
        await db.update(
          'inventory',
          {
            'quantity': newQuantity,
            'last_stock_update': now,
            'updated_at': now,
          },
          where: 'product_id = ? AND branch_id = ?',
          whereArgs: [productId, branchId],
        );
      }
      
      return true;
    } catch (e) {
      logger.e('Error updating local inventory quantity: $e');
      return false;
    }
  }
  
  // Add inventory transaction
  Future<bool> addInventoryTransaction(
    int productId,
    int branchId,
    String transactionType,
    double quantity,
    {String? referenceType, int? referenceId, double? unitPrice, String? token}
  ) async {
    try {
      // Try to add via API first
      try {
        final data = {
          'product_id': productId,
          'branch_id': branchId,
          'transaction_type': transactionType,
          'quantity': quantity,
          'reference_type': referenceType,
          'reference_id': referenceId,
          'unit_price': unitPrice,
        };
        
        await _apiService.post(
          '/inventory/transactions',
          data,
          token: token,
        );
        
        // Also add to local database
        await _addLocalInventoryTransaction(
          productId,
          branchId,
          transactionType,
          quantity,
          referenceType: referenceType,
          referenceId: referenceId,
          unitPrice: unitPrice,
        );
        
        return true;
      } catch (e) {
        logger.w('Failed to add inventory transaction via API, adding locally: $e');
      }
      
      // If offline or API call fails, add to local database only
      return await _addLocalInventoryTransaction(
        productId,
        branchId,
        transactionType,
        quantity,
        referenceType: referenceType,
        referenceId: referenceId,
        unitPrice: unitPrice,
      );
    } catch (e) {
      logger.e('Error adding inventory transaction: $e');
      return false;
    }
  }
  
  // Add local inventory transaction
  Future<bool> _addLocalInventoryTransaction(
    int productId,
    int branchId,
    String transactionType,
    double quantity,
    {String? referenceType, int? referenceId, double? unitPrice}
  ) async {
    try {
      final db = await _databaseService.database;
      
      await db.insert(
        'inventory_transactions',
        {
          'transaction_date': DateTime.now().toIso8601String(),
          'product_id': productId,
          'branch_id': branchId,
          'transaction_type': transactionType,
          'quantity': quantity,
          'reference_type': referenceType,
          'reference_id': referenceId,
          'unit_price': unitPrice,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      
      return true;
    } catch (e) {
      logger.e('Error adding local inventory transaction: $e');
      return false;
    }
  }
  
  // Get inventory transactions
  Future<List<InventoryMovement>> getInventoryTransactions({
    int? productId,
    int? branchId,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    try {
      // Try to get from API first
      try {
        final queryParams = <String, String>{
          'page': page.toString(),
          'limit': limit.toString(),
        };
        
        if (productId != null) {
          queryParams['product_id'] = productId.toString();
        }
        
        if (branchId != null) {
          queryParams['branch_id'] = branchId.toString();
        }
        
        if (transactionType != null) {
          queryParams['transaction_type'] = transactionType;
        }
        
        if (startDate != null) {
          queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
        }
        
        if (endDate != null) {
          queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
        }
        
        final response = await _apiService.get(
          '/inventory/transactions',
          queryParams: queryParams,
          token: token,
        );
        
        final List<dynamic> data = response['data'];
        return data.map((item) => InventoryMovement.fromMap(item)).toList();
      } catch (e) {
        logger.w('Failed to get inventory transactions from API, using local data: $e');
      }
      
      // If offline or API call fails, get from local database
      final db = await _databaseService.database;
      
      // Build the query
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (productId != null) {
        whereClause += 'it.product_id = ?';
        whereArgs.add(productId);
      }
      
      if (branchId != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'it.branch_id = ?';
        whereArgs.add(branchId);
      }
      
      if (transactionType != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'it.transaction_type = ?';
        whereArgs.add(transactionType);
      }
      
      if (startDate != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'it.transaction_date >= ?';
        whereArgs.add(DateFormat('yyyy-MM-dd').format(startDate));
      }
      
      if (endDate != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'it.transaction_date <= ?';
        whereArgs.add(DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1))));
      }
      
      // Join with products to get names
      String query = '''
      SELECT it.*, p.name as product_name, p.sku as product_sku
      FROM inventory_transactions it
      JOIN products p ON it.product_id = p.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY it.transaction_date DESC
      LIMIT ? OFFSET ?
      ''';
      
      whereArgs.add(limit);
      whereArgs.add((page - 1) * limit);
      
      final results = await db.rawQuery(query, whereArgs);
      
      return results.map((item) {
        // Correctly convert the date string to DateTime
        final dateStr = item['transaction_date'] as String?;
        final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
        
        return InventoryMovement(
          id: item['id'] as int,
          productId: item['product_id'] as int,
          productName: item['product_name'] as String? ?? 'Unknown Product',
          productSku: item['product_sku'] as String?,
          date: date,
          type: item['transaction_type'] as String,
          quantity: item['quantity'] is int ? 
            (item['quantity'] as int).toDouble() : 
            (item['quantity'] as double? ?? 0.0),
          referenceType: item['reference_type'] as String?,
          referenceId: item['reference_id'] as int?,
          unitPrice: item['unit_price'] != null ? 
            (item['unit_price'] is int ? 
              (item['unit_price'] as int).toDouble() : 
              item['unit_price'] as double) : null,
          branchId: item['branch_id'] as int,
          createdAt: item['created_at'] as String?,
        );
      }).toList();
    } catch (e) {
      logger.e('Error getting inventory transactions: $e');
      rethrow;
    }
  }
  
  // Get low stock items
  Future<List<InventoryItem>> getLowStockItems({
    int? branchId,
    int? categoryId,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    try {
      // Try to get from API first
      try {
        final queryParams = <String, String>{
          'page': page.toString(),
          'limit': limit.toString(),
        };
        
        if (branchId != null) {
          queryParams['branch_id'] = branchId.toString();
        }
        
        if (categoryId != null) {
          queryParams['category_id'] = categoryId.toString();
        }
        
        final response = await _apiService.get(
          '/inventory/low-stock',
          queryParams: queryParams,
          token: token,
        );
        
        final List<dynamic> data = response['data'];
        return data.map((item) => InventoryItem.fromJson(item)).toList();
      } catch (e) {
        logger.w('Failed to get low stock items from API, using local data: $e');
      }
      
      // If offline or API call fails, get from local database
      return getInventoryItems(
        branchId: branchId,
        lowStock: true,
        page: page,
        limit: limit,
      );
    } catch (e) {
      logger.e('Error getting low stock items: $e');
      rethrow;
    }
  }
  
  // Save inventory items to local database
  Future<void> _saveInventoryItemsToLocalDB(List<InventoryItem> items) async {
    try {
      await _databaseService.transaction((txn) async {
        for (var item in items) {
          // Check if item exists
          final existingItems = await txn.query(
            'inventory',
            where: 'product_id = ? AND branch_id = ?',
            whereArgs: [item.productId, item.branchId],
            limit: 1,
          );
          
          if (existingItems.isEmpty) {
            // Insert new item
            await txn.insert(
              'inventory',
              {
                'id': item.id,
                'product_id': item.productId,
                'branch_id': item.branchId,
                'quantity': item.quantity,
                'reserved_quantity': item.reservedQuantity,
                'min_stock_level': item.minStockLevel,
                'max_stock_level': item.maxStockLevel,
                'reorder_point': item.reorderPoint,
                'shelf_location': item.shelfLocation,
                'last_stock_update': item.lastStockUpdate,
                'last_counting_date': item.lastCountingDate,
                'created_at': item.createdAt,
                'updated_at': item.updatedAt,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } else {
            // Update existing item
            await txn.update(
              'inventory',
              {
                'quantity': item.quantity,
                'reserved_quantity': item.reservedQuantity,
                'min_stock_level': item.minStockLevel,
                'max_stock_level': item.maxStockLevel,
                'reorder_point': item.reorderPoint,
                'shelf_location': item.shelfLocation,
                'last_stock_update': item.lastStockUpdate,
                'last_counting_date': item.lastCountingDate,
                'updated_at': item.updatedAt,
              },
              where: 'product_id = ? AND branch_id = ?',
              whereArgs: [item.productId, item.branchId],
            );
          }
        }
      });
    } catch (e) {
      logger.e('Error saving inventory items to local DB: $e');
    }
  }
  
  // Save a single inventory item to local database
  Future<void> _saveInventoryItemToLocalDB(InventoryItem item) async {
    try {
      final db = await _databaseService.database;
      
      // Check if item exists
      final existingItems = await db.query(
        'inventory',
        where: 'product_id = ? AND branch_id = ?',
        whereArgs: [item.productId, item.branchId],
        limit: 1,
      );
      
      if (existingItems.isEmpty) {
        // Insert new item
        await db.insert(
          'inventory',
          {
            'id': item.id,
            'product_id': item.productId,
            'branch_id': item.branchId,
            'quantity': item.quantity,
            'reserved_quantity': item.reservedQuantity,
            'min_stock_level': item.minStockLevel,
            'max_stock_level': item.maxStockLevel,
            'reorder_point': item.reorderPoint,
            'shelf_location': item.shelfLocation,
            'last_stock_update': item.lastStockUpdate,
            'last_counting_date': item.lastCountingDate,
            'created_at': item.createdAt,
            'updated_at': item.updatedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        // Update existing item
        await db.update(
          'inventory',
          {
            'quantity': item.quantity,
            'reserved_quantity': item.reservedQuantity,
            'min_stock_level': item.minStockLevel,
            'max_stock_level': item.maxStockLevel,
            'reorder_point': item.reorderPoint,
            'shelf_location': item.shelfLocation,
            'last_stock_update': item.lastStockUpdate,
            'last_counting_date': item.lastCountingDate,
            'updated_at': item.updatedAt,
          },
          where: 'product_id = ? AND branch_id = ?',
          whereArgs: [item.productId, item.branchId],
        );
      }
    } catch (e) {
      logger.e('Error saving inventory item to local DB: $e');
    }
  }
}