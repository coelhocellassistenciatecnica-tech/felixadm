import 'package:flutter/foundation.dart';
import '../models/installment.dart';
import '../database/installment_dao.dart';
import '../models/installment.dart'; // Certifique-se de que Installment está importado

class InstallmentProvider extends ChangeNotifier {
  final InstallmentDao _dao = InstallmentDao();

  // Adicionar um método para adicionar parcelas, se necessário
  Future<void> addInstallments(List<Installment> installments) async {
    try {
      await _dao.insertAll(installments);
      await load(); // Recarregar as parcelas após adicionar
    } catch (e) {
      debugPrint('Error adding installments to local DB: $e');
    }
  }

  // Adicionar um método para marcar parcela como paga
  Future<void> markInstallmentPaid(int id, double amount, DateTime paidAt) async {
    try {
      await _dao.markPaid(id, amount, paidAt);
      await load(); // Recarregar as parcelas após marcar como paga
    } catch (e) {
      debugPrint('Error marking installment paid in local DB: $e');
    }
  }

  List<Installment> _pending = [];
  List<Installment> _overdue = [];
  Map<String, dynamic> _summary = {};

  List<Installment> get pending => _pending;
  List<Installment> get overdue => _overdue;
  Map<String, dynamic> get summary => _summary;

  Future<void> load({int? clientId}) async {
    await _dao.updateOverdueStatuses();
    _pending = await _dao.findPending(clientId: clientId);
    _overdue = await _dao.findOverdue();
    _summary = await _dao.getSummary();
    notifyListeners();
  }

  Future<List<Installment>> getBySale(int saleId) => _dao.findBySale(saleId);

  Future<List<Installment>> getDueSoon(int days) => _dao.findDueSoon(days);
}
