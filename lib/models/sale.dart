import 'sale_item.dart';

enum PaymentType { cash, installments, pix, debit, credit }
enum SaleStatus { pending, partiallyPaid, paid }

extension PaymentTypeExt on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.cash: return 'Dinheiro';
      case PaymentType.installments: return 'Parcelado';
      case PaymentType.pix: return 'PIX';
      case PaymentType.debit: return 'Cartão Débito';
      case PaymentType.credit: return 'Cartão Crédito';
    }
  }
  String get value => name;
  static PaymentType fromValue(String v) =>
      PaymentType.values.firstWhere((e) => e.name == v, orElse: () => PaymentType.cash);
}

extension SaleStatusExt on SaleStatus {
  String get label {
    switch (this) {
      case SaleStatus.pending: return 'Pendente';
      case SaleStatus.partiallyPaid: return 'Parcialmente Pago';
      case SaleStatus.paid: return 'Pago';
    }
  }
  static SaleStatus fromValue(String v) =>
      SaleStatus.values.firstWhere((e) => e.name == v, orElse: () => SaleStatus.pending);
}

class Sale {
  final int? id;
  final int clientId;
  final String clientName;
  final double totalAmount;
  final double discount;
  final double finalAmount;
  final PaymentType paymentType;
  final int installmentsCount;
  final SaleStatus status;
  final double amountPaid;
  final DateTime saleDate;
  final String? notes;
  final DateTime createdAt;
  List<SaleItem> items;

  Sale({
    this.id,
    required this.clientId,
    required this.clientName,
    required this.totalAmount,
    this.discount = 0,
    required this.finalAmount,
    required this.paymentType,
    this.installmentsCount = 1,
    this.status = SaleStatus.pending,
    this.amountPaid = 0,
    required this.saleDate,
    this.notes,
    DateTime? createdAt,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  double get remaining => finalAmount - amountPaid;
  bool get isOverdue => status != SaleStatus.paid && saleDate.isBefore(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'client_name': clientName,
      'total_amount': totalAmount,
      'discount': discount,
      'final_amount': finalAmount,
      'payment_type': paymentType.value,
      'installments_count': installmentsCount,
      'status': status.name,
      'amount_paid': amountPaid,
      'sale_date': saleDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      clientId: map['client_id'],
      clientName: map['client_name'],
      totalAmount: (map['total_amount'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      finalAmount: (map['final_amount'] as num).toDouble(),
      paymentType: PaymentTypeExt.fromValue(map['payment_type']),
      installmentsCount: map['installments_count'] ?? 1,
      status: SaleStatusExt.fromValue(map['status']),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      saleDate: DateTime.parse(map['sale_date']),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Sale copyWith({
    SaleStatus? status,
    double? amountPaid,
    List<SaleItem>? items,
  }) {
    return Sale(
      id: id,
      clientId: clientId,
      clientName: clientName,
      totalAmount: totalAmount,
      discount: discount,
      finalAmount: finalAmount,
      paymentType: paymentType,
      installmentsCount: installmentsCount,
      status: status ?? this.status,
      amountPaid: amountPaid ?? this.amountPaid,
      saleDate: saleDate,
      notes: notes,
      createdAt: createdAt,
      items: items ?? this.items,
    );
  }
}
