// services/expense_service.dart
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'dart:io';

class ExpenseService {
  final ApiService apiService;
  final DatabaseService databaseService;
  final Logger logger = Logger();

  ExpenseService({
    required this.apiService, 
    required this.databaseService
  });

  // Get expenses with optional filtering
  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int? supplierId,
    String? status,
    int? userId,
    int? branchId,
    String? search,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    try {
      // Try to get from API first
      try {
        final queryParams = {
          'page': page.toString(),
          'limit': limit.toString(),
        };
        
        if (startDate != null) {
          queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
        }
        
        if (endDate != null) {
          queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
        }
        
        if (category != null) queryParams['category'] = category;
        if (supplierId != null) queryParams['supplier_id'] = supplierId.toString();
        if (status != null) queryParams['status'] = status;
        if (userId != null) queryParams['user_id'] = userId.toString();
        if (branchId != null) queryParams['branch_id'] = branchId.toString();
        if (search != null) queryParams['search'] = search;
        
        final response = await apiService.get(
          '/expenses',
          queryParams: queryParams,
          token: token,
        );
        
        final List<dynamic> data = response['data'];
        final List<Expense> expenses = data
            .map((item) => Expense.fromMap(item))
            .toList();
        
        // Save to local database for offline use
        _saveExpensesToLocalDB(expenses);
        
        return expenses;
      } catch (e) {
        logger.w('Failed to get expenses from API, using local data: $e');
      }
      
      // If offline or API call fails, get from local database
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (startDate != null) {
        whereClause += 'expense_date >= ?';
        whereArgs.add(DateFormat('yyyy-MM-dd').format(startDate));
      }
      
      if (endDate != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'expense_date <= ?';
        whereArgs.add(DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1))));
      }
      
      if (category != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'category = ?';
        whereArgs.add(category);
      }
      
      if (supplierId != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'supplier_id = ?';
        whereArgs.add(supplierId);
      }
      
      if (status != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'status = ?';
        whereArgs.add(status);
      }
      
      if (userId != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'user_id = ?';
        whereArgs.add(userId);
      }
      
      if (branchId != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'branch_id = ?';
        whereArgs.add(branchId);
      }
      
      if (search != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += '(description LIKE ? OR reference_number LIKE ? OR notes LIKE ?)';
        whereArgs.add('%$search%');
        whereArgs.add('%$search%');
        whereArgs.add('%$search%');
      }
      
      final expenseMaps = await databaseService.query(
        'expenses',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        limit: limit,
        offset: (page - 1) * limit,
        orderBy: 'expense_date DESC',
      );
      
      return expenseMaps.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      logger.e('Error getting expenses: $e');
      rethrow;
    }
  }

  // Get expense by ID
  Future<Expense> getExpenseById(int id, {String? token}) async {
    try {
      // Try to get from API first
      try {
        final response = await apiService.get('/expenses/$id', token: token);
        
        final Expense expense = Expense.fromMap(response['data']);
        
        // Update in local database
        await databaseService.update(
          'expenses',
          expense.toMap(),
          'id = ?',
          [id],
        );
        
        return expense;
      } catch (e) {
        logger.w('Failed to get expense from API, using local data: $e');
      }
      
      // If offline or API call fails, get from local database
      final expenseMaps = await databaseService.query(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (expenseMaps.isEmpty) {
        throw Exception('Expense not found');
      }
      
      return Expense.fromMap(expenseMaps.first);
    } catch (e) {
      logger.e('Error getting expense by id: $e');
      rethrow;
    }
  }

  // Create a new expense
  Future<Expense> createExpense(Expense expense, {String? token}) async {
    try {
      // Try to create in API first
      try {
        final response = await apiService.post(
          '/expenses',
          expense.toMap(),
          token: token,
        );
        
        final Expense newExpense = Expense.fromMap(response['data']);
        
        // Save to local database
        await databaseService.insert(
          'expenses',
          newExpense.toMap(),
        );
        
        return newExpense;
      } catch (e) {
        logger.w('Failed to create expense in API, saving locally only: $e');
      }
      
      // If offline or API call fails, save to local database only
      // Generate temporary ID for offline mode
      final lastExpenseMaps = await databaseService.query(
        'expenses',
        orderBy: 'id DESC',
        limit: 1,
      );
      
      int tempId = 1;
      if (lastExpenseMaps.isNotEmpty) {
        tempId = lastExpenseMaps.first['id'] + 1;
      }
      
      final offlineExpense = expense.copyWith(
        id: tempId,
        syncStatus: 'pending',
      );
      
      final id = await databaseService.insert(
        'expenses',
        offlineExpense.toMap(),
      );
      
      return offlineExpense.copyWith(id: id);
    } catch (e) {
      logger.e('Error creating expense: $e');
      rethrow;
    }
  }

  // Update an existing expense
  Future<Expense> updateExpense(Expense expense, {String? token}) async {
    try {
      // Try to update in API first
      try {
        final response = await apiService.put(
          '/expenses/${expense.id}',
          expense.toMap(),
          token: token,
        );
        
        final Expense updatedExpense = Expense.fromMap(response['data']);
        
        // Update in local database
        await databaseService.update(
          'expenses',
          updatedExpense.toMap(),
          'id = ?',
          [expense.id],
        );
        
        return updatedExpense;
      } catch (e) {
        logger.w('Failed to update expense in API, updating locally only: $e');
      }
      
      // If offline or API call fails, update local database only
      final offlineExpense = expense.copyWith(
        syncStatus: 'pending',
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      await databaseService.update(
        'expenses',
        offlineExpense.toMap(),
        'id = ?',
        [expense.id],
      );
      
      return offlineExpense;
    } catch (e) {
      logger.e('Error updating expense: $e');
      rethrow;
    }
  }

  // Delete an expense
  Future<bool> deleteExpense(int id, {String? token}) async {
    try {
      try {
        await apiService.delete(
          '/expenses/$id',
          token: token,
        );
        
        // Delete from local database
        await databaseService.delete(
          'expenses',
          'id = ?',
          [id],
        );
        
        return true;
      } catch (e) {
        logger.w('Failed to delete expense in API, marking for deletion: $e');
      }
      
      // If offline or API call fails, mark for deletion in local database
      await databaseService.update(
        'expenses',
        {
          'status': 'deleted',
          'sync_status': 'pending',
          'updated_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [id],
      );
      
      return true;
    } catch (e) {
      logger.e('Error deleting expense: $e');
      rethrow;
    }
  }

  // Get expense categories
  Future<List<String>> getExpenseCategories({String? token}) async {
    try {
      // Try to get from API first
      try {
        final response = await apiService.get('/expense-categories', token: token);
        
        final List<dynamic> data = response['data'];
        final List<String> categories = data.map((item) => item['name'].toString()).toList();
        
        return categories;
      } catch (e) {
        logger.w('Failed to get expense categories from API, using predefined list: $e');
      }
      
      // If offline or API call fails, return predefined list
      return [
        Expense.categoryUtilities,
        Expense.categoryRent,
        Expense.categorySupplies,
        Expense.categorySalary,
        Expense.categoryMarketing,
        Expense.categoryMaintenance,
        Expense.categoryEquipment,
        Expense.categoryTaxes,
        Expense.categoryInsurance,
        Expense.categoryOther,
      ];
    } catch (e) {
      logger.e('Error getting expense categories: $e');
      return [Expense.categoryOther]; // Return at least one default category
    }
  }

  // Get expense summary (total by category, by date, etc.)
  Future<Map<String, dynamic>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
    int? branchId,
    String? token,
  }) async {
    try {
      // Format dates for query
      final formattedStartDate = startDate != null 
          ? DateFormat('yyyy-MM-dd').format(startDate) 
          : DateFormat('yyyy-MM-dd').format(DateTime(DateTime.now().year, DateTime.now().month, 1));
          
      final formattedEndDate = endDate != null 
          ? DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1))) 
          : DateFormat('yyyy-MM-dd').format(DateTime(DateTime.now().year, DateTime.now().month + 1, 0).add(const Duration(days: 1)));
      
      // Build where clause
      String whereClause = 'expense_date BETWEEN ? AND ?';
      List<dynamic> whereArgs = [formattedStartDate, formattedEndDate];
      
      if (branchId != null) {
        whereClause += ' AND branch_id = ?';
        whereArgs.add(branchId);
      }
      
      // Try to get from API first
      try {
        final queryParams = {
          'start_date': formattedStartDate,
          'end_date': formattedEndDate,
        };
        
        if (branchId != null) {
          queryParams['branch_id'] = branchId.toString();
        }
        
        final response = await apiService.get(
          '/expense-summary',
          queryParams: queryParams,
          token: token,
        );
        
        return response['data'];
      } catch (e) {
        logger.w('Failed to get expense summary from API, calculating locally: $e');
      }
      
      // If offline or API call fails, calculate from local database
      final expenseMaps = await databaseService.query(
        'expenses',
        where: whereClause,
        whereArgs: whereArgs,
      );
      
      final expenses = expenseMaps.map((map) => Expense.fromMap(map)).toList();
      
      // Calculate summary data
      double totalAmount = 0;
      Map<String, double> byCategory = {};
      Map<String, double> byMonth = {};
      
      for (var expense in expenses) {
        // Total amount
        totalAmount += expense.amount;
        
        // By category
        final category = expense.category;
        if (byCategory.containsKey(category)) {
          byCategory[category] = byCategory[category]! + expense.amount;
        } else {
          byCategory[category] = expense.amount;
        }
        
        // By month
        final monthKey = DateFormat('yyyy-MM').format(expense.expenseDate);
        if (byMonth.containsKey(monthKey)) {
          byMonth[monthKey] = byMonth[monthKey]! + expense.amount;
        } else {
          byMonth[monthKey] = expense.amount;
        }
      }
      
      return {
        'total_amount': totalAmount,
        'by_category': byCategory,
        'by_month': byMonth,
        'count': expenses.length,
      };
    } catch (e) {
      logger.e('Error getting expense summary: $e');
      rethrow;
    }
  }

  // Upload expense attachment
  Future<String> uploadExpenseAttachment(int expenseId, String filePath, {String? token}) async {
    try {
      final file = File(filePath);
      
      final response = await apiService.uploadFile(
        '/expenses/$expenseId/attachment',
        file,
        'attachment',
        token: token,
      );
      
      final String attachmentUrl = response['data']['url'];
      
      // Update expense in local database
      await databaseService.update(
        'expenses',
        {'attachment_url': attachmentUrl},
        'id = ?',
        [expenseId],
      );
      
      return attachmentUrl;
    } catch (e) {
      logger.e('Error uploading expense attachment: $e');
      rethrow;
    }
  }

  // Save expenses to local database
  Future<void> _saveExpensesToLocalDB(List<Expense> expenses) async {
    try {
      await databaseService.transaction((txn) async {
        for (var expense in expenses) {
          // Check if expense exists
          final existingExpenses = await txn.query(
            'expenses',
            where: 'id = ?',
            whereArgs: [expense.id],
            limit: 1,
          );
          
          if (existingExpenses.isEmpty) {
            // Insert new expense
            await txn.insert(
              'expenses',
              expense.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } else {
            // Update existing expense if it's not pending sync
            final existingExpense = existingExpenses.first;
            if (existingExpense['sync_status'] != 'pending') {
              await txn.update(
                'expenses',
                expense.toMap(),
                where: 'id = ?',
                whereArgs: [expense.id],
              );
            }
          }
        }
      });
    } catch (e) {
      logger.e('Error saving expenses to local DB: $e');
    }
  }
}