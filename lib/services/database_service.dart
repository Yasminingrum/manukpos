// services/database_service.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import '../config/constants.dart';
import '../models/category.dart';
import '../models/business.dart';
import '../models/user.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  final Logger logger = Logger();
  Database? _database;
  
  // Private constructor
  DatabaseService._internal();
  
  // Factory constructor
  factory DatabaseService() {
    return _instance;
  }
  
  // Database getter
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Initialize the database if not available
    _database = await _initializeDatabase();
    return _database!;
  }
  
  // Initialize database
  Future<Database> _initializeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    
    logger.i('Initializing database at $path');
    
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }
  
  // Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    logger.i('Creating database tables for version $version');
    
    // Execute all table creation SQL statements
    var batch = db.batch();
    
    // Create branches table
    await db.execute('''
    CREATE TABLE branches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      address TEXT,
      phone TEXT,
      email TEXT,
      is_main_branch INTEGER DEFAULT 0,
      is_active INTEGER DEFAULT 1,
      created_at TEXT DEFAULT (datetime('now', 'localtime')),
      updated_at TEXT DEFAULT (datetime('now', 'localtime'))
    )''');
    
    // Create users table
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      name TEXT NOT NULL,
      email TEXT UNIQUE,
      phone TEXT,
      role TEXT NOT NULL,
      branch_id INTEGER,
      is_active INTEGER DEFAULT 1,
      last_login TEXT,
      login_count INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now', 'localtime')),
      updated_at TEXT DEFAULT (datetime('now', 'localtime')),
      FOREIGN KEY (branch_id) REFERENCES branches(id)
    )''');
    
    // Create categories table
    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      code TEXT UNIQUE,
      description TEXT,
      parent_id INTEGER NULL,
      level INTEGER DEFAULT 1,
      path TEXT,
      created_at TEXT DEFAULT (datetime('now', 'localtime')),
      updated_at TEXT DEFAULT (datetime('now', 'localtime')),
      FOREIGN KEY (parent_id) REFERENCES categories(id)
    )''');
    
    // Create products table
    await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sku TEXT UNIQUE NOT NULL,
      barcode TEXT UNIQUE,
      name TEXT NOT NULL,
      description TEXT,
      category_id INTEGER NOT NULL,
      buying_price REAL NOT NULL,
      selling_price REAL NOT NULL,
      discount_price REAL,
      min_stock INTEGER DEFAULT 1,
      weight REAL,
      dimension_length REAL,
      dimension_width REAL,
      dimension_height REAL,
      is_service INTEGER DEFAULT 0,
      is_active INTEGER DEFAULT 1,
      is_featured INTEGER DEFAULT 0,
      allow_fractions INTEGER DEFAULT 0,
      image_url TEXT,
      tags TEXT,
      created_at TEXT DEFAULT (datetime('now', 'localtime')),
      updated_at TEXT DEFAULT (datetime('now', 'localtime')),
      FOREIGN KEY (category_id) REFERENCES categories(id)
    )''');
    
    // Create inventory table
    await db.execute('''
    CREATE TABLE inventory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      branch_id INTEGER NOT NULL,
      quantity REAL NOT NULL DEFAULT 0,
      reserved_quantity REAL DEFAULT 0,
      min_stock_level INTEGER DEFAULT 0,
      max_stock_level INTEGER,
      reorder_point INTEGER,
      reorder_quantity INTEGER,
      shelf_location TEXT,
      last_stock_update TEXT,
      last_counting_date TEXT,
      created_at TEXT DEFAULT (datetime('now', 'localtime')),
      updated_at TEXT DEFAULT (datetime('now', 'localtime')),
      FOREIGN KEY (product_id) REFERENCES products(id),
      FOREIGN KEY (branch_id) REFERENCES branches(id),
      UNIQUE (product_id, branch_id)
    )''');
    
    // Create customers table
    await db.execute('''
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT UNIQUE,
      name TEXT NOT NULL,
      phone TEXT,
      email TEXT,
      address TEXT,
      city TEXT,
      postal_code TEXT,
      birthdate TEXT,
      join_date TEXT DEFAULT (date('now', 'localtime')),
      customer_type TEXT DEFAULT 'regular',
      credit_limit REAL DEFAULT 0,
      current_balance REAL DEFAULT 0,
      tax_id TEXT,
      is_active INTEGER DEFAULT 1,
      notes TEXT,
      created_at TEXT DEFAULT (datetime('now', 'localtime')),
      updated_at TEXT DEFAULT (datetime('now', 'localtime'))
    )''');
    
    // Create transactions table
    await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_number TEXT UNIQUE NOT NULL,
      invoice_date TEXT DEFAULT (datetime('now', 'localtime')),
      customer_id INTEGER,
      user_id INTEGER NOT NULL,
      branch_id INTEGER NOT NULL,
      transaction_date TEXT DEFAULT (datetime('now', 'localtime')),
      due_date TEXT,
      subtotal REAL NOT NULL,
      discount_id INTEGER,
      discount_amount REAL DEFAULT 0,
      tax_id INTEGER,
      tax_amount REAL DEFAULT 0,
      fee_id INTEGER,
      fee_amount REAL DEFAULT 0,
      shipping_cost REAL DEFAULT 0,
      grand_total REAL NOT NULL,
      amount_paid REAL DEFAULT 0,
      amount_returned REAL DEFAULT 0,
      payment_status TEXT DEFAULT 'unpaid',
      points_earned INTEGER DEFAULT 0,
      points_used INTEGER DEFAULT 0,
      notes TEXT,
      status TEXT DEFAULT 'completed',
      reference_id INTEGER,
      shipping_address TEXT,
      shipping_tracking TEXT,
      created_at TEXT DEFAULT (datetime('now', 'localtime')),
      updated_at TEXT DEFAULT (datetime('now', 'localtime')),
      sync_status TEXT DEFAULT 'pending',
      FOREIGN KEY (customer_id) REFERENCES customers(id),
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (branch_id) REFERENCES branches(id)
    )''');
    
    // Create transaction_items table
    await db.execute('''
    CREATE TABLE transaction_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity REAL NOT NULL,
      unit_price REAL NOT NULL,
      original_price REAL,
      discount_percent REAL DEFAULT 0,
      discount_amount REAL DEFAULT 0,
      tax_percent REAL DEFAULT 0,
      tax_amount REAL DEFAULT 0,
      subtotal REAL NOT NULL,
      notes TEXT,
      created_at TEXT DEFAULT (datetime('now', 'localtime')),
      updated_at TEXT DEFAULT (datetime('now', 'localtime')),
      sync_status TEXT DEFAULT 'pending',
      FOREIGN KEY (transaction_id) REFERENCES transactions(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    )''');
    
    // Create payments table
    await db.execute('''
    CREATE TABLE payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id INTEGER NOT NULL,
      payment_method TEXT NOT NULL,
      amount REAL NOT NULL,
      reference_number TEXT,
      payment_date TEXT DEFAULT (datetime('now', 'localtime')),
      status TEXT DEFAULT 'completed',
      card_last4 TEXT,
      card_type TEXT,
      e_wallet_provider TEXT,
      cheque_number TEXT,
      cheque_date TEXT,
      account_name TEXT,
      notes TEXT,
      user_id INTEGER,
      created_at TEXT DEFAULT (datetime('now', 'localtime')),
      updated_at TEXT DEFAULT (datetime('now', 'localtime')),
      sync_status TEXT DEFAULT 'pending',
      FOREIGN KEY (transaction_id) REFERENCES transactions(id),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )''');
    
    // Create sync_log table
    await db.execute('''
    CREATE TABLE sync_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      device_id TEXT NOT NULL,
      user_id INTEGER,
      branch_id INTEGER NOT NULL,
      sync_type TEXT NOT NULL,
      sync_status TEXT DEFAULT 'in_progress',
      start_time TEXT DEFAULT (datetime('now', 'localtime')),
      end_time TEXT,
      data_count INTEGER DEFAULT 0,
      error_message TEXT,
      created_at TEXT DEFAULT (datetime('now', 'localtime')),
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (branch_id) REFERENCES branches(id)
    )''');
    
    // Create business_profile table
    await db.execute('''
    CREATE TABLE business_profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      address TEXT,
      phone TEXT,
      email TEXT,
      tax_id TEXT,
      logo_path TEXT,
      footer_text TEXT,
      show_tax_info INTEGER DEFAULT 1,
      show_social_media INTEGER DEFAULT 0,
      social_media_handles TEXT,
      currency_symbol TEXT DEFAULT 'Rp',
      created_at TEXT DEFAULT (datetime('now', 'localtime')),
      updated_at TEXT DEFAULT (datetime('now', 'localtime'))
    )''');
    
    await batch.commit();
    
    // Insert default data
    await _insertDefaultData(db);
  }
  
  // Insert default data
  Future<void> _insertDefaultData(Database db) async {
    logger.i('Inserting default data');
    
    // Insert main branch
    await db.insert('branches', {
      'code': 'MAIN',
      'name': 'Kantor Pusat',
      'is_main_branch': 1,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    
    // Insert admin user
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123', // In production, use hashed passwords
      'name': 'Administrator',
      'role': 'admin',
      'branch_id': 1,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    
    // Insert default category
    await db.insert('categories', {
      'name': 'Umum',
      'code': 'GEN',
      'description': 'Kategori Umum',
      'level': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    
    // Insert default business profile
    await db.insert('business_profile', {
      'name': 'My Business',
      'address': 'Business Address',
      'phone': '081234567890',
      'email': 'contact@mybusiness.com',
      'tax_id': '',
      'logo_path': null,
      'footer_text': 'Terima kasih atas kunjungan Anda!',
      'show_tax_info': 1,
      'show_social_media': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Upgrade database
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    logger.i('Upgrading database from version $oldVersion to $newVersion');
    
    // Implement migration logic for different versions
    if (oldVersion < 2) {

      // Check if business_profile table exists
      var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='business_profile'");
      if (tables.isEmpty) {
        // Create business_profile table if it doesn't exist
        await db.execute('''
        CREATE TABLE business_profile (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          address TEXT,
          phone TEXT,
          email TEXT,
          tax_id TEXT,
          logo_path TEXT,
          footer_text TEXT,
          show_tax_info INTEGER DEFAULT 1,
          show_social_media INTEGER DEFAULT 0,
          social_media_handles TEXT,
          currency_symbol TEXT DEFAULT 'Rp',
          created_at TEXT DEFAULT (datetime('now', 'localtime')),
          updated_at TEXT DEFAULT (datetime('now', 'localtime'))
        )''');
        
        // Insert default business profile
        await db.insert('business_profile', {
          'name': 'My Business',
          'address': 'Business Address',
          'phone': '081234567890',
          'email': 'contact@mybusiness.com',
          'tax_id': '',
          'logo_path': null,
          'footer_text': 'Terima kasih atas kunjungan Anda!',
          'show_tax_info': 1,
          'show_social_media': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }
  
  // General database operations
  
  // Query the database
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool distinct = false,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }
  
  // Insert data
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    
    // Add timestamps if not provided
    if (!data.containsKey('created_at')) {
      data['created_at'] = DateTime.now().toIso8601String();
    }
    if (!data.containsKey('updated_at')) {
      data['updated_at'] = DateTime.now().toIso8601String();
    }
    
    return await db.insert(table, data, 
      conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  // Update data
  Future<int> update(
    String table,
    Map<String, dynamic> data,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    
    // Update the updated_at timestamp
    if (!data.containsKey('updated_at')) {
      data['updated_at'] = DateTime.now().toIso8601String();
    }
    
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }
  
  // Delete data
  Future<int> delete(
    String table,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
  
  // Execute raw SQL
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    
    return await db.rawQuery(sql, arguments);
  }
  
  // Execute SQL with no return
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    
    await db.execute(sql, arguments);
  }
  
  // Transaction operations
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    
    return await db.transaction(action);
  }
  
  // Close the database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // =============================================
  // Category specific methods
  // =============================================
  
  // Get all categories
  Future<List<Category>> getAllCategories() async {
    logger.i('Fetching all categories');
    
    final List<Map<String, dynamic>> maps = await query(
      'categories',
      orderBy: 'parent_id IS NULL DESC, name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }
  
  // Get category by ID
  Future<Category?> getCategoryById(int id) async {
    logger.i('Fetching category with ID: $id');
    
    final List<Map<String, dynamic>> maps = await query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }
  
  // Insert a new category
  Future<int> insertCategory(Category category) async {
    logger.i('Inserting new category: ${category.name}');
    
    // Convert Category object to Map
    final Map<String, dynamic> categoryMap = category.toMap();
    
    // Remove id if it's 0 (for auto-increment)
    if (categoryMap['id'] == 0) {
      categoryMap.remove('id');
    }
    
    // Add timestamps
    categoryMap['created_at'] = DateTime.now().toIso8601String();
    categoryMap['updated_at'] = DateTime.now().toIso8601String();
    
    return await insert('categories', categoryMap);
  }
  
  // Update an existing category
  Future<int> updateCategory(Category category) async {
    logger.i('Updating category with ID: ${category.id}');
    
    // Convert Category object to Map
    final Map<String, dynamic> categoryMap = category.toMap();
    
    // Always update the timestamp
    categoryMap['updated_at'] = DateTime.now().toIso8601String();
    
    // Remove id from the map as it's used in the where clause
    categoryMap.remove('id');
    
    return await update(
      'categories',
      categoryMap,
      'id = ?',
      [category.id],
    );
  }
  
  // Delete a category
  Future<int> deleteCategory(int id) async {
    logger.i('Deleting category with ID: $id');
    
    return await delete(
      'categories',
      'id = ?',
      [id],
    );
  }
  
  // Check if a category has products
  Future<bool> categoryHasProducts(int categoryId) async {
    logger.i('Checking if category ID $categoryId has products');
    
    final List<Map<String, dynamic>> result = await query(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    
    return result.isNotEmpty;
  }
  
  // Get child categories
  Future<List<Category>> getChildCategories(int parentId) async {
    logger.i('Fetching child categories for parent ID: $parentId');
    
    final List<Map<String, dynamic>> maps = await query(
      'categories',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }
  
  // Get top level categories (those with no parent)
  Future<List<Category>> getTopLevelCategories() async {
    logger.i('Fetching top level categories');
    
    final List<Map<String, dynamic>> maps = await query(
      'categories',
      where: 'parent_id IS NULL',
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }
  
  // =============================================
  // Business Profile methods
  // =============================================
  
  // Get business profile
  Future<Business?> getBusinessProfile() async {
    logger.i('Fetching business profile');
    
    final List<Map<String, dynamic>> maps = await query(
      'business_profile',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return Business.fromMap(maps.first);
    }
    return null;
  }
  
  // Save business profile
  Future<int> saveBusinessProfile(Business business) async {
    logger.i('Saving business profile: ${business.name}');
    
    // Convert Business object to Map
    final Map<String, dynamic> businessMap = business.toMap();
    
    // Check if we have an existing record
    final List<Map<String, dynamic>> existing = await query(
      'business_profile',
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      // Update existing record
      return await update(
        'business_profile',
        businessMap,
        'id = ?',
        [existing.first['id']],
      );
    } else {
      // Insert new record
      return await insert('business_profile', businessMap);
    }
  }

  // =============================================
  // User specific methods
  // =============================================
  
  // Get all users
  Future<List<User>> getUsers() async {
    logger.i('Fetching all users');
    
    final List<Map<String, dynamic>> maps = await query(
      'users',
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  // Get user by ID
  Future<User?> getUserById(int id) async {
    logger.i('Fetching user with ID: $id');
    
    final List<Map<String, dynamic>> maps = await query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Update an existing user
  Future<int> updateUser(User user) async {
    logger.i('Updating user with ID: ${user.id}');
    
    // Convert User object to Map
    final Map<String, dynamic> userMap = user.toMap();
    
    // Always update the timestamp
    userMap['updated_at'] = DateTime.now().toIso8601String();
    
    // Remove the id from the map as it's used in the where clause
    final userId = user.id;
    userMap.remove('id');
    
    // If password is null, remove it from the map to avoid overwriting existing password
    if (userMap['password'] == null) {
      userMap.remove('password');
    }
    
    return await update(
      'users',
      userMap,
      'id = ?',
      [userId],
    );
  }

  // Create a new user
  Future<int> createUser(User user) async {
    logger.i('Creating new user: ${user.username}');
    
    // Convert User object to Map
    final Map<String, dynamic> userMap = user.toMap();
    
    // Remove id if it's null (for auto-increment)
    userMap.remove('id');
    
    // Add timestamps
    userMap['created_at'] = DateTime.now().toIso8601String();
    userMap['updated_at'] = DateTime.now().toIso8601String();
    
    return await insert('users', userMap);
  }

  // Delete a user
  Future<int> deleteUser(int id) async {
    logger.i('Deleting user with ID: $id');
    
    return await delete(
      'users',
      'id = ?',
      [id],
    );
  }

  // Get all branches
  Future<List<Map<String, dynamic>>> getBranches() async {
    logger.i('Fetching all branches');
    
    return await query(
      'branches',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'is_main_branch DESC, name ASC',
    );
  }

}
