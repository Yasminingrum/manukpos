// models/transaction_item.dart
import 'dart:convert';

class TransactionItem {
  final int? id;
  final int transactionId;
  final int productId;
  final double quantity;
  final double unitPrice;
  final double? originalPrice;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double subtotal;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final String? syncStatus;
  
  // Additional fields for UI display
  final String? productName;
  final String? productSku;
  final String? productBarcode;

  TransactionItem({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.originalPrice,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.taxPercent = 0,
    this.taxAmount = 0,
    required this.subtotal,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 'pending',
    
    // Additional fields
    this.productName,
    this.productSku,
    this.productBarcode,
  });

  // Create a copy of this transaction item with given fields replaced with new values
  TransactionItem copyWith({
    int? id,
    int? transactionId,
    int? productId,
    double? quantity,
    double? unitPrice,
    double? originalPrice,
    double? discountPercent,
    double? discountAmount,
    double? taxPercent,
    double? taxAmount,
    double? subtotal,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
    String? productName,
    String? productSku,
    String? productBarcode,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      subtotal: subtotal ?? this.subtotal,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      productBarcode: productBarcode ?? this.productBarcode,
    );
  }

  // Convert TransactionItem instance to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'original_price': originalPrice,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'subtotal': subtotal,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
    };
  }

  // Create TransactionItem instance from Map (database or API)
  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      transactionId: map['transaction_id'],
      productId: map['product_id'],
      quantity: map['quantity'] is int ? 
        (map['quantity'] as int).toDouble() : (map['quantity'] ?? 0.0),
      unitPrice: map['unit_price'] is int ? 
        (map['unit_price'] as int).toDouble() : (map['unit_price'] ?? 0.0),
      originalPrice: map['original_price'] != null ? 
        (map['original_price'] is int ? 
          (map['original_price'] as int).toDouble() : 
          map['original_price']) : null,
      discountPercent: map['discount_percent'] is int ? 
        (map['discount_percent'] as int).toDouble() : (map['discount_percent'] ?? 0.0),
      discountAmount: map['discount_amount'] is int ? 
        (map['discount_amount'] as int).toDouble() : (map['discount_amount'] ?? 0.0),
      taxPercent: map['tax_percent'] is int ? 
        (map['tax_percent'] as int).toDouble() : (map['tax_percent'] ?? 0.0),
      taxAmount: map['tax_amount'] is int ? 
        (map['tax_amount'] as int).toDouble() : (map['tax_amount'] ?? 0.0),
      subtotal: map['subtotal'] is int ? 
        (map['subtotal'] as int).toDouble() : (map['subtotal'] ?? 0.0),
      notes: map['notes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'] ?? 'pending',
      productName: map['product_name'],
      productSku: map['product_sku'],
      productBarcode: map['product_barcode'],
    );
  }

  // Convert TransactionItem instance to JSON string
  String toJson() => json.encode(toMap());

  // Create TransactionItem instance from JSON string
  factory TransactionItem.fromJson(String source) => TransactionItem.fromMap(json.decode(source));

  @override
  String toString() {
    return 'TransactionItem(id: $id, productId: $productId, qty: $quantity, price: $unitPrice, subtotal: $subtotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is TransactionItem &&
      other.id == id &&
      other.transactionId == transactionId &&
      other.productId == productId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      transactionId.hashCode ^
      productId.hashCode;
  }
}