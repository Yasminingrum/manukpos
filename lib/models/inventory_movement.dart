// models/inventory_movement.dart
import 'dart:convert';

class InventoryMovement {
  final int id;
  final int productId;
  final String productName;
  final String? productSku;
  final DateTime date;
  final String type; // 'in' or 'out'
  final double quantity;
  final String? referenceType; // e.g., 'purchase', 'sale', 'adjustment'
  final int? referenceId;
  final double? unitPrice;
  final String? notes;
  final int? userId;
  final int branchId;
  final String? createdAt;
  final String? syncStatus;

  InventoryMovement({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    required this.date,
    required this.type,
    required this.quantity,
    this.referenceType,
    this.referenceId,
    this.unitPrice,
    this.notes,
    this.userId,
    required this.branchId,
    this.createdAt,
    this.syncStatus,
  });

  // Create a copy with updated fields
  InventoryMovement copyWith({
    int? id,
    int? productId,
    String? productName,
    String? productSku,
    DateTime? date,
    String? type,
    double? quantity,
    String? referenceType,
    int? referenceId,
    double? unitPrice,
    String? notes,
    int? userId,
    int? branchId,
    String? createdAt,
    String? syncStatus,
  }) {
    return InventoryMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      date: date ?? this.date,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      unitPrice: unitPrice ?? this.unitPrice,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      branchId: branchId ?? this.branchId,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Convert from Map (database or API)
  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    return InventoryMovement(
      id: map['id'],
      productId: map['product_id'],
      productName: map['product_name'] ?? 'Unknown Product',
      productSku: map['product_sku'],
      date: map['date'] is String 
          ? DateTime.parse(map['date']) 
          : (map['date'] ?? DateTime.now()),
      type: map['type'],
      quantity: map['quantity'] is int 
          ? (map['quantity'] as int).toDouble() 
          : (map['quantity'] ?? 0.0),
      referenceType: map['reference_type'],
      referenceId: map['reference_id'],
      unitPrice: map['unit_price'] != null 
          ? (map['unit_price'] is int 
              ? (map['unit_price'] as int).toDouble() 
              : map['unit_price']) 
          : null,
      notes: map['notes'],
      userId: map['user_id'],
      branchId: map['branch_id'],
      createdAt: map['created_at'],
      syncStatus: map['sync_status'],
    );
  }

  // Convert to Map for database or API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'date': date.toIso8601String(),
      'type': type,
      'quantity': quantity,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'unit_price': unitPrice,
      'notes': notes,
      'user_id': userId,
      'branch_id': branchId,
      'created_at': createdAt,
      'sync_status': syncStatus,
    };
  }

  // Create from JSON string
  factory InventoryMovement.fromJson(String source) => 
      InventoryMovement.fromMap(json.decode(source));

  // Convert to JSON string
  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'InventoryMovement(id: $id, product: $productName, date: $date, type: $type, quantity: $quantity)';
  }

  // Constants for movement types
  static const String typeIn = 'in';
  static const String typeOut = 'out';
  
  // Constants for reference types
  static const String refPurchase = 'purchase';
  static const String refSale = 'sale';
  static const String refReturn = 'return';
  static const String refAdjustment = 'adjustment';
  static const String refTransfer = 'transfer';
}