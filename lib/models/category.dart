// models/category.dart
class Category {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final int? parentId;
  final int level;
  final String? path;
  final String? createdAt;
  final String? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.parentId,
    required this.level,
    this.path,
    this.createdAt,
    this.updatedAt,
  });

  // Create a Category from a database map
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      description: map['description'],
      parentId: map['parent_id'],
      level: map['level'] ?? 1,
      path: map['path'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  // Convert a Category to a database map
  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'code': code,
      'description': description,
      'parent_id': parentId,
      'level': level,
      'path': path,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Only include ID if it's not a new record (ID != 0)
    if (id != 0) {
      map['id'] = id;
    }

    return map;
  }

  // Create a copy of this Category with given fields replaced with new values
  Category copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    int? parentId,
    int? level,
    String? path,
    String? createdAt,
    String? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, code: $code, parentId: $parentId, level: $level}';
  }
}