// models/product.dart
class Product {
  final int id;
  final String sku;
  final String? barcode;
  final String name;
  final String? description;
  final int categoryId;
  final String category; // Added category field (instead of categoryName)
  final double buyingPrice;
  final double sellingPrice;
  final double? discountPrice;
  final int minStock;
  final double? weight;
  final double? dimensionLength;
  final double? dimensionWidth;
  final double? dimensionHeight;
  final bool isService;
  final bool isActive;
  final bool isFeatured;
  final bool allowFractions;
  final String? imageUrl;
  final String? tags;
  final String createdAt;
  final String updatedAt;
  final String? syncStatus;

  Product({
    required this.id,
    required this.sku,
    this.barcode,
    required this.name,
    this.description,
    required this.categoryId,
    required this.category,
    required this.buyingPrice,
    required this.sellingPrice,
    this.discountPrice,
    this.minStock = 1,
    this.weight,
    this.dimensionLength,
    this.dimensionWidth,
    this.dimensionHeight,
    this.isService = false,
    this.isActive = true,
    this.isFeatured = false,
    this.allowFractions = false,
    this.imageUrl,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus,
  });

  // Create a copy of this product with updated fields
  Product copyWith({
    int? id,
    String? sku,
    String? barcode,
    String? name,
    String? description,
    int? categoryId,
    String? category,
    double? buyingPrice,
    double? sellingPrice,
    double? discountPrice,
    int? minStock,
    double? weight,
    double? dimensionLength,
    double? dimensionWidth,
    double? dimensionHeight,
    bool? isService,
    bool? isActive,
    bool? isFeatured,
    bool? allowFractions,
    String? imageUrl,
    String? tags,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      discountPrice: discountPrice ?? this.discountPrice,
      minStock: minStock ?? this.minStock,
      weight: weight ?? this.weight,
      dimensionLength: dimensionLength ?? this.dimensionLength,
      dimensionWidth: dimensionWidth ?? this.dimensionWidth,
      dimensionHeight: dimensionHeight ?? this.dimensionHeight,
      isService: isService ?? this.isService,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      allowFractions: allowFractions ?? this.allowFractions,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Create Product from JSON (same as existing fromJson)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      sku: json['sku'],
      barcode: json['barcode'],
      name: json['name'],
      description: json['description'],
      categoryId: json['category_id'],
      category: json['category_name'] ?? 'Uncategorized', // Get category name from response
      buyingPrice: json['buying_price'].toDouble(),
      sellingPrice: json['selling_price'].toDouble(),
      discountPrice: json['discount_price']?.toDouble(),
      minStock: json['min_stock'] ?? 1,
      weight: json['weight']?.toDouble(),
      dimensionLength: json['dimension_length']?.toDouble(),
      dimensionWidth: json['dimension_width']?.toDouble(),
      dimensionHeight: json['dimension_height']?.toDouble(),
      isService: json['is_service'] == 1,
      isActive: json['is_active'] == 1,
      isFeatured: json['is_featured'] == 1,
      allowFractions: json['allow_fractions'] == 1,
      imageUrl: json['image_url'],
      tags: json['tags'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      syncStatus: json['sync_status'],
    );
  }

  // Create Product from Map (alias for fromJson to fix the error)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product.fromJson(map);
  }

  // Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'discount_price': discountPrice,
      'min_stock': minStock,
      'weight': weight,
      'dimension_length': dimensionLength,
      'dimension_width': dimensionWidth,
      'dimension_height': dimensionHeight,
      'is_service': isService ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'is_featured': isFeatured ? 1 : 0,
      'allow_fractions': allowFractions ? 1 : 0,
      'image_url': imageUrl,
      'tags': tags,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
    };
  }

  // Convert Product to Map (alias for toJson to fix the error)
  Map<String, dynamic> toMap() {
    return toJson();
  }
}