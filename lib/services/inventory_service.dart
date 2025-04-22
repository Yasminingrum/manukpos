// lib/services/inventory_service.dart
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import '../models/inventory.dart';
import 'api_service.dart';
import 'database_service.dart';
import '../config/constants.dart';

class InventoryService {
  final Logger logger = Logger();
  late DatabaseService _databaseService;
  late ApiService _apiService;
  
  // Singleton pattern
  static final InventoryService _instance = InventoryService._internal();
  
  factory InventoryService() {
    return _instance;
  }
  
  InventoryService._internal() {
    _databaseService = DatabaseService();
    _apiService = ApiService(baseUrl: AppConstants.apiBaseUrl);
  }
  
  // Get inventory items with optional filtering
  Future<List<InventoryItem>> getInventoryItems({
    int? branchId,
    int? productId,
    bool? lowStockOnly,
    String? search,
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
        
        if (branchId != null) queryParams['branch_id'] = branchId.toString();
        if (productId != null) queryParams['product_id'] = productId.toString();
        if (lowStockOnly != null) queryParams['low_stock_only'] = lowStockOnly ? '1' : '0';
        if (search != null) queryParams['search'] = search;
        if (categoryId != null) queryParams['category_id'] = categoryId.toString();
        
        final response = await _apiService.get(
          '/inventory',
          queryParams: queryParams,
          token: token,
        );
        
        final List<dynamic> data = response['data'];
        final List<InventoryItem> inventoryItems = data
            .map((item) => InventoryItem.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // Save to local database for offline use
        _saveInventoryToLocalDB(inventoryItems);
        
        return inventoryItems;
      } catch (e) {
        logger.w('Failed to get inventory from API, using local data: $e');
      }
      
      // If offline or API call fails, get from local database
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (branchId != null) {
        whereClause += 'branch_id = ?';
        whereArgs.add(branchId);
      }
      
      if (productId != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'product_id = ?';
        whereArgs.add(productId);
      }
      
      if (lowStockOnly == true) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'quantity <= min_stock_level';
      }
      
      // For search and category filtering, we need to join with products table
      String query = '''
      SELECT i.*, p.name as product_name, p.sku as product_sku, b.name as branch_name
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      JOIN branches b ON i.branch_id = b.id
      ''';
      
      if (whereClause.isNotEmpty) {
        query += ' WHERE $whereClause';
      }
      
      if (search != null) {
        if (whereClause.isNotEmpty) {
          query += ' AND (p.name LIKE ? OR p.sku LIKE ?)';
        } else {
          query += ' WHERE (p.name LIKE ? OR p.sku LIKE ?)';
        }
        whereArgs.add('%$search%');
        whereArgs.add('%$search%');
      }
      
      if (categoryId != null) {
        if (whereClause.isNotEmpty || search != null) {
          query += ' AND p.category_id = ?';
        } else {
          query += ' WHERE p.category_id = ?';
        }
        whereArgs.add(categoryId);
      }
      
      query += ' ORDER BY p.name ASC LIMIT ? OFFSET ?';
      whereArgs.add(limit);
      whereArgs.add((page - 1) * limit);
      
      final db = await _databaseService.database;
      final results = await db.rawQuery(query, whereArgs);
      
      return results.map((map) {
        // Combine inventory data with product and branch data
        final inventoryMap = <String, dynamic>{
          'id': map['id'],
          'product_id': map['product_id'],
          'branch_id': map['branch_id'],
          'branch_name': map['branch_name'],
          'quantity': map['quantity'],
          'reserved_quantity': map['reserved_quantity'],
          'min_stock_level': map['min_stock_level'],
          'max_stock_level': map['max_stock_level'],
          'reorder_point': map['reorder_point'],
          'shelf_location': map['shelf_location'],
          'last_stock_update': map['last_stock_update'],
          'last_counting_date': map['last_counting_date'],
          'created_at': map['created_at'],
          'updated_at': map['updated_at'],
        };
        
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
    {String? token}
  ) async {
    try {
      // Try to get from API first
      try {
        final response = await _apiService.get(
          '/inventory/product/$productId/branch/$branchId',
          token: token,
        );
        
        final InventoryItem inventoryItem = InventoryItem.fromJson(response['data'] as Map<String, dynamic>);
        
        // Update in local database
        await _saveInventoryToLocalDB([inventoryItem]);
        
        return inventoryItem;
      } catch (e) {
        logger.w('Failed to get inventory item from API, using local data: $e');
      }
      
      // If offline or API call fails, get from local database
      final db = await _databaseService.database;
      final results = await db.query(
        'inventory',
        where: 'product_id = ? AND branch_id = ?',
        whereArgs: [productId, branchId],
        limit: 1,
      );
      
      if (results.isEmpty) {
        return null;
      }
      
      return InventoryItem.fromJson(results.first);
    } catch (e) {
      logger.e('Error getting inventory item: $e');
      rethrow;
    }
  }
  
  // Update inventory quantity
  Future<InventoryItem> updateInventoryQuantity(
    int productId, 
    int branchId, 
    double newQuantity,
    {String? token}
  ) async {
    try {
      // Try to update through API first
      try {
        final response = await _apiService.put(
          '/inventory/update-quantity',
          {
            'product_id': productId,
            'branch_id': branchId,
            'quantity': newQuantity,
          },
          token: token,
        );
        
        final InventoryItem inventoryItem = InventoryItem.fromJson(response['data'] as Map<String, dynamic>);
        
        // Update in local database
        await _saveInventoryToLocalDB([inventoryItem]);
        
        return inventoryItem;
      } catch (e) {
        logger.w('Failed to update inventory through API, updating locally: $e');
      }
      
      // If offline or API call fails, update locally
      final db = await _databaseService.database;
      
      // Check if inventory item exists
      final existingItems = await db.query(
        'inventory',
        where: 'product_id = ? AND branch_id = ?',
        whereArgs: [productId, branchId],
        limit: 1,
      );
      
      if (existingItems.isEmpty) {
        // Create new inventory item if it doesn't exist
        final newItem = <String, dynamic>{
          'product_id': productId,
          'branch_id': branchId,
          'quantity': newQuantity,
          'reserved_quantity': 0.0,
          'min_stock_level': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'last_stock_update': DateTime.now().toIso8601String(),
        };
        
        final id = await db.insert('inventory', newItem);
        newItem['id'] = id;
        
        return InventoryItem.fromJson(newItem);
      } else {
        // Update existing inventory item
        final item = existingItems.first;
        final updatedItem = <String, dynamic>{
          'quantity': newQuantity,
          'updated_at': DateTime.now().toIso8601String(),
          'last_stock_update': DateTime.now().toIso8601String(),
        };
        
        await db.update(
          'inventory',
          updatedItem,
          where: 'id = ?',
          whereArgs: [item['id']],
        );
        
        // Get updated item
        final updatedItems = await db.query(
          'inventory',
          where: 'id = ?',
          whereArgs: [item['id']],
          limit: 1,
        );
        
        return InventoryItem.fromJson(updatedItems.first);
      }
    } catch (e) {
      logger.e('Error updating inventory quantity: $e');
      rethrow;
    }
  }
  
  // Add inventory transaction (for stock movements)
  Future<void> addInventoryTransaction(
    int productId, 
    int branchId, 
    String transactionType, 
    double quantity, 
    {
      String? referenceType,
      int? referenceId,
      double? unitPrice,
      String? notes,
      int? userId,
      String? token,
    }
  ) async {
    try {
      final transaction = <String, dynamic>{
        'product_id': productId,
        'branch_id': branchId,
        'transaction_type': transactionType,
        'quantity': quantity,
        'reference_type': referenceType,
        'reference_id': referenceId,
        'unit_price': unitPrice,
        'notes': notes,
        'user_id': userId,
        'transaction_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Try to add through API first
      try {
        await _apiService.post(
          '/inventory/transactions',
          transaction,
          token: token,
        );
      } catch (e) {
        logger.w('Failed to add inventory transaction through API, adding locally: $e');
      }
      
      // Add to local database regardless of API success
      // (if API succeeded, this is for offline access; if it failed, this is the primary record until sync)
      final db = await _databaseService.database;
      await db.insert('inventory_transactions', transaction);
      
      // Update inventory quantity
      // If transaction_type is 'in', add quantity; if 'out', subtract quantity
      final inventoryItem = await getInventoryItemByProductAndBranch(productId, branchId);
      
      double newQuantity = 0;
      if (inventoryItem != null) {
        newQuantity = inventoryItem.quantity;
        if (transactionType == 'in') {
          newQuantity += quantity;
        } else if (transactionType == 'out') {
          newQuantity -= quantity;
          // Ensure quantity doesn't go below zero
          if (newQuantity < 0) newQuantity = 0;
        }
      } else {
        // If inventory item doesn't exist, create it with the transaction quantity
        if (transactionType == 'in') {
          newQuantity = quantity;
        }
      }
      
      await updateInventoryQuantity(productId, branchId, newQuantity);
    } catch (e) {
      logger.e('Error adding inventory transaction: $e');
      rethrow;
    }
  }
  
  // Get low stock products
  Future<List<Map<String, dynamic>>> getLowStockProducts({
    int? branchId,
    int limit = 10,
    String? token,
  }) async {
    try {
      // Try to get from API first
      try {
        final queryParams = <String, String>{
          'limit': limit.toString(),
        };
        
        if (branchId != null) queryParams['branch_id'] = branchId.toString();
        
        final response = await _apiService.get(
          '/inventory/low-stock',
          queryParams: queryParams,
          token: token,
        );
        
        final List<dynamic> data = response['data'];
        return List<Map<String, dynamic>>.from(data);
      } catch (e) {
        logger.w('Failed to get low stock products from API, using local data: $e');
      }
      
      // If offline or API call fails, get from local database
      String query = '''
      SELECT i.*, p.name as product_name, p.sku as product_sku, 
             p.min_stock as min_stock
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      WHERE i.quantity <= p.min_stock
      ''';
      
      if (branchId != null) {
        query += ' AND i.branch_id = ?';
      }
      
      query += ' ORDER BY (i.quantity / NULLIF(p.min_stock, 0)) ASC LIMIT ?';
      
      final List<dynamic> args = [];
      if (branchId != null) args.add(branchId);
      args.add(limit);
      
      final db = await _databaseService.database;
      final results = await db.rawQuery(query, args);
      
      return results.map((item) {
        return <String, dynamic>{
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'product_sku': item['product_sku'],
          'current_stock': item['quantity'],
          'min_stock': item['min_stock'],
          'branch_id': item['branch_id'],
        };
      }).toList();
    } catch (e) {
      logger.e('Error getting low stock products: $e');
      rethrow;
    }
  }
  
  // Get inventory statistics
  Future<Map<String, dynamic>> getInventoryStatistics({
    int? branchId,
    String? token,
  }) async {
    try {
      // Try to get from API first
      try {
        final queryParams = <String, String>{};
        if (branchId != null) queryParams['branch_id'] = branchId.toString();
        
        final response = await _apiService.get(
          '/inventory/statistics',
          queryParams: queryParams,
          token: token,
        );
        
        return response['data'] as Map<String, dynamic>;
      } catch (e) {
        logger.w('Failed to get inventory statistics from API, calculating locally: $e');
      }
      
      // If offline or API call fails, calculate from local database
      final db = await _databaseService.database;
      
      // Set up the query with branch filter if provided
      String branchFilter = branchId != null ? 'AND i.branch_id = $branchId' : '';
      
      // Total products count
      final totalProductsQuery = '''
      SELECT COUNT(DISTINCT i.product_id) as count
      FROM inventory i
      WHERE i.quantity > 0 $branchFilter
      ''';
      final totalProductsResult = await db.rawQuery(totalProductsQuery);
      final totalProducts = Sqflite.firstIntValue(totalProductsResult) ?? 0;
      
      // Total inventory value
      final totalValueQuery = '''
      SELECT SUM(i.quantity * p.buying_price) as value
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      WHERE i.quantity > 0 $branchFilter
      ''';
      final totalValueResult = await db.rawQuery(totalValueQuery);
      final totalValueObj = totalValueResult.first['value'];
      final double totalValue = totalValueObj is int ? 
        (totalValueObj).toDouble() : (totalValueObj as double? ?? 0.0);
      
      // Low stock count
      final lowStockQuery = '''
      SELECT COUNT(*) as count
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      WHERE i.quantity <= p.min_stock AND i.quantity > 0 $branchFilter
      ''';
      final lowStockResult = await db.rawQuery(lowStockQuery);
      final lowStockCount = Sqflite.firstIntValue(lowStockResult) ?? 0;
      
      // Out of stock count
      final outOfStockQuery = '''
      SELECT COUNT(*) as count
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      WHERE i.quantity = 0 $branchFilter
      ''';
      final outOfStockResult = await db.rawQuery(outOfStockQuery);
      final outOfStockCount = Sqflite.firstIntValue(outOfStockResult) ?? 0;
      
      // Category distribution
      final categoryDistributionQuery = '''
      SELECT c.name as category, COUNT(i.product_id) as count
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      WHERE i.quantity > 0 $branchFilter
      GROUP BY c.id
      ORDER BY count DESC
      ''';
      final categoryDistribution = await db.rawQuery(categoryDistributionQuery);
      final Map<String, dynamic> categoryDistributionMap = {};
      for (final item in categoryDistribution) {
        final category = item['category'] as String;
        final count = item['count'];
        categoryDistributionMap[category] = count;
      }
      
      // Category values
      final categoryValuesQuery = '''
      SELECT c.name as category, SUM(i.quantity * p.buying_price) as value
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      WHERE i.quantity > 0 $branchFilter
      GROUP BY c.id
      ORDER BY value DESC
      ''';
      final categoryValues = await db.rawQuery(categoryValuesQuery);
      final Map<String, dynamic> categoryValuesMap = {};
      for (final item in categoryValues) {
        final category = item['category'] as String;
        final valueObj = item['value'];
        final double value = valueObj is int ? valueObj.toDouble() : (valueObj as double? ?? 0.0);
        categoryValuesMap[category] = value;
      }
      
      // Value tiers (for ABC analysis)
      final Map<String, double> valueTiers = {
        'High Value (>1M)': 0.0,
        'Medium Value (100K-1M)': 0.0,
        'Low Value (<100K)': 0.0,
      };
      
      final productValuesQuery = '''
      SELECT i.product_id, (i.quantity * p.buying_price) as value
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      WHERE i.quantity > 0 $branchFilter
      ''';
      final productValues = await db.rawQuery(productValuesQuery);
      
      for (final item in productValues) {
        final valueObj = item['value'];
        final double value = valueObj is int ? valueObj.toDouble() : (valueObj as double? ?? 0.0);
        
        if (value > 1000000) {
          valueTiers['High Value (>1M)'] = (valueTiers['High Value (>1M)'] ?? 0.0) + value;
        } else if (value > 100000) {
          valueTiers['Medium Value (100K-1M)'] = (valueTiers['Medium Value (100K-1M)'] ?? 0.0) + value;
        } else {
          valueTiers['Low Value (<100K)'] = (valueTiers['Low Value (<100K)'] ?? 0.0) + value;
        }
      }
      
      // ABC Analysis (A: top 20% items = 80% value, B: next 30% = 15% value, C: remaining 50% = 5% value)
      List<Map<String, dynamic>> sortedProducts = List<Map<String, dynamic>>.from(productValues);
      sortedProducts.sort((a, b) {
        final valueAObj = a['value'];
        final valueBObj = b['value'];
        final double valueA = valueAObj is int ? valueAObj.toDouble() : (valueAObj as double? ?? 0.0);
        final double valueB = valueBObj is int ? valueBObj.toDouble() : (valueBObj as double? ?? 0.0);
        return valueB.compareTo(valueA);
      });
      
      final totalProductCount = sortedProducts.length;
      final aCount = (totalProductCount * 0.2).ceil();
      final bCount = (totalProductCount * 0.3).ceil();
      
      double aValue = 0;
      double bValue = 0;
      double cValue = 0;
      
      for (int i = 0; i < sortedProducts.length; i++) {
        final valueObj = sortedProducts[i]['value'];
        final double value = valueObj is int ? valueObj.toDouble() : (valueObj as double? ?? 0.0);
        
        if (i < aCount) {
          aValue += value;
        } else if (i < aCount + bCount) {
          bValue += value;
        } else {
          cValue += value;
        }
      }
      
      final Map<String, dynamic> abcAnalysis = {
        'A_count': aCount,
        'B_count': bCount,
        'C_count': totalProductCount - aCount - bCount,
        'A_value': aValue,
        'B_value': bValue,
        'C_value': cValue,
        'total_count': totalProductCount,
        'total_value': aValue + bValue + cValue,
        'A_percentage': totalValue > 0 ? (aValue * 100 / totalValue) : 0,
        'B_percentage': totalValue > 0 ? (bValue * 100 / totalValue) : 0,
        'C_percentage': totalValue > 0 ? (cValue * 100 / totalValue) : 0,
      };
      
      return {
        'total_products': totalProducts,
        'total_value': totalValue,
        'low_stock_count': lowStockCount,
        'out_of_stock_count': outOfStockCount,
        'category_distribution': categoryDistributionMap,
        'category_values': categoryValuesMap,
        'value_tiers': valueTiers,
        'abc_analysis': abcAnalysis,
      };
    } catch (e) {
      logger.e('Error getting inventory statistics: $e');
      rethrow;
    }
  }
  
  // Save inventory items to local DB
  Future<void> _saveInventoryToLocalDB(List<InventoryItem> items) async {
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
              item.toJson(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } else {
            // Update existing item
            await txn.update(
              'inventory',
              item.toJson(),
              where: 'id = ?',
              whereArgs: [existingItems.first['id']],
            );
          }
        }
      });
    } catch (e) {
      logger.e('Error saving inventory to local DB: $e');
    }
  }
  
  // Perform stock opname (physical inventory count)
  Future<void> performStockOpname(
    int branchId,
    int userId,
    List<Map<String, dynamic>> items,
    {
      String? notes,
      String? token,
    }
  ) async {
    try {
      // Create stock opname header
      final stockOpname = <String, dynamic>{
        'branch_id': branchId,
        'user_id': userId,
        'opname_date': DateTime.now().toIso8601String(),
        'reference_number': 'SO-${DateTime.now().millisecondsSinceEpoch}',
        'notes': notes,
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Try to save to API first
      try {
        await _apiService.post(
          '/inventory/stock-opname',
          {
            'header': stockOpname,
            'items': items,
          },
          token: token,
        );
        
        // API handled the updates, so we're done
        return;
      } catch (e) {
        logger.w('Failed to perform stock opname through API, doing it locally: $e');
      }
      
      // If offline or API call fails, perform locally
      await _databaseService.transaction((txn) async {
        // Insert stock opname header
        final stockOpnameId = await txn.insert('stock_opname', stockOpname);
        
        // Insert stock opname items and update inventory
        for (final item in items) {
          final productId = item['product_id'] as int;
          final systemStock = item['system_stock'] as double;
          final physicalStock = item['physical_stock'] as double;
          final difference = physicalStock - systemStock;
          
          // Insert stock opname item
          final stockOpnameItem = <String, dynamic>{
            'stock_opname_id': stockOpnameId,
            'product_id': productId,
            'system_stock': systemStock,
            'physical_stock': physicalStock,
            'difference': difference,
            'adjustment_value': item['adjustment_value'],
            'notes': item['notes'],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          await txn.insert('stock_opname_items', stockOpnameItem);
          
          // Update inventory quantity
          final inventoryItems = await txn.query(
            'inventory',
            where: 'product_id = ? AND branch_id = ?',
            whereArgs: [productId, branchId],
            limit: 1,
          );
          
          if (inventoryItems.isEmpty) {
            // Insert new inventory item if it doesn't exist
            await txn.insert('inventory', {
              'product_id': productId,
              'branch_id': branchId,
              'quantity': physicalStock,
              'reserved_quantity': 0.0,
              'min_stock_level': 0,
              'last_stock_update': DateTime.now().toIso8601String(),
              'last_counting_date': DateTime.now().toIso8601String(),
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          } else {
            // Update existing inventory item
            await txn.update(
              'inventory',
              {
                'quantity': physicalStock,
                'last_stock_update': DateTime.now().toIso8601String(),
                'last_counting_date': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [inventoryItems.first['id']],
            );
          }
          
          // Add inventory transaction for adjustment
          if (difference != 0) {
            final transactionType = difference > 0 ? 'in' : 'out';
            final adjustmentQuantity = difference.abs();
            
            await txn.insert('inventory_transactions', {
              'product_id': productId,
              'branch_id': branchId,
              'transaction_type': transactionType,
              'quantity': adjustmentQuantity,
              'reference_type': 'stock_opname',
              'reference_id': stockOpnameId,
              'notes': 'Stock adjustment from physical count',
              'user_id': userId,
              'transaction_date': DateTime.now().toIso8601String(),
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      });
    } catch (e) {
      logger.e('Error performing stock opname: $e');
      rethrow;
    }
  }
}