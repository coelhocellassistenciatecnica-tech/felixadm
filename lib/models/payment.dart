class Payment {
  final int? id;
  final int saleId;
  final int clientId;
  final String clientName;
  final int? installmentId;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;

  Payment({
    this.id,
    required this.saleId,
    required this.clientId,
    required this.clientName,
    this.installmentId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'client_id': clientId,
      'client_name': clientName,
      'installment_id': installmentId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      saleId: map['sale_id'],
      clientId: map['client_id'],
      clientName: map['client_name'],
      installmentId: map['installment_id'],
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: map['payment_method'],
      paymentDate: DateTime.parse(map['payment_date']),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
