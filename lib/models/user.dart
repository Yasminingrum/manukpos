// models/user.dart
import 'dart:convert';

class User {
  final int? id;
  final String username;
  final String? password; // For storing password during user creation/update
  final String name;
  final String? email;
  final String? phone;
  final String role;
  final int? branchId;
  final int isActive;
  final String? lastLogin;
  final int? loginCount;
  final String? createdAt;
  final String? updatedAt;
  
  // Adding this for auth_service.dart compatibility
  String get passwordHash => password ?? '';

  User({
    this.id,
    required this.username,
    this.password,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    this.branchId,
    this.isActive = 1,
    this.lastLogin,
    this.loginCount,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'branch_id': branchId,
      'is_active': isActive,
      'last_login': lastLogin,
      'login_count': loginCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      role: map['role'],
      branchId: map['branch_id'],
      isActive: map['is_active'],
      lastLogin: map['last_login'],
      loginCount: map['login_count'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
  
  // JSON support for auth_service.dart
  String toJson() => json.encode(toMap());
  
  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  User copyWith({
    int? id,
    String? username,
    String? password,
    String? passwordHash, // Added for auth_service.dart compatibility
    String? name,
    String? email,
    String? phone,
    String? role,
    int? branchId,
    int? isActive,
    String? lastLogin,
    int? loginCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: passwordHash ?? password ?? this.password, // Handle passwordHash
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      loginCount: loginCount ?? this.loginCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}