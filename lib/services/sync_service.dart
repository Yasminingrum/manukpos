// services/sync_service.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import '../config/constants.dart';
import 'api_service.dart';
import 'database_service.dart';

class SyncService {
  final ApiService apiService;
  final DatabaseService databaseService;
  final Logger logger = Logger();
  
  // Tabel yang perlu disinkronkan
  final List<String> _tablesToSync = [
    AppConstants.tableUsers,
    AppConstants.tableBranches,
    AppConstants.tableProducts,
    AppConstants.tableCategories,
    AppConstants.tableInventory,
    AppConstants.tableTransactions,
    AppConstants.tableTransactionItems,
    AppConstants.tableCustomers,
    AppConstants.tablePayments,
  ];
  
  // Status sinkronisasi
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _currentSyncTable;
  
  SyncService({
    required this.apiService,
    required this.databaseService,
  });
  
  // Getters
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get currentSyncTable => _currentSyncTable;
  
  // Cek apakah ada koneksi internet
  Future<bool> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  // Dapatkan ID perangkat
  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      }
    } catch (e) {
      logger.e('Error getting device info: $e');
      deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return deviceId;
  }
  
  // Sinkronisasi data
  Future<bool> synchronize({
    required int userId,
    required int branchId,
    required String token,
  }) async {
    // Cek jika sudah dalam proses sinkronisasi
    if (_isSyncing) {
      logger.w('Sync already in progress');
      return false;
    }
    
    // Cek koneksi internet
    final hasConnectivity = await _checkConnectivity();
    if (!hasConnectivity) {
      logger.w('No internet connection for sync');
      return false;
    }
    
    _isSyncing = true;
    
    try {
      final deviceId = await _getDeviceId();
      
      // Buat log sinkronisasi
      final syncLogId = await _createSyncLog(deviceId, userId, branchId);
      
      // Lakukan sinkronisasi untuk setiap tabel
      for (var table in _tablesToSync) {
        _currentSyncTable = table;
        
        // Sinkronisasi data ke server
        await _syncTableToServer(table, syncLogId, branchId, token);
        
        // Ambil data terbaru dari server
        await _syncTableFromServer(table, syncLogId, branchId, token);
      }
      
      // Update status sinkronisasi
      await _completeSyncLog(syncLogId, 'completed');
      
      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      _currentSyncTable = null;
      
      return true;
    } catch (e) {
      logger.e('Error during sync: $e');
      
      // Update log dengan error
      if (_currentSyncTable != null) {
        final syncLogs = await databaseService.query(
          AppConstants.tableSyncLog,
          where: 'sync_status = ?',
          whereArgs: ['in_progress'],
          orderBy: 'id DESC',
          limit: 1,
        );
        
        if (syncLogs.isNotEmpty) {
          final syncLogId = syncLogs.first['id'];
          await _completeSyncLog(syncLogId, 'failed', errorMessage: e.toString());
        }
      }
      
      _isSyncing = false;
      _currentSyncTable = null;
      
      return false;
    }
  }
  
  // Buat log sinkronisasi
  Future<int> _createSyncLog(String deviceId, int userId, int branchId) async {
    final syncLog = {
      'device_id': deviceId,
      'user_id': userId,
      'branch_id': branchId,
      'sync_type': 'full',
      'sync_status': 'in_progress',
      'start_time': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
    
    return await databaseService.insert(AppConstants.tableSyncLog, syncLog);
  }
  
  // Selesaikan log sinkronisasi
  Future<void> _completeSyncLog(int syncLogId, String status, {String? errorMessage}) async {
    final updatedLog = {
      'sync_status': status,
      'end_time': DateTime.now().toIso8601String(),
      'error_message': errorMessage,
    };
    
    await databaseService.update(
      AppConstants.tableSyncLog,
      updatedLog,
      'id = ?',
      [syncLogId],
    );
  }
  
  // Sinkronisasi data ke server
  Future<void> _syncTableToServer(String table, int syncLogId, int branchId, String token) async {
    logger.i('Syncing $table to server');
    
    // Ambil data yang belum disinkronkan (sync_status = 'pending')
    final pendingData = await databaseService.query(
      table,
      where: "sync_status = ?",
      whereArgs: ['pending'],
    );
    
    if (pendingData.isEmpty) {
      logger.i('No pending data for $table');
      return;
    }
    
    // Kirim data ke server
    for (var item in pendingData) {
      try {
        // Tentukan endpoint berdasarkan tabel
        String endpoint = _getEndpointForTable(table);
        
        // Kirim data ke server
        final isNewRecord = item['id'] < 0; // ID negatif untuk record baru yang dibuat offline
        final serverResponse = isNewRecord
            ? await apiService.post(endpoint, item, token: token)
            : await apiService.put('$endpoint/${item['id']}', item, token: token);
        
        // Update data lokal dengan ID dari server jika perlu
        if (isNewRecord && serverResponse['data'] != null) {
          final serverItem = serverResponse['data'];
          
          // Update ID lokal dengan ID dari server
          await _updateLocalRecordWithServerId(table, item['id'], serverItem['id']);
        }
        
        // Update status sinkronisasi
        await databaseService.update(
          table,
          {'sync_status': 'completed'},
          'id = ?',
          [item['id']],
        );
        
        // Catat detail sinkronisasi
        await _logSyncDetail(syncLogId, table, item['id'], 'upload', 'completed');
      } catch (e) {
        logger.e('Error syncing item ${item['id']} from $table: $e');
        
        // Catat detail sinkronisasi dengan error
        await _logSyncDetail(syncLogId, table, item['id'], 'upload', 'failed', errorMessage: e.toString());
      }
    }
  }
  
  // Sinkronisasi data dari server
  Future<void> _syncTableFromServer(String table, int syncLogId, int branchId, String token) async {
    logger.i('Syncing $table from server');
    
    try {
      // Tentukan endpoint berdasarkan tabel
      String endpoint = _getEndpointForTable(table);
      
      // Ambil timestamp sinkronisasi terakhir
      final lastSync = await _getLastSuccessfulSyncTime();
      
      // Parameter untuk mengambil data yang diperbarui sejak sinkronisasi terakhir
      final params = <String, dynamic>{
        'updated_after': lastSync?.toIso8601String(),
        'branch_id': branchId.toString(),
        'limit': '1000', // Batasi jumlah data yang diambil dalam satu kali
      };
      
      // Ambil data dari server
      final response = await apiService.get(endpoint, queryParams: params, token: token);
      
      final List<dynamic> serverData = response['data'];
      
      // Update database lokal
      for (var item in serverData) {
        await databaseService.transaction((txn) async {
          // Cek apakah data sudah ada di lokal
          final existingItems = await txn.query(
            table,
            where: 'id = ?',
            whereArgs: [item['id']],
            limit: 1,
          );
          
          if (existingItems.isEmpty) {
            // Tambahkan data baru
            item['sync_status'] = 'completed';
            await txn.insert(table, item, conflictAlgorithm: ConflictAlgorithm.replace);
          } else {
            // Update data yang sudah ada jika versi server lebih baru
            final existingItem = existingItems.first;
            
            // Skip jika data lokal dalam status pending (belum disinkronkan)
            if (existingItem['sync_status'] == 'pending') {
              return;
            }
            
            // Update data lokal
            item['sync_status'] = 'completed';
            await txn.update(
              table,
              item,
              where: 'id = ?',
              whereArgs: [item['id']],
            );
          }
          
          // Catat detail sinkronisasi
          await _logSyncDetail(syncLogId, table, item['id'], 'download', 'completed');
        });
      }
    } catch (e) {
      logger.e('Error syncing $table from server: $e');
      
      // Catat error pada log sinkronisasi
      await _logSyncDetail(syncLogId, table, null, 'download', 'failed', errorMessage: e.toString());
      
      // Re-throw error untuk dihandle di level atas
      rethrow;
    }
  }
  
  // Update record lokal dengan ID dari server
  Future<void> _updateLocalRecordWithServerId(String table, int localId, int serverId) async {
    // Update ID pada tabel utama
    await databaseService.rawQuery(
      'UPDATE $table SET id = ?, sync_status = ? WHERE id = ?',
      [serverId, 'completed', localId],
    );
    
    // Update semua tabel terkait yang mereferensikan ID ini
    final relatedTables = _getRelatedTables(table);
    final foreignKeyColumn = _getForeignKeyColumn(table);
    
    for (var relatedTable in relatedTables) {
      await databaseService.rawQuery(
        'UPDATE $relatedTable SET $foreignKeyColumn = ? WHERE $foreignKeyColumn = ?',
        [serverId, localId],
      );
    }
  }
  
  // Catat detail sinkronisasi
  Future<void> _logSyncDetail(
    int syncId,
    String tableName,
    int? recordId,
    String action,
    String status, {
    String? errorMessage,
  }) async {
    final syncDetail = {
      'sync_id': syncId,
      'table_name': tableName,
      'record_id': recordId,
      'sync_action': action,
      'sync_status': status,
      'error_message': errorMessage,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    await databaseService.insert('sync_details', syncDetail);
  }
  
  // Dapatkan waktu sinkronisasi terakhir yang berhasil
  Future<DateTime?> _getLastSuccessfulSyncTime() async {
    final syncLogs = await databaseService.query(
      AppConstants.tableSyncLog,
      where: 'sync_status = ?',
      whereArgs: ['completed'],
      orderBy: 'end_time DESC',
      limit: 1,
    );
    
    if (syncLogs.isEmpty) {
      return null;
    }
    
    final lastSyncLog = syncLogs.first;
    final endTimeStr = lastSyncLog['end_time'];
    
    if (endTimeStr == null) {
      return null;
    }
    
    return DateTime.parse(endTimeStr.toString());
  }
  
  // Dapatkan endpoint API untuk tabel
  String _getEndpointForTable(String table) {
    switch (table) {
      case AppConstants.tableUsers:
        return '/users';
      case AppConstants.tableBranches:
        return '/branches';
      case AppConstants.tableProducts:
        return '/products';
      case AppConstants.tableCategories:
        return '/categories';
      case AppConstants.tableInventory:
        return '/inventory';
      case AppConstants.tableTransactions:
        return '/transactions';
      case AppConstants.tableTransactionItems:
        return '/transaction-items';
      case AppConstants.tableCustomers:
        return '/customers';
      case AppConstants.tablePayments:
        return '/payments';
      default:
        return '/$table';
    }
  }
  
  // Dapatkan tabel terkait yang referensi ke tabel tertentu
  List<String> _getRelatedTables(String table) {
    switch (table) {
      case AppConstants.tableUsers:
        return [
          AppConstants.tableTransactions,
          AppConstants.tablePayments,
        ];
      case AppConstants.tableBranches:
        return [
          AppConstants.tableUsers,
          AppConstants.tableInventory,
          AppConstants.tableTransactions,
        ];
      case AppConstants.tableProducts:
        return [
          AppConstants.tableInventory,
          AppConstants.tableTransactionItems,
        ];
      case AppConstants.tableCategories:
        return [AppConstants.tableProducts];
      case AppConstants.tableTransactions:
        return [
          AppConstants.tableTransactionItems,
          AppConstants.tablePayments,
        ];
      case AppConstants.tableCustomers:
        return [AppConstants.tableTransactions];
      default:
        return [];
    }
  }
  
  // Dapatkan nama kolom foreign key untuk referensi ke tabel tertentu
  String _getForeignKeyColumn(String table) {
    switch (table) {
      case AppConstants.tableUsers:
        return 'user_id';
      case AppConstants.tableBranches:
        return 'branch_id';
      case AppConstants.tableProducts:
        return 'product_id';
      case AppConstants.tableCategories:
        return 'category_id';
      case AppConstants.tableTransactions:
        return 'transaction_id';
      case AppConstants.tableCustomers:
        return 'customer_id';
      default:
        return '${table.substring(0, table.length - 1)}_id';
    }
  }
}