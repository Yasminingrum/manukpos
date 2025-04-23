// models/business.dart
class Business {
  final int? id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? taxId;
  final String? logoPath;
  final String? footerText;
  final bool showTaxInfo;
  final bool showSocialMedia;
  final String? socialMediaHandles;
  final String currencySymbol;
  final String? createdAt;
  final String? updatedAt;

  Business({
    this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.taxId,
    this.logoPath,
    this.footerText,
    this.showTaxInfo = true,
    this.showSocialMedia = false,
    this.socialMediaHandles,
    this.currencySymbol = 'Rp',
    this.createdAt,
    this.updatedAt,
  });

  // Create a Business from a map
  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      taxId: map['tax_id'],
      logoPath: map['logo_path'],
      footerText: map['footer_text'],
      showTaxInfo: map['show_tax_info'] == 1,
      showSocialMedia: map['show_social_media'] == 1,
      socialMediaHandles: map['social_media_handles'],
      currencySymbol: map['currency_symbol'] ?? 'Rp',
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  // Convert a Business into a map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'tax_id': taxId,
      'logo_path': logoPath,
      'footer_text': footerText,
      'show_tax_info': showTaxInfo ? 1 : 0,
      'show_social_media': showSocialMedia ? 1 : 0,
      'social_media_handles': socialMediaHandles,
      'currency_symbol': currencySymbol,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  // Create a copy of Business with new values
  Business copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? taxId,
    String? logoPath,
    String? footerText,
    bool? showTaxInfo,
    bool? showSocialMedia,
    String? socialMediaHandles,
    String? currencySymbol,
    String? createdAt,
    String? updatedAt,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      taxId: taxId ?? this.taxId,
      logoPath: logoPath ?? this.logoPath,
      footerText: footerText ?? this.footerText,
      showTaxInfo: showTaxInfo ?? this.showTaxInfo,
      showSocialMedia: showSocialMedia ?? this.showSocialMedia,
      socialMediaHandles: socialMediaHandles ?? this.socialMediaHandles,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}