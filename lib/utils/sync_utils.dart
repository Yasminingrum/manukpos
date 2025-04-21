// lib/utils/sync_utils.dart
import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Utility class for data synchronization operations
class SyncUtils {
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _syncStateKey = 'sync_state';
  
  /// Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTimeStr = prefs.getString(_lastSyncTimeKey);
    
    if (lastSyncTimeStr != null) {
      return DateTime.parse(lastSyncTimeStr);
    }
    
    return null;
  }
  
  /// Save last sync time
  static Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncTimeKey, time.toIso8601String());
  }
  
  /// Save sync state
  static Future<void> saveSyncState(Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncStateKey, jsonEncode(state));
  }
  
  /// Get sync state
  static Future<Map<String, dynamic>?> getSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateStr = prefs.getString(_syncStateKey);
    
    if (stateStr != null) {
      return jsonDecode(stateStr) as Map<String, dynamic>;
    }
    
    return null;
  }
  
  /// Clear sync state
  static Future<void> clearSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_syncStateKey);
  }
  
  /// Check if sync is needed
  static Future<bool> isSyncNeeded(Duration syncInterval) async {
    final lastSyncTime = await getLastSyncTime();
    
    if (lastSyncTime == null) {
      return true;
    }
    
    final now = DateTime.now();
    final diff = now.difference(lastSyncTime);
    
    return diff > syncInterval;
  }
  
  /// Get records that need to be synced from a table
  static Future<List<Map<String, dynamic>>> getPendingSyncRecords(
    Database db, 
    String tableName,
    {String syncStatusField = 'sync_status', String pendingStatus = 'pending'}
  ) async {
    final records = await db.query(
      tableName,
      where: '$syncStatusField = ?',
      whereArgs: [pendingStatus],
    );
    
    return records;
  }
  
  /// Mark records as synced
  static Future<void> markRecordsAsSynced(
    Database db, 
    String tableName, 
    List<int> ids,
    {String idField = 'id', String syncStatusField = 'sync_status', String syncedStatus = 'synced'}
  ) async {
    await db.update(
      tableName,
      {syncStatusField: syncedStatus},
      where: '$idField IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }
  
  /// Listen for connectivity changes
  static Stream<List<ConnectivityResult>> listenForConnectivity() {
    return Connectivity().onConnectivityChanged;
  }
  
  /// Queue a sync operation for later execution
  static Future<void> queueSyncOperation(
    String operation, 
    Map<String, dynamic> data
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final queueKey = 'sync_queue';
    
    List<String> queue = prefs.getStringList(queueKey) ?? [];
    
    final operationData = {
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    queue.add(jsonEncode(operationData));
    await prefs.setStringList(queueKey, queue);
  }
  
  /// Get queued sync operations
  static Future<List<Map<String, dynamic>>> getQueuedSyncOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final queueKey = 'sync_queue';
    
    List<String> queue = prefs.getStringList(queueKey) ?? [];
    
    return queue.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }
  
  /// Clear sync queue after processing
  static Future<void> clearSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueKey = 'sync_queue';
    
    await prefs.remove(queueKey);
  }
}