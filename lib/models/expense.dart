// models/expense.dart
import 'dart:convert';

class Expense {
  final int? id;
  final String description;
  final double amount;
  final String category;
  final DateTime expenseDate;
  final int? supplierId;
  final String? referenceNumber;
  final String? notes;
  final String? attachmentUrl;
  final int? userId;
  final int branchId;
  final String? paymentMethod;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? syncStatus;

  // Additional fields for UI display
  final String? supplierName;
  final String? userName;
  final String? branchName;

  Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.expenseDate,
    this.supplierId,
    this.referenceNumber,
    this.notes,
    this.attachmentUrl,
    this.userId,
    required this.branchId,
    this.paymentMethod,
    this.status = 'completed',
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 'pending',
    
    // Additional fields
    this.supplierName,
    this.userName,
    this.branchName,
  });

  // Create a copy of this expense with given fields replaced with new values
  Expense copyWith({
    int? id,
    String? description,
    double? amount,
    String? category,
    DateTime? expenseDate,
    int? supplierId,
    String? referenceNumber,
    String? notes,
    String? attachmentUrl,
    int? userId,
    int? branchId,
    String? paymentMethod,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
    String? supplierName,
    String? userName,
    String? branchName,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      expenseDate: expenseDate ?? this.expenseDate,
      supplierId: supplierId ?? this.supplierId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      userId: userId ?? this.userId,
      branchId: branchId ?? this.branchId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      supplierName: supplierName ?? this.supplierName,
      userName: userName ?? this.userName,
      branchName: branchName ?? this.branchName,
    );
  }

  // Convert Expense instance to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'expense_date': expenseDate.toIso8601String(),
      'supplier_id': supplierId,
      'reference_number': referenceNumber,
      'notes': notes,
      'attachment_url': attachmentUrl,
      'user_id': userId,
      'branch_id': branchId,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
    };
  }

  // Create Expense instance from Map (database or API)
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      description: map['description'],
      amount: map['amount'] is int ? 
        (map['amount'] as int).toDouble() : (map['amount'] ?? 0.0),
      category: map['category'],
      expenseDate: map['expense_date'] is String ? 
        DateTime.parse(map['expense_date']) : DateTime.now(),
      supplierId: map['supplier_id'],
      referenceNumber: map['reference_number'],
      notes: map['notes'],
      attachmentUrl: map['attachment_url'],
      userId: map['user_id'],
      branchId: map['branch_id'],
      paymentMethod: map['payment_method'],
      status: map['status'] ?? 'completed',
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'] ?? 'pending',
      supplierName: map['supplier_name'],
      userName: map['user_name'],
      branchName: map['branch_name'],
    );
  }

  // Convert Expense instance to JSON string
  String toJson() => json.encode(toMap());

  // Create Expense instance from JSON string
  factory Expense.fromJson(String source) => Expense.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Expense(id: $id, description: $description, amount: $amount, category: $category, date: $expenseDate)';
  }

  // Expense category constants
  static const String CATEGORY_UTILITIES = 'Utilities';
  static const String CATEGORY_RENT = 'Rent';
  static const String CATEGORY_SUPPLIES = 'Supplies';
  static const String CATEGORY_SALARY = 'Salary';
  static const String CATEGORY_MARKETING = 'Marketing';
  static const String CATEGORY_MAINTENANCE = 'Maintenance';
  static const String CATEGORY_EQUIPMENT = 'Equipment';
  static const String CATEGORY_TAXES = 'Taxes';
  static const String CATEGORY_INSURANCE = 'Insurance';
  static const String CATEGORY_OTHER = 'Other';

  // Status constants
  static const String STATUS_COMPLETED = 'completed';
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_CANCELLED = 'cancelled';

  // Payment method constants
  static const String PAYMENT_CASH = 'cash';
  static const String PAYMENT_TRANSFER = 'bank_transfer';
  static const String PAYMENT_DEBIT = 'debit_card';
  static const String PAYMENT_CREDIT = 'credit_card';
  static const String PAYMENT_EWALLET = 'e_wallet';
}