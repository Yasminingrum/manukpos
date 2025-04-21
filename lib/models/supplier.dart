class Supplier {
  final int id;
  final String? code;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxId;
  final int? paymentTerms;
  final int isActive;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  Supplier({
    required this.id,
    this.code,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.taxId,
    this.paymentTerms,
    this.isActive = 1,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // Convert Supplier object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'tax_id': taxId,
      'payment_terms': paymentTerms,
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Create a Supplier from a Map
  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      contactPerson: map['contact_person'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      taxId: map['tax_id'],
      paymentTerms: map['payment_terms'],
      isActive: map['is_active'] ?? 1,
      notes: map['notes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  // Create a copy of Supplier with modified fields
  Supplier copyWith({
    int? id,
    String? code,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    int? paymentTerms,
    int? isActive,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Supplier(id: $id, name: $name, contactPerson: $contactPerson, phone: $phone)';
  }
}