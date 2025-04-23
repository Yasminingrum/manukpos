// models/transaction.dart
import 'dart:convert';
import 'transaction_item.dart';

class Transaction {
  final int? id;
  final String invoiceNumber;
  final String? invoiceDate;
  final int? customerId;
  final int userId;
  final int branchId;
  final String? transactionDate;
  final String? dueDate;
  final double subtotal;
  final int? discountId;
  final double discountAmount;
  final int? taxId;
  final double taxAmount;
  final int? feeId;
  final double feeAmount;
  final double shippingCost;
  final double grandTotal;
  final double amountPaid;
  final double amountReturned;
  final String paymentStatus;
  final int pointsEarned;
  final int pointsUsed;
  final String? notes;
  final String status;
  final int? referenceId;
  final String? shippingAddress;
  final String? shippingTracking;
  final String? createdAt;
  final String? updatedAt;
  final String? syncStatus;
  // Add transaction type field
  final String type;
  
  // Additional fields for UI display
  final String? customerName;
  final String? userName;
  final String? branchName;
  final List<TransactionItem>? items;

  Transaction({
    this.id,
    required this.invoiceNumber,
    this.invoiceDate,
    this.customerId,
    required this.userId,
    required this.branchId,
    this.transactionDate,
    this.dueDate,
    required this.subtotal,
    this.discountId,
    this.discountAmount = 0,
    this.taxId,
    this.taxAmount = 0,
    this.feeId,
    this.feeAmount = 0,
    this.shippingCost = 0,
    required this.grandTotal,
    this.amountPaid = 0,
    this.amountReturned = 0,
    this.paymentStatus = 'unpaid',
    this.pointsEarned = 0,
    this.pointsUsed = 0,
    this.notes,
    this.status = 'completed',
    this.referenceId,
    this.shippingAddress,
    this.shippingTracking,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 'pending',
    this.type = 'sale', // Default value for type
    
    // Additional fields
    this.customerName,
    this.userName,
    this.branchName,
    this.items,
  });

  // Get remaining payment amount
  double get remainingAmount => grandTotal - amountPaid;

  // Check if transaction is completely paid
  bool get isPaid => paymentStatus == 'paid' || amountPaid >= grandTotal;

  // Check if this is a credit transaction
  bool get isCredit => dueDate != null;

  // Check if this transaction is overdue
  bool isOverdue(DateTime currentDate) {
    if (dueDate == null || isPaid) return false;
    final due = DateTime.parse(dueDate!);
    return currentDate.isAfter(due);
  }

  // Create a copy of this transaction with given fields replaced with new values
  Transaction copyWith({
    int? id,
    String? invoiceNumber,
    String? invoiceDate,
    int? customerId,
    int? userId,
    int? branchId,
    String? transactionDate,
    String? dueDate,
    double? subtotal,
    int? discountId,
    double? discountAmount,
    int? taxId,
    double? taxAmount,
    int? feeId,
    double? feeAmount,
    double? shippingCost,
    double? grandTotal,
    double? amountPaid,
    double? amountReturned,
    String? paymentStatus,
    int? pointsEarned,
    int? pointsUsed,
    String? notes,
    String? status,
    int? referenceId,
    String? shippingAddress,
    String? shippingTracking,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
    String? type,
    String? customerName,
    String? userName,
    String? branchName,
    List<TransactionItem>? items,
  }) {
    return Transaction(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      branchId: branchId ?? this.branchId,
      transactionDate: transactionDate ?? this.transactionDate,
      dueDate: dueDate ?? this.dueDate,
      subtotal: subtotal ?? this.subtotal,
      discountId: discountId ?? this.discountId,
      discountAmount: discountAmount ?? this.discountAmount,
      taxId: taxId ?? this.taxId,
      taxAmount: taxAmount ?? this.taxAmount,
      feeId: feeId ?? this.feeId,
      feeAmount: feeAmount ?? this.feeAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      grandTotal: grandTotal ?? this.grandTotal,
      amountPaid: amountPaid ?? this.amountPaid,
      amountReturned: amountReturned ?? this.amountReturned,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      pointsUsed: pointsUsed ?? this.pointsUsed,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      referenceId: referenceId ?? this.referenceId,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingTracking: shippingTracking ?? this.shippingTracking,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      type: type ?? this.type,
      customerName: customerName ?? this.customerName,
      userName: userName ?? this.userName,
      branchName: branchName ?? this.branchName,
      items: items ?? this.items,
    );
  }

  // Convert Transaction instance to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate,
      'customer_id': customerId,
      'user_id': userId,
      'branch_id': branchId,
      'transaction_date': transactionDate,
      'due_date': dueDate,
      'subtotal': subtotal,
      'discount_id': discountId,
      'discount_amount': discountAmount,
      'tax_id': taxId,
      'tax_amount': taxAmount,
      'fee_id': feeId,
      'fee_amount': feeAmount,
      'shipping_cost': shippingCost,
      'grand_total': grandTotal,
      'amount_paid': amountPaid,
      'amount_returned': amountReturned,
      'payment_status': paymentStatus,
      'points_earned': pointsEarned,
      'points_used': pointsUsed,
      'notes': notes,
      'status': status,
      'reference_id': referenceId,
      'shipping_address': shippingAddress,
      'shipping_tracking': shippingTracking,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'type': type,
    };
  }

  // Create Transaction instance from Map (database or API)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      invoiceDate: map['invoice_date'],
      customerId: map['customer_id'],
      userId: map['user_id'],
      branchId: map['branch_id'],
      transactionDate: map['transaction_date'],
      dueDate: map['due_date'],
      subtotal: map['subtotal'] is int ? 
        (map['subtotal'] as int).toDouble() : (map['subtotal'] ?? 0.0),
      discountId: map['discount_id'],
      discountAmount: map['discount_amount'] is int ? 
        (map['discount_amount'] as int).toDouble() : (map['discount_amount'] ?? 0.0),
      taxId: map['tax_id'],
      taxAmount: map['tax_amount'] is int ? 
        (map['tax_amount'] as int).toDouble() : (map['tax_amount'] ?? 0.0),
      feeId: map['fee_id'],
      feeAmount: map['fee_amount'] is int ? 
        (map['fee_amount'] as int).toDouble() : (map['fee_amount'] ?? 0.0),
      shippingCost: map['shipping_cost'] is int ? 
        (map['shipping_cost'] as int).toDouble() : (map['shipping_cost'] ?? 0.0),
      grandTotal: map['grand_total'] is int ? 
        (map['grand_total'] as int).toDouble() : (map['grand_total'] ?? 0.0),
      amountPaid: map['amount_paid'] is int ? 
        (map['amount_paid'] as int).toDouble() : (map['amount_paid'] ?? 0.0),
      amountReturned: map['amount_returned'] is int ? 
        (map['amount_returned'] as int).toDouble() : (map['amount_returned'] ?? 0.0),
      paymentStatus: map['payment_status'] ?? 'unpaid',
      pointsEarned: map['points_earned'] ?? 0,
      pointsUsed: map['points_used'] ?? 0,
      notes: map['notes'],
      status: map['status'] ?? 'completed',
      referenceId: map['reference_id'],
      shippingAddress: map['shipping_address'],
      shippingTracking: map['shipping_tracking'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'] ?? 'pending',
      type: map['type'] ?? 'sale',
      customerName: map['customer_name'],
      userName: map['user_name'],
      branchName: map['branch_name'],
      items: map['items'] != null ? 
        List<TransactionItem>.from(
          (map['items'] as List).map((item) => TransactionItem.fromMap(item))
        ) : null,
    );
  }

  // Convert Transaction instance to JSON string
  String toJson() => json.encode(toMap());

  // Create Transaction instance from JSON string
  factory Transaction.fromJson(String source) => Transaction.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Transaction(id: $id, invoice: $invoiceNumber, total: $grandTotal, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Transaction &&
      other.id == id &&
      other.invoiceNumber == invoiceNumber;
  }

  @override
  int get hashCode {
    return id.hashCode ^ invoiceNumber.hashCode;
  }
}