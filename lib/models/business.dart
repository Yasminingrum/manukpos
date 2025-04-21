// models/business.dart
import 'dart:convert';

class Business {
  final int? id;
  final String name;
  final String? tagline;
  final String? address;
  final String? city;
  final String? province;
  final String? postalCode;
  final String? phone;
  final String? email;
  final String? website;
  final String? taxId;
  final String? logoUrl;
  final String? receiptHeader;
  final String? receiptFooter;
  final String? currency;
  final String? currencySymbol;
  final bool includeTax;
  final double taxRate;
  final String? createdAt;
  final String? updatedAt;

  Business({
    this.id,
    required this.name,
    this.tagline,
    this.address,
    this.city,
    this.province,
    this.postalCode,
    this.phone,
    this.email,
    this.website,
    this.taxId,
    this.logoUrl,
    this.receiptHeader,
    this.receiptFooter,
    this.currency = 'IDR',
    this.currencySymbol = 'Rp',
    this.includeTax = true,
    this.taxRate = 0.11, // Default PPN Indonesia 11%
    this.createdAt,
    this.updatedAt,
  });

  // Create a copy with modified fields
  Business copyWith({
    int? id,
    String? name,
    String? tagline,
    String? address,
    String? city,
    String? province,
    String? postalCode,
    String? phone,
    String? email,
    String? website,
    String? taxId,
    String? logoUrl,
    String? receiptHeader,
    String? receiptFooter,
    String? currency,
    String? currencySymbol,
    bool? includeTax,
    double? taxRate,
    String? createdAt,
    String? updatedAt,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      address: address ?? this.address,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      taxId: taxId ?? this.taxId,
      logoUrl: logoUrl ?? this.logoUrl,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      includeTax: includeTax ?? this.includeTax,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert Business to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'address': address,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'phone': phone,
      'email': email,
      'website': website,
      'tax_id': taxId,
      'logo_url': logoUrl,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'currency': currency,
      'currency_symbol': currencySymbol,
      'include_tax': includeTax ? 1 : 0,
      'tax_rate': taxRate,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Create Business from Map
  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      id: map['id'],
      name: map['name'],
      tagline: map['tagline'],
      address: map['address'],
      city: map['city'],
      province: map['province'],
      postalCode: map['postal_code'],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      taxId: map['tax_id'],
      logoUrl: map['logo_url'],
      receiptHeader: map['receipt_header'],
      receiptFooter: map['receipt_footer'],
      currency: map['currency'] ?? 'IDR',
      currencySymbol: map['currency_symbol'] ?? 'Rp',
      includeTax: map['include_tax'] == 1,
      taxRate: map['tax_rate'] is int ? 
        (map['tax_rate'] as int).toDouble() : (map['tax_rate'] ?? 0.11),
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  // Convert to JSON string
  String toJson() => json.encode(toMap());

  // Create from JSON string
  factory Business.fromJson(String source) => Business.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Business(id: $id, name: $name, address: $address, taxId: $taxId)';
  }

  // Create a default Business instance
  factory Business.defaultBusiness() {
    return Business(
      name: 'MANUK UMKM',
      tagline: 'Manajemen Keuangan UMKM',
      currency: 'IDR',
      currencySymbol: 'Rp',
      includeTax: true,
      taxRate: 0.11,
      receiptHeader: 'Terima kasih telah berbelanja',
      receiptFooter: 'Barang yang sudah dibeli tidak dapat dikembalikan',
    );
  }
}