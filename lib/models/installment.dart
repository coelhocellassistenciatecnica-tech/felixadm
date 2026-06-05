enum InstallmentStatus { pending, paid, overdue }

extension InstallmentStatusExt on InstallmentStatus {
  String get label {
    switch (this) {
      case InstallmentStatus.pending: return 'Pendente';
      case InstallmentStatus.paid: return 'Pago';
      case InstallmentStatus.overdue: return 'Atrasado';
    }
  }
  static InstallmentStatus fromValue(String v) =>
      InstallmentStatus.values.firstWhere((e) => e.name == v, orElse: () => InstallmentStatus.pending);
}

class Installment {
  final int? id;
  final int saleId;
  final int clientId;
  final String clientName;
  final int installmentNumber;
  final int totalInstallments;
  final double amount;
  final double amountPaid;
  final DateTime dueDate;
  final DateTime? paidAt;
  final InstallmentStatus status;

  Installment({
    this.id,
    required this.saleId,
    required this.clientId,
    required this.clientName,
    required this.installmentNumber,
    required this.totalInstallments,
    required this.amount,
    this.amountPaid = 0,
    required this.dueDate,
    this.paidAt,
    this.status = InstallmentStatus.pending,
  });

  bool get isOverdue =>
      status == InstallmentStatus.pending && dueDate.isBefore(DateTime.now());

  double get remaining => amount - amountPaid;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'client_id': clientId,
      'client_name': clientName,
      'installment_number': installmentNumber,
      'total_installments': totalInstallments,
      'amount': amount,
      'amount_paid': amountPaid,
      'due_date': dueDate.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'status': status.name,
    };
  }

  factory Installment.fromMap(Map<String, dynamic> map) {
    final inst = Installment(
      id: map['id'],
      saleId: map['sale_id'],
      clientId: map['client_id'],
      clientName: map['client_name'],
      installmentNumber: map['installment_number'],
      totalInstallments: map['total_installments'],
      amount: (map['amount'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date']),
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at']) : null,
      status: InstallmentStatusExt.fromValue(map['status']),
    );
    return inst;
  }

  Installment copyWith({
    InstallmentStatus? status,
    double? amountPaid,
    DateTime? paidAt,
  }) {
    return Installment(
      id: id,
      saleId: saleId,
      clientId: clientId,
      clientName: clientName,
      installmentNumber: installmentNumber,
      totalInstallments: totalInstallments,
      amount: amount,
      amountPaid: amountPaid ?? this.amountPaid,
      dueDate: dueDate,
      paidAt: paidAt ?? this.paidAt,
      status: status ?? this.status,
    );
  }
}
