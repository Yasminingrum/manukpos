// services/auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../config/constants.dart';
import '../models/user.dart';
import '../models/branch.dart';
import 'database_service.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final DatabaseService databaseService;
  final ApiService apiService;
  final SharedPreferences sharedPreferences;
  final Logger logger = Logger();
  
  User? _currentUser;
  Branch? _currentBranch;
  String? _token;
  bool _isInitialized = false;
  
  AuthService({
    required this.databaseService,
    required this.apiService,
    required this.sharedPreferences,
  }) {
    _initializeAuthState();
  }
  
  // Getters
  User? get currentUser => _currentUser;
  Branch? get currentBranch => _currentBranch;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isInitialized => _isInitialized;
  
  // Initialize auth state from SharedPreferences
  Future<void> _initializeAuthState() async {
    try {
      // Load token
      _token = sharedPreferences.getString(AppConstants.tokenKey);
      
      // Load user data
      final userJson = sharedPreferences.getString(AppConstants.userDataKey);
      if (userJson != null) {
        _currentUser = User.fromJson(userJson);
      }
      
      // Load branch data
      final branchJson = sharedPreferences.getString(AppConstants.branchDataKey);
      if (branchJson != null) {
        _currentBranch = Branch.fromJson(branchJson);
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      logger.e('Error initializing auth state: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    // Wait for initialization to complete if needed
    if (!_isInitialized) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return !_isInitialized;
      });
    }
    
    return isAuthenticated;
  }
  
  // Login user
  Future<User> login(String username, String password) async {
    try {
      // First try online login
      try {
        final response = await apiService.post('/auth/login', {
          'username': username,
          'password': password,
        });
        
        // Save token
        _token = response['data']['token'];
        await sharedPreferences.setString(AppConstants.tokenKey, _token!);
        
        // Save user data
        _currentUser = User.fromMap(response['data']['user']);
        await sharedPreferences.setString(
          AppConstants.userDataKey,
          jsonEncode(_currentUser!.toMap())
        );
        
        // Save branch data
        _currentBranch = Branch.fromMap(response['data']['branch']);
        await sharedPreferences.setString(
          AppConstants.branchDataKey,
          jsonEncode(_currentBranch!.toMap())
        );
        
        // Update last login in local database
        await _updateUserLastLogin(_currentUser!);
        
        notifyListeners();
        return _currentUser!;
      } catch (e) {
        // If online login fails, try offline login
        logger.w('Online login failed, trying offline login: $e');
      }
      
      // Offline login
      final users = await databaseService.query(
        AppConstants.tableUsers,
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );
      
      if (users.isEmpty) {
        throw Exception('User not found');
      }
      
      final user = User.fromMap(users.first);
      
      // Simple password comparison for offline mode
      // In a real app, use proper password hashing/verification
      if (user.passwordHash != password) {
        throw Exception('Invalid password');
      }
      
      // Save user data locally
      _currentUser = user;
      await sharedPreferences.setString(
        AppConstants.userDataKey,
        jsonEncode(user.toMap())
      );
      
      // Get branch data
      if (user.branchId != null) {
        final branches = await databaseService.query(
          AppConstants.tableBranches,
          where: 'id = ?',
          whereArgs: [user.branchId],
          limit: 1,
        );
        
        if (branches.isNotEmpty) {
          _currentBranch = Branch.fromMap(branches.first);
          await sharedPreferences.setString(
            AppConstants.branchDataKey,
            jsonEncode(_currentBranch!.toMap())
          );
        }
      }
      
      // Update last login
      await _updateUserLastLogin(user);
      
      // Generate a temporary token for offline mode
      _token = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      await sharedPreferences.setString(AppConstants.tokenKey, _token!);
      
      notifyListeners();
      return user;
    } catch (e) {
      logger.e('Login error: $e');
      rethrow;
    }
  }
  
  // Update user's last login
  Future<void> _updateUserLastLogin(User user) async {
    try {
      final now = DateTime.now().toIso8601String();
      final loginCount = (user.loginCount ?? 0) + 1;
      
      await databaseService.update(
        AppConstants.tableUsers,
        {
          'last_login': now,
          'login_count': loginCount,
          'updated_at': now,
        },
        'id = ?',
        [user.id],
      );
    } catch (e) {
      logger.e('Error updating last login: $e');
    }
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      // Clear auth data from SharedPreferences
      await sharedPreferences.remove(AppConstants.tokenKey);
      await sharedPreferences.remove(AppConstants.userDataKey);
      await sharedPreferences.remove(AppConstants.branchDataKey);
      
      // Clear in-memory data
      _token = null;
      _currentUser = null;
      _currentBranch = null;
      
      notifyListeners();
    } catch (e) {
      logger.e('Error during logout: $e');
      rethrow;
    }
  }
  
  // Change current branch
  Future<void> changeBranch(Branch branch) async {
    try {
      // Update current branch
      _currentBranch = branch;
      await sharedPreferences.setString(
        AppConstants.branchDataKey,
        jsonEncode(branch.toMap())
      );
      
      notifyListeners();
    } catch (e) {
      logger.e('Error changing branch: $e');
      rethrow;
    }
  }
  
  // Update user profile
  Future<User> updateProfile(User updatedUser) async {
    try {
      // Try online update first
      try {
        final response = await apiService.put(
          '/users/${updatedUser.id}',
          updatedUser.toMap(),
          token: _token,
        );
        
        _currentUser = User.fromMap(response['data']);
        await sharedPreferences.setString(
          AppConstants.userDataKey,
          jsonEncode(_currentUser!.toMap())
        );
        
        notifyListeners();
        return _currentUser!;
      } catch (e) {
        // If online update fails, update locally
        logger.w('Online profile update failed, updating locally: $e');
      }
      
      // Update locally
      await databaseService.update(
        AppConstants.tableUsers,
        updatedUser.toMap(),
        'id = ?',
        [updatedUser.id],
      );
      
      _currentUser = updatedUser;
      await sharedPreferences.setString(
        AppConstants.userDataKey,
        jsonEncode(updatedUser.toMap())
      );
      
      notifyListeners();
      return updatedUser;
    } catch (e) {
      logger.e('Error updating profile: $e');
      rethrow;
    }
  }
  
  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      // Verify current password
      if (_currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // In a real app, use proper password hashing/verification
      if (_currentUser!.passwordHash != currentPassword) {
        throw Exception('Current password is incorrect');
      }
      
      // Try online update first
      try {
        await apiService.post(
          '/auth/change-password',
          {
            'current_password': currentPassword,
            'new_password': newPassword,
          },
          token: _token,
        );
      } catch (e) {
        // If online update fails, update locally
        logger.w('Online password change failed, updating locally: $e');
      }
      
      // Update locally
      await databaseService.update(
        AppConstants.tableUsers,
        {
          'password': newPassword,
          'updated_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [_currentUser!.id],
      );
      
      // Update current user
      _currentUser = _currentUser!.copyWith(passwordHash: newPassword);
      await sharedPreferences.setString(
        AppConstants.userDataKey,
        jsonEncode(_currentUser!.toMap())
      );
      
      return true;
    } catch (e) {
      logger.e('Error changing password: $e');
      rethrow;
    }
  }
  
  // Check user permissions
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    
    // Simplified permission check based on roles
    // In a real app, implement more sophisticated permission system
    switch (_currentUser!.role) {
      case 'admin':
        return true; // Admin has all permissions
      case 'manajer':
        // Manager can't access certain admin functions
        return permission != 'user_management' && 
               permission != 'system_settings';
      case 'kasir':
        // Cashier has limited permissions
        return permission == 'pos' || 
               permission == 'transactions' ||
               permission == 'products_view';
      case 'owner':
        // Owner has all permissions except system settings
        return permission != 'system_settings';
      default:
        return false;
    }
  }
}