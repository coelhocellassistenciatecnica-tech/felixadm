import 'package:flutter/foundation.dart';
import '../models/installment.dart';
import '../database/installment_dao.dart';

class InstallmentProvider extends ChangeNotifier {
  final InstallmentDao _dao = InstallmentDao();

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
