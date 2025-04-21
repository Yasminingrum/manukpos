// models/branch.dart
import 'dart:convert';

class Branch {
  final int id;
  final String code;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final bool isMainBranch;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  Branch({
    required this.id,
    required this.code,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.isMainBranch = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // Copy with method for creating a copy with some properties changed
  Branch copyWith({
    int? id,
    String? code,
    String? name,
    String? address,
    String? phone,
    String? email,
    bool? isMainBranch,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return Branch(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isMainBranch: isMainBranch ?? this.isMainBranch,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Create Branch from Map (database or API)
  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      isMainBranch: map['is_main_branch'] == 1, // Convert integer to boolean
      isActive: map['is_active'] == 1, // Convert integer to boolean
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  // Create Branch from JSON string
  factory Branch.fromJson(String source) => Branch.fromMap(json.decode(source));

  // Convert Branch to Map for database or API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'is_main_branch': isMainBranch ? 1 : 0, // Convert boolean to integer
      'is_active': isActive ? 1 : 0, // Convert boolean to integer
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Convert Branch to JSON string
  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'Branch(id: $id, code: $code, name: $name)';
  }
}