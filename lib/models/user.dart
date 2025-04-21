// models/user.dart
import 'dart:convert';

class User {
  final int id;
  final String username;
  final String? passwordHash; // Store password hash, not plain password
  final String name;
  final String? email;
  final String? phone;
  final String role;
  final int? branchId;
  final bool isActive;
  final String? lastLogin;
  final int? loginCount;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.id,
    required this.username,
    this.passwordHash,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    this.branchId,
    this.isActive = true,
    this.lastLogin,
    this.loginCount,
    this.createdAt,
    this.updatedAt,
  });

  // Copy with method for creating a copy with some properties changed
  User copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? name,
    String? email,
    String? phone,
    String? role,
    int? branchId,
    bool? isActive,
    String? lastLogin,
    int? loginCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
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

  // Create User from Map (database or API)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      passwordHash: map['password'], // Use 'password' field from DB as passwordHash
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      role: map['role'],
      branchId: map['branch_id'],
      isActive: map['is_active'] == 1, // Convert integer to boolean
      lastLogin: map['last_login'],
      loginCount: map['login_count'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  // Create User from JSON string
  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  // Convert User to Map for database or API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': passwordHash, // Store as 'password' in DB
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'branch_id': branchId,
      'is_active': isActive ? 1 : 0, // Convert boolean to integer
      'last_login': lastLogin,
      'login_count': loginCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Convert User to JSON string
  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'User(id: $id, username: $username, name: $name, email: $email, role: $role, branchId: $branchId)';
  }
}