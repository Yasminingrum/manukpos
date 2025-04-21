// models/customer.dart
import 'dart:convert';

class Customer {
  final int? id;
  final String? code;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? birthdate;
  final String? joinDate;
  final String customerType;
  final double creditLimit;
  final double currentBalance;
  final String? taxId;
  final bool isActive;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  Customer({
    this.id,
    this.code,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.postalCode,
    this.birthdate,
    this.joinDate,
    this.customerType = 'regular',
    this.creditLimit = 0,
    this.currentBalance = 0,
    this.taxId,
    this.isActive = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // Create a copy of this customer with given fields replaced with new values
  Customer copyWith({
    int? id,
    String? code,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? postalCode,
    String? birthdate,
    String? joinDate,
    String? customerType,
    double? creditLimit,
    double? currentBalance,
    String? taxId,
    bool? isActive,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      birthdate: birthdate ?? this.birthdate,
      joinDate: joinDate ?? this.joinDate,
      customerType: customerType ?? this.customerType,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      taxId: taxId ?? this.taxId,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert Customer instance to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'postal_code': postalCode,
      'birthdate': birthdate,
      'join_date': joinDate,
      'customer_type': customerType,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'tax_id': taxId,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Create Customer instance from Map (database or API)
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      city: map['city'],
      postalCode: map['postal_code'],
      birthdate: map['birthdate'],
      joinDate: map['join_date'],
      customerType: map['customer_type'] ?? 'regular',
      creditLimit: map['credit_limit'] is int
          ? (map['credit_limit'] as int).toDouble()
          : (map['credit_limit'] ?? 0.0),
      currentBalance: map['current_balance'] is int
          ? (map['current_balance'] as int).toDouble()
          : (map['current_balance'] ?? 0.0),
      taxId: map['tax_id'],
      isActive: map['is_active'] == 1,
      notes: map['notes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  // Convert Customer instance to JSON string
  String toJson() => json.encode(toMap());

  // Create Customer instance from JSON string
  factory Customer.fromJson(String source) => Customer.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Customer &&
      other.id == id &&
      other.code == code &&
      other.name == name &&
      other.phone == phone &&
      other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      code.hashCode ^
      name.hashCode ^
      phone.hashCode ^
      email.hashCode;
  }
}