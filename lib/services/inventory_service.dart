// lib/services/inventory_service.dart
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import '../models/inventory.dart';
import 'api_service.dart';
import 'database_service.dart';

class InventoryService {
  final Logger logger = Logger();
  final DatabaseService databaseService;
  final ApiService apiService;
  
  // Constructor with dependency injection
  InventoryService({
    required this.databaseService,
    required this.apiService,
  });
  
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
        
        final response = await apiService.get(
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
      
      // Check if the inventory table exists
      final db = await databaseService.database;
      final tableCheck = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='inventory'");
      if (tableCheck.isEmpty) {
        logger.w('Inventory table does not exist, returning empty list');
        return [];
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
      // First check if products table exists
      final productsTableCheck = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='products'");
      if (productsTableCheck.isEmpty) {
        logger.w('Products table does not exist, returning empty list');
        return [];
      }
      
      String query = '''
      SELECT i.*, b.name as branch_name
      FROM inventory i
      JOIN branches b ON i.branch_id = b.id
      ''';
      
      // Only join with products if we need to filter by product properties
      if (search != null || categoryId != null) {
        query = '''
        SELECT i.*, p.name as product_name, p.sku as product_sku, b.name as branch_name
        FROM inventory i
        JOIN products p ON i.product_id = p.id
        JOIN branches b ON i.branch_id = b.id
        ''';
      }
      
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
      
      query += ' ORDER BY i.id ASC LIMIT ? OFFSET ?';
      whereArgs.add(limit);
      whereArgs.add((page - 1) * limit);
      
      logger.d('Executing query: $query with args: $whereArgs');
      
      try {
        final results = await db.rawQuery(query, whereArgs);
        
        return results.map((map) {
          // Combine inventory data with product and branch data
          final inventoryMap = <String, dynamic>{
            'id': map['id'],
            'product_id': map['product_id'],
            'branch_id': map['branch_id'],
            'branch_name': map['branch_name'] ?? 'Unknown Branch',
            'quantity': map['quantity'],
            'min_stock_level': map['min_stock_level'] ?? 0,
            'created_at': map['created_at'] ?? DateTime.now().toIso8601String(),
            'updated_at': map['updated_at'] ?? DateTime.now().toIso8601String(),
          };
          
          return InventoryItem.fromJson(inventoryMap);
        }).toList();
      } catch (e) {
        logger.e('Error executing inventory query: $e');
        // Return empty list in case of query error
        return [];
      }
    } catch (e) {
      logger.e('Error getting inventory items: $e');
      return []; // Return empty list instead of rethrowing
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
        final response = await apiService.get(
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
      final db = await databaseService.database;
      
      // Check if the inventory table exists
      final tableCheck = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='inventory'");
      if (tableCheck.isEmpty) {
        return null;
      }
      
      final results = await db.query(
        'inventory',
        where: 'product_id = ? AND branch_id = ?',
        whereArgs: [productId, branchId],
        limit: 1,
      );
      
      if (results.isEmpty) {
        return null;
      }
      
      // Get branch name
      String branchName = 'Unknown Branch';
      try {
        final branchData = await db.query(
          'branches',
          columns: ['name'],
          where: 'id = ?',
          whereArgs: [branchId],
          limit: 1,
        );
        
        if (branchData.isNotEmpty) {
          branchName = branchData.first['name'] as String;
        }
      } catch (e) {
        logger.w('Failed to get branch name: $e');
      }
      
      // Add branch name to inventory data
      final inventoryData = Map<String, dynamic>.from(results.first);
      inventoryData['branch_name'] = branchName;
      
      return InventoryItem.fromJson(inventoryData);
    } catch (e) {
      logger.e('Error getting inventory item: $e');
      return null; // Return null instead of rethrowing
    }
  }
  
  // Update inventory quantity
  Future<InventoryItem?> updateInventoryQuantity(
    int productId, 
    int branchId, 
    double newQuantity,
    {String? token}
  ) async {
    try {
      // Try to update through API first
      try {
        final response = await apiService.put(
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
      final db = await databaseService.database;
      
      // Check if inventory item exists
      final existingItems = await db.query(
        'inventory',
        where: 'product_id = ? AND branch_id = ?',
        whereArgs: [productId, branchId],
        limit: 1,
      );
      
      String branchName = 'Unknown Branch';
      try {
        final branchData = await db.query(
          'branches',
          columns: ['name'],
          where: 'id = ?',
          whereArgs: [branchId],
          limit: 1,
        );
        
        if (branchData.isNotEmpty) {
          branchName = branchData.first['name'] as String;
        }
      } catch (e) {
        logger.w('Failed to get branch name: $e');
      }
      
      if (existingItems.isEmpty) {
        // Create new inventory item if it doesn't exist
        final now = DateTime.now().toIso8601String();
        final newItem = <String, dynamic>{
          'product_id': productId,
          'branch_id': branchId,
          'quantity': newQuantity,
          'reserved_quantity': 0.0,
          'min_stock_level': 0,
          'created_at': now,
          'updated_at': now,
          'last_stock_update': now,
        };
        
        try {
          final id = await db.insert('inventory', newItem);
          newItem['id'] = id;
          newItem['branch_name'] = branchName;
          
          return InventoryItem.fromJson(newItem);
        } catch (e) {
          logger.e('Error inserting new inventory item: $e');
          return null;
        }
      } else {
        // Update existing inventory item
        final item = existingItems.first;
        final now = DateTime.now().toIso8601String();
        final updatedItem = <String, dynamic>{
          'quantity': newQuantity,
          'updated_at': now,
          'last_stock_update': now,
        };
        
        try {
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
          
          if (updatedItems.isNotEmpty) {
            final result = Map<String, dynamic>.from(updatedItems.first);
            result['branch_name'] = branchName;
            return InventoryItem.fromJson(result);
          }
        } catch (e) {
          logger.e('Error updating inventory item: $e');
        }
      }
      
      return null;
    } catch (e) {
      logger.e('Error updating inventory quantity: $e');
      return null; // Return null instead of rethrowing
    }
  }
  
  // Add inventory transaction (for stock movements)
  Future<bool> addInventoryTransaction(
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
      final now = DateTime.now().toIso8601String();
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
        'transaction_date': now,
        'created_at': now,
      };
      
      // Try to add through API first
      try {
        await apiService.post(
          '/inventory/transactions',
          transaction,
          token: token,
        );
      } catch (e) {
        logger.w('Failed to add inventory transaction through API, adding locally: $e');
      }
      
      // Check if inventory_transactions table exists
      final db = await databaseService.database;
      final tableCheck = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='inventory_transactions'");
      if (tableCheck.isEmpty) {
        logger.w('inventory_transactions table does not exist');
        return false;
      }
      
      // Add to local database regardless of API success
      try {
        await db.insert('inventory_transactions', transaction);
      } catch (e) {
        logger.e('Error inserting inventory transaction: $e');
        return false;
      }
      
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
      
      final result = await updateInventoryQuantity(productId, branchId, newQuantity);
      return result != null;
    } catch (e) {
      logger.e('Error adding inventory transaction: $e');
      return false; // Return false instead of rethrowing
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
        
        final response = await apiService.get(
          '/inventory/low-stock',
          queryParams: queryParams,
          token: token,
        );
        
        final List<dynamic> data = response['data'];
        return List<Map<String, dynamic>>.from(data);
      } catch (e) {
        logger.w('Failed to get low stock products from API, using local data: $e');
      }
      
      // Check if required tables exist
      final db = await databaseService.database;
      final inventoryTableCheck = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='inventory'");
      final productsTableCheck = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='products'");
      
      if (inventoryTableCheck.isEmpty || productsTableCheck.isEmpty) {
        logger.w('Required tables do not exist');
        return [];
      }
      
      // If offline or API call fails, get from local database
      String query = '''
      SELECT i.*, p.name as product_name, p.sku as product_sku, 
             p.min_stock as min_stock
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      WHERE i.quantity <= IFNULL(p.min_stock, 0)
      ''';
      
      if (branchId != null) {
        query += ' AND i.branch_id = ?';
      }
      
      // Using a simpler ordering to avoid potential SQL errors
      query += ' ORDER BY i.quantity ASC LIMIT ?';
      
      final List<dynamic> args = [];
      if (branchId != null) args.add(branchId);
      args.add(limit);
      
      try {
        final results = await db.rawQuery(query, args);
        
        return results.map((item) {
          return <String, dynamic>{
            'product_id': item['product_id'],
            'product_name': item['product_name'],
            'product_sku': item['product_sku'],
            'current_stock': item['quantity'],
            'min_stock': item['min_stock'] ?? 0,
            'branch_id': item['branch_id'],
          };
        }).toList();
      } catch (e) {
        logger.e('Error executing low stock query: $e');
        return [];
      }
    } catch (e) {
      logger.e('Error getting low stock products: $e');
      return []; // Return empty list instead of rethrowing
    }
  }
  
  // Get inventory statistics with safer implementation
  Future<Map<String, dynamic>> getInventoryStatistics({
    int? branchId,
    String? token,
  }) async {
    try {
      // Try to get from API first
      try {
        final queryParams = <String, String>{};
        if (branchId != null) queryParams['branch_id'] = branchId.toString();
        
        final response = await apiService.get(
          '/inventory/statistics',
          queryParams: queryParams,
          token: token,
        );
        
        return response['data'] as Map<String, dynamic>;
      } catch (e) {
        logger.w('Failed to get inventory statistics from API, calculating locally: $e');
      }
      
      // Check if required tables exist
      final db = await databaseService.database;
      final inventoryTableCheck = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='inventory'");
      final productsTableCheck = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='products'");
      
      if (inventoryTableCheck.isEmpty || productsTableCheck.isEmpty) {
        logger.w('Required tables do not exist, returning default statistics');
        return _getDefaultStatistics();
      }
      
      // Set up the query with branch filter if provided
      String branchFilter = branchId != null ? 'AND i.branch_id = $branchId' : '';
      
      // Total products count
      int totalProducts = 0;
      double totalValue = 0.0;
      int lowStockCount = 0;
      int outOfStockCount = 0;
      Map<String, dynamic> categoryDistributionMap = {};
      Map<String, dynamic> categoryValuesMap = {};
      
      try {
        // Total products count
        final totalProductsQuery = '''
        SELECT COUNT(DISTINCT i.product_id) as count
        FROM inventory i
        WHERE i.quantity > 0 $branchFilter
        ''';
        final totalProductsResult = await db.rawQuery(totalProductsQuery);
        totalProducts = Sqflite.firstIntValue(totalProductsResult) ?? 0;
      } catch (e) {
        logger.e('Error getting total products: $e');
      }
      
      try {
        // Total inventory value
        final totalValueQuery = '''
        SELECT SUM(i.quantity * p.buying_price) as value
        FROM inventory i
        JOIN products p ON i.product_id = p.id
        WHERE i.quantity > 0 $branchFilter
        ''';
        final totalValueResult = await db.rawQuery(totalValueQuery);
        final totalValueObj = totalValueResult.isNotEmpty ? totalValueResult.first['value'] : null;
        totalValue = totalValueObj is int ? 
          (totalValueObj).toDouble() : (totalValueObj as double? ?? 0.0);
      } catch (e) {
        logger.e('Error getting total value: $e');
      }
      
      try {
        // Low stock count - using a simpler query
        final lowStockQuery = '''
        SELECT COUNT(*) as count
        FROM inventory i
        JOIN products p ON i.product_id = p.id
        WHERE i.quantity <= IFNULL(p.min_stock, 0) AND i.quantity > 0 $branchFilter
        ''';
        final lowStockResult = await db.rawQuery(lowStockQuery);
        lowStockCount = Sqflite.firstIntValue(lowStockResult) ?? 0;
      } catch (e) {
        logger.e('Error getting low stock count: $e');
      }
      
      try {
        // Out of stock count
        final outOfStockQuery = '''
        SELECT COUNT(*) as count
        FROM inventory i
        WHERE i.quantity = 0 $branchFilter
        ''';
        final outOfStockResult = await db.rawQuery(outOfStockQuery);
        outOfStockCount = Sqflite.firstIntValue(outOfStockResult) ?? 0;
      } catch (e) {
        logger.e('Error getting out of stock count: $e');
      }
      
      // Check if categories table exists
      final categoriesTableCheck = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='categories'");
      if (categoriesTableCheck.isNotEmpty) {
        try {
          // Simplified category distribution query
          final categoryDistributionQuery = '''
          SELECT c.name as category, COUNT(i.product_id) as count
          FROM inventory i
          JOIN products p ON i.product_id = p.id
          JOIN categories c ON p.category_id = c.id
          WHERE i.quantity > 0 $branchFilter
          GROUP BY c.id
          ''';
          final categoryDistribution = await db.rawQuery(categoryDistributionQuery);
          
          for (final item in categoryDistribution) {
            final category = item['category'] as String? ?? 'Unknown';
            final count = item['count'];
            categoryDistributionMap[category] = count;
          }
        } catch (e) {
          logger.e('Error getting category distribution: $e');
        }
        
        try {
          // Simplified category values query
          final categoryValuesQuery = '''
          SELECT c.name as category, SUM(i.quantity * p.buying_price) as value
          FROM inventory i
          JOIN products p ON i.product_id = p.id
          JOIN categories c ON p.category_id = c.id
          WHERE i.quantity > 0 $branchFilter
          GROUP BY c.id
          ''';
          final categoryValues = await db.rawQuery(categoryValuesQuery);
          
          for (final item in categoryValues) {
            final category = item['category'] as String? ?? 'Unknown';
            final valueObj = item['value'];
            double value = 0.0;
            if (valueObj != null) {
              value = valueObj is int ? valueObj.toDouble() : (valueObj as double? ?? 0.0);
            }
            categoryValuesMap[category] = value;
          }
        } catch (e) {
          logger.e('Error getting category values: $e');
        }
      }
      
      // Return simplified statistics
      return {
        'total_products': totalProducts,
        'total_value': totalValue,
        'low_stock_count': lowStockCount,
        'out_of_stock_count': outOfStockCount,
        'category_distribution': categoryDistributionMap,
        'category_values': categoryValuesMap,
      };
    } catch (e) {
      logger.e('Error getting inventory statistics: $e');
      // Return default statistics instead of rethrowing
      return _getDefaultStatistics();
    }
  }
  
  // Return default statistics
  Map<String, dynamic> _getDefaultStatistics() {
    return {
      'total_products': 0,
      'total_value': 0.0,
      'low_stock_count': 0,
      'out_of_stock_count': 0,
      'category_distribution': {},
      'category_values': {},
    };
  }
  
  // Save inventory items to local DB with better error handling
  Future<void> _saveInventoryToLocalDB(List<InventoryItem> items) async {
    try {
      if (items.isEmpty) {
        return;
      }
      
      final db = await databaseService.database;
      
      // Check if inventory table exists
      final tableCheck = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='inventory'");
      if (tableCheck.isEmpty) {
        logger.w('Inventory table does not exist, cannot save items');
        return;
      }
      
      await databaseService.transaction((txn) async {
        for (var item in items) {
          try {
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
          } catch (e) {
            logger.e('Error saving inventory item ${item.productId}: $e');
            // Continue with next item instead of throwing
          }
        }
      });
    } catch (e) {
      logger.e('Error saving inventory to local DB: $e');
      // Swallow the exception to prevent crashes
    }
  }
}