// services/product_service.dart
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import 'api_service.dart';
import 'database_service.dart';
import '../config/constants.dart';

class ProductService {
  final ApiService apiService;
  final DatabaseService databaseService;
  final Logger logger = Logger();

  ProductService({
    required this.apiService, 
    required this.databaseService
  });

  // Mendapatkan daftar produk
  Future<List<Product>> getProducts({
    String? search,
    int? categoryId,
    bool? isActive,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    try {
      // Coba dapatkan dari API jika online
      try {
        final queryParams = {
          'page': page.toString(),
          'limit': limit.toString(),
        };
        
        if (search != null) queryParams['search'] = search;
        if (categoryId != null) queryParams['category_id'] = categoryId.toString();
        if (isActive != null) queryParams['is_active'] = isActive ? '1' : '0';
        
        final response = await apiService.get(
          '/products',
          queryParams: queryParams,
          token: token,
        );
        
        final List<dynamic> data = response['data'];
        final List<Product> products = data
            .map((item) => Product.fromMap(item))
            .toList();
        
        // Simpan ke database lokal untuk penggunaan offline
        _saveProductsToLocalDB(products);
        
        return products;
      } catch (e) {
        logger.w('Gagal mengambil data dari API, menggunakan data lokal: $e');
      }
      
      // Jika offline atau API gagal, ambil dari lokal
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (search != null) {
        whereClause += 'name LIKE ? OR sku LIKE ? OR barcode LIKE ?';
        whereArgs.add('%$search%');
        whereArgs.add('%$search%');
        whereArgs.add('%$search%');
      }
      
      if (categoryId != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'category_id = ?';
        whereArgs.add(categoryId);
      }
      
      if (isActive != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'is_active = ?';
        whereArgs.add(isActive ? 1 : 0);
      }
      
      final productMaps = await databaseService.query(
        AppConstants.tableProducts,
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        limit: limit,
        offset: (page - 1) * limit,
        orderBy: 'name ASC',
      );
      
      return productMaps.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      logger.e('Error getting products: $e');
      rethrow;
    }
  }

  // Mendapatkan detail produk berdasarkan ID
  Future<Product> getProductById(int id, {String? token}) async {
    try {
      // Coba dapatkan dari API jika online
      try {
        final response = await apiService.get('/products/$id', token: token);
        
        final Product product = Product.fromMap(response['data']);
        
        // Update di database lokal
        await databaseService.update(
          AppConstants.tableProducts,
          product.toMap(),
          'id = ?',
          [id],
        );
        
        return product;
      } catch (e) {
        logger.w('Gagal mengambil data dari API, menggunakan data lokal: $e');
      }
      
      // Jika offline atau API gagal, ambil dari lokal
      final productMaps = await databaseService.query(
        AppConstants.tableProducts,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (productMaps.isEmpty) {
        throw Exception('Produk tidak ditemukan');
      }
      
      return Product.fromMap(productMaps.first);
    } catch (e) {
      logger.e('Error getting product by id: $e');
      rethrow;
    }
  }

  // Mencari produk berdasarkan barcode
  Future<Product> getProductByBarcode(String barcode, {String? token}) async {
    try {
      // Coba dapatkan dari API jika online
      try {
        final response = await apiService.get(
          '/products/barcode/$barcode',
          token: token,
        );
        
        final Product product = Product.fromMap(response['data']);
        
        // Update di database lokal
        await databaseService.update(
          AppConstants.tableProducts,
          product.toMap(),
          'id = ?',
          [product.id],
        );
        
        return product;
      } catch (e) {
        logger.w('Gagal mengambil data dari API, menggunakan data lokal: $e');
      }
      
      // Jika offline atau API gagal, ambil dari lokal
      final productMaps = await databaseService.query(
        AppConstants.tableProducts,
        where: 'barcode = ?',
        whereArgs: [barcode],
        limit: 1,
      );
      
      if (productMaps.isEmpty) {
        throw Exception('Produk tidak ditemukan');
      }
      
      return Product.fromMap(productMaps.first);
    } catch (e) {
      logger.e('Error getting product by barcode: $e');
      rethrow;
    }
  }

  // Membuat produk baru
  Future<Product> createProduct(Product product, {String? token}) async {
    try {
      // Coba buat di API jika online
      try {
        final response = await apiService.post(
          '/products',
          product.toMap(),
          token: token,
        );
        
        final Product newProduct = Product.fromMap(response['data']);
        
        // Simpan ke database lokal
        await databaseService.insert(
          AppConstants.tableProducts,
          newProduct.toMap(),
        );
        
        return newProduct;
      } catch (e) {
        logger.w('Gagal membuat produk di API, menyimpan lokal saja: $e');
      }
      
      // Jika offline atau API gagal, simpan ke lokal saja
      // Generate ID sementara untuk mode offline
      final lastProductMaps = await databaseService.query(
        AppConstants.tableProducts,
        orderBy: 'id DESC',
        limit: 1,
      );
      
      int tempId = 1;
      if (lastProductMaps.isNotEmpty) {
        tempId = lastProductMaps.first['id'] + 1;
      }
      
      final offlineProduct = product.copyWith(
        id: tempId,
        syncStatus: AppConstants.syncStatusPending,
      );
      
      final id = await databaseService.insert(
        AppConstants.tableProducts,
        offlineProduct.toMap(),
      );
      
      return offlineProduct.copyWith(id: id);
    } catch (e) {
      logger.e('Error creating product: $e');
      rethrow;
    }
  }

  // Memperbarui produk
  Future<Product> updateProduct(Product product, {String? token}) async {
    try {
      // Coba update di API jika online
      try {
        final response = await apiService.put(
          '/products/${product.id}',
          product.toMap(),
          token: token,
        );
        
        final Product updatedProduct = Product.fromMap(response['data']);
        
        // Update di database lokal
        await databaseService.update(
          AppConstants.tableProducts,
          updatedProduct.toMap(),
          'id = ?',
          [product.id],
        );
        
        return updatedProduct;
      } catch (e) {
        logger.w('Gagal update produk di API, update lokal saja: $e');
      }
      
      // Jika offline atau API gagal, update lokal saja
      final offlineProduct = product.copyWith(
        syncStatus: AppConstants.syncStatusPending,
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      await databaseService.update(
        AppConstants.tableProducts,
        offlineProduct.toMap(),
        'id = ?',
        [product.id],
      );
      
      return offlineProduct;
    } catch (e) {
      logger.e('Error updating product: $e');
      rethrow;
    }
  }

  // Menghapus produk
  Future<bool> deleteProduct(int id, {String? token}) async {
    try {
      // Coba hapus di API jika online
      try {
        await apiService.delete(
          '/products/$id',
          token: token,
        );
        
        // Hapus dari database lokal
        await databaseService.delete(
          AppConstants.tableProducts,
          'id = ?',
          [id],
        );
        
        return true;
      } catch (e) {
        logger.w('Gagal menghapus produk di API, menandai untuk dihapus saja: $e');
      }
      
      // Jika offline atau API gagal, tandai untuk dihapus saat sinkronisasi
      await databaseService.update(
        AppConstants.tableProducts,
        {
          'is_active': 0,
          'sync_status': AppConstants.syncStatusPending,
          'updated_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [id],
      );
      
      return true;
    } catch (e) {
      logger.e('Error deleting product: $e');
      rethrow;
    }
  }

  // Simpan produk ke database lokal
  Future<void> _saveProductsToLocalDB(List<Product> products) async {
    try {
      await databaseService.transaction((txn) async {
        for (var product in products) {
          // Check if product exists
          final existingProducts = await txn.query(
            AppConstants.tableProducts,
            where: 'id = ?',
            whereArgs: [product.id],
            limit: 1,
          );
          
          if (existingProducts.isEmpty) {
            // Insert new product
            await txn.insert(
              AppConstants.tableProducts,
              product.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } else {
            // Update existing product if it's not pending sync
            final existingProduct = existingProducts.first;
            if (existingProduct['sync_status'] != AppConstants.syncStatusPending) {
              await txn.update(
                AppConstants.tableProducts,
                product.toMap(),
                where: 'id = ?',
                whereArgs: [product.id],
              );
            }
          }
        }
      });
    } catch (e) {
      logger.e('Error saving products to local DB: $e');
    }
  }
}