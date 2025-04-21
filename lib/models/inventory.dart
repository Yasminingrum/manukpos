// models/inventory.dart
class InventoryItem {
  final int id;
  final int productId;
  final int branchId;
  final String branchName;
  final double quantity;
  final double reservedQuantity;
  final int minStockLevel;
  final int? maxStockLevel;
  final int? reorderPoint;
  final String? shelfLocation;
  final String? lastStockUpdate;
  final String? lastCountingDate;
  final String createdAt;
  final String updatedAt;

  // Computed property
  double get availableQuantity => quantity - reservedQuantity;
  
  // Check if stock is low
  bool get isLowStock => quantity <= minStockLevel;

  InventoryItem({
    required this.id,
    required this.productId,
    required this.branchId,
    required this.branchName,
    required this.quantity,
    this.reservedQuantity = 0,
    required this.minStockLevel,
    this.maxStockLevel,
    this.reorderPoint,
    this.shelfLocation,
    this.lastStockUpdate,
    this.lastCountingDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      productId: json['product_id'],
      branchId: json['branch_id'],
      branchName: json['branch_name'] ?? 'Unknown Branch',
      quantity: json['quantity'].toDouble(),
      reservedQuantity: json['reserved_quantity']?.toDouble() ?? 0,
      minStockLevel: json['min_stock_level'] ?? 0,
      maxStockLevel: json['max_stock_level'],
      reorderPoint: json['reorder_point'],
      shelfLocation: json['shelf_location'],
      lastStockUpdate: json['last_stock_update'],
      lastCountingDate: json['last_counting_date'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'branch_id': branchId,
      'quantity': quantity,
      'reserved_quantity': reservedQuantity,
      'min_stock_level': minStockLevel,
      'max_stock_level': maxStockLevel,
      'reorder_point': reorderPoint,
      'shelf_location': shelfLocation,
      'last_stock_update': lastStockUpdate,
      'last_counting_date': lastCountingDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}