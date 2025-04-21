class Payment {
  final int? id;
  final int transactionId;
  final String paymentMethod;
  final double amount;
  final String? referenceNumber;
  final String? paymentDate;
  final String status;
  final String? cardLast4;
  final String? cardType;
  final String? eWalletProvider;
  final String? chequeNumber;
  final String? chequeDate;
  final String? accountName;
  final String? notes;
  final int? userId;
  final String? createdAt;
  final String? updatedAt;
  final String syncStatus;

  Payment({
    this.id,
    required this.transactionId,
    required this.paymentMethod,
    required this.amount,
    this.referenceNumber,
    this.paymentDate,
    this.status = 'completed',
    this.cardLast4,
    this.cardType,
    this.eWalletProvider,
    this.chequeNumber,
    this.chequeDate,
    this.accountName,
    this.notes,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 'pending',
  });

  // Create a Payment from a Map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      transactionId: map['transaction_id'],
      paymentMethod: map['payment_method'],
      amount: map['amount'],
      referenceNumber: map['reference_number'],
      paymentDate: map['payment_date'],
      status: map['status'] ?? 'completed',
      cardLast4: map['card_last4'],
      cardType: map['card_type'],
      eWalletProvider: map['e_wallet_provider'],
      chequeNumber: map['cheque_number'],
      chequeDate: map['cheque_date'],
      accountName: map['account_name'],
      notes: map['notes'],
      userId: map['user_id'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'] ?? 'pending',
    );
  }

  // Convert a Payment to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'payment_method': paymentMethod,
      'amount': amount,
      'reference_number': referenceNumber,
      'payment_date': paymentDate,
      'status': status,
      'card_last4': cardLast4,
      'card_type': cardType,
      'e_wallet_provider': eWalletProvider,
      'cheque_number': chequeNumber,
      'cheque_date': chequeDate,
      'account_name': accountName,
      'notes': notes,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
    };
  }

  // Create a copy of Payment with some updated fields
  Payment copyWith({
    int? id,
    int? transactionId,
    String? paymentMethod,
    double? amount,
    String? referenceNumber,
    String? paymentDate,
    String? status,
    String? cardLast4,
    String? cardType,
    String? eWalletProvider,
    String? chequeNumber,
    String? chequeDate,
    String? accountName,
    String? notes,
    int? userId,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) {
    return Payment(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      status: status ?? this.status,
      cardLast4: cardLast4 ?? this.cardLast4,
      cardType: cardType ?? this.cardType,
      eWalletProvider: eWalletProvider ?? this.eWalletProvider,
      chequeNumber: chequeNumber ?? this.chequeNumber,
      chequeDate: chequeDate ?? this.chequeDate,
      accountName: accountName ?? this.accountName,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Payment method types
  static const String METHOD_CASH = 'cash';
  static const String METHOD_CREDIT_CARD = 'credit_card';
  static const String METHOD_DEBIT_CARD = 'debit_card';
  static const String METHOD_E_WALLET = 'e_wallet';
  static const String METHOD_BANK_TRANSFER = 'bank_transfer';
  static const String METHOD_CHEQUE = 'cheque';
  static const String METHOD_LOYALTY_POINTS = 'loyalty_points';
  static const String METHOD_CREDIT = 'credit';
  
  // Payment status types
  static const String STATUS_COMPLETED = 'completed';
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_FAILED = 'failed';
  static const String STATUS_REFUNDED = 'refunded';
  static const String STATUS_PARTIAL = 'partial';

  // Sync status types
  static const String SYNC_PENDING = 'pending';
  static const String SYNC_SYNCED = 'synced';
  static const String SYNC_FAILED = 'failed';

  @override
  String toString() {
    return 'Payment{id: $id, transactionId: $transactionId, paymentMethod: $paymentMethod, amount: $amount, status: $status}';
  }
}