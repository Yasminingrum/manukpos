// stock_opname.dart
class StockOpname {
  final int id;
  final int branchId;
  final int userId;
  final String opnameDate;
  final String referenceNumber;
  final String? notes;
  final String status;
  final String? completedAt;

  StockOpname({
    required this.id,
    required this.branchId,
    required this.userId,
    required this.opnameDate,
    required this.referenceNumber,
    this.notes,
    required this.status,
    this.completedAt,
  });

  // Create a copy of this stock opname with some updated fields
  StockOpname copyWith({
    int? id,
    int? branchId,
    int? userId,
    String? opnameDate,
    String? referenceNumber,
    String? notes,
    String? status,
    String? completedAt,
  }) {
    return StockOpname(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      userId: userId ?? this.userId,
      opnameDate: opnameDate ?? this.opnameDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Factory method to create a StockOpname from a Map
  factory StockOpname.fromMap(Map<String, dynamic> map) {
    return StockOpname(
      id: map['id'] as int,
      branchId: map['branch_id'] as int,
      userId: map['user_id'] as int,
      opnameDate: map['opname_date'] as String,
      referenceNumber: map['reference_number'] as String,
      notes: map['notes'] as String?,
      status: map['status'] as String,
      completedAt: map['completed_at'] as String?,
    );
  }

  // Convert this StockOpname to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch_id': branchId,
      'user_id': userId,
      'opname_date': opnameDate,
      'reference_number': referenceNumber,
      'notes': notes,
      'status': status,
      'completed_at': completedAt,
    };
  }
}

class StockOpnameItem {
  final int id;
  final int stockOpnameId;
  final int productId;
  final String productName;
  final String productSku;
  final double systemStock;
  final double physicalStock;
  final double difference;
  final double? adjustmentValue;
  final String notes;

  StockOpnameItem({
    required this.id,
    required this.stockOpnameId,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.systemStock,
    required this.physicalStock,
    required this.difference,
    this.adjustmentValue,
    this.notes = '',
  });

  // Create a copy of this stock opname item with some updated fields
  StockOpnameItem copyWith({
    int? id,
    int? stockOpnameId,
    int? productId,
    String? productName,
    String? productSku,
    double? systemStock,
    double? physicalStock,
    double? difference,
    double? adjustmentValue,
    String? notes,
  }) {
    return StockOpnameItem(
      id: id ?? this.id,
      stockOpnameId: stockOpnameId ?? this.stockOpnameId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      systemStock: systemStock ?? this.systemStock,
      physicalStock: physicalStock ?? this.physicalStock,
      difference: difference ?? this.difference,
      adjustmentValue: adjustmentValue ?? this.adjustmentValue,
      notes: notes ?? this.notes,
    );
  }

  // Factory method to create a StockOpnameItem from a Map
  factory StockOpnameItem.fromMap(Map<String, dynamic> map) {
    return StockOpnameItem(
      id: map['id'] as int,
      stockOpnameId: map['stock_opname_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      productSku: map['product_sku'] as String,
      systemStock: map['system_stock'] as double,
      physicalStock: map['physical_stock'] as double,
      difference: map['difference'] as double,
      adjustmentValue: map['adjustment_value'] as double?,
      notes: map['notes'] as String? ?? '',
    );
  }

  // Convert this StockOpnameItem to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stock_opname_id': stockOpnameId,
      'product_id': productId,
      'system_stock': systemStock,
      'physical_stock': physicalStock,
      'difference': difference,
      'adjustment_value': adjustmentValue,
      'notes': notes,
    };
  }
}