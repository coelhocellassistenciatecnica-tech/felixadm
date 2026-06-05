import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/installment.dart';
import '../database/sale_dao.dart';
import '../database/installment_dao.dart';
import '../database/payment_dao.dart';
import '../models/payment.dart';

class SaleProvider extends ChangeNotifier {
  final SaleDao _saleDao = SaleDao();
  final InstallmentDao _instDao = InstallmentDao();
  final PaymentDao _paymentDao = PaymentDao();

  List<Sale> _sales = [];
  bool _loading = false;

  List<Sale> get sales => _sales;
  bool get loading => _loading;

  Future<void> loadSales({int? clientId, DateTime? from, DateTime? to}) async {
    _loading = true;
    notifyListeners();
    _sales = await _saleDao.findAll(clientId: clientId, from: from, to: to);
    _loading = false;
    notifyListeners();
  }

  Future<Sale?> getSaleById(int id) => _saleDao.findById(id);

  Future<int> createSale(Sale sale, List<SaleItem> items) async {
    final saleId = await _saleDao.insertSale(sale, items);
    if (sale.paymentType == PaymentType.installments && sale.installmentsCount > 1) {
      final installmentAmount = sale.finalAmount / sale.installmentsCount;
      final installments = List.generate(sale.installmentsCount, (i) {
        return Installment(
          saleId: saleId,
          clientId: sale.clientId,
          clientName: sale.clientName,
          installmentNumber: i + 1,
          totalInstallments: sale.installmentsCount,
          amount: installmentAmount,
          dueDate: DateTime(
            sale.saleDate.year,
            sale.saleDate.month + i + 1,
            sale.saleDate.day,
          ),
        );
      });
      await _instDao.insertAll(installments);
    } else if (sale.paymentType == PaymentType.cash || sale.paymentType == PaymentType.pix) {
      await _saleDao.updateStatus(saleId, SaleStatus.paid.name, sale.finalAmount);
      await _paymentDao.insert(Payment(
        saleId: saleId,
        clientId: sale.clientId,
        clientName: sale.clientName,
        amount: sale.finalAmount,
        paymentMethod: sale.paymentType.label,
        paymentDate: sale.saleDate,
      ));
    }
    await loadSales();
    return saleId;
  }

  Future<void> registerPayment({
    required int saleId,
    required int clientId,
    required String clientName,
    required double amount,
    required String paymentMethod,
    int? installmentId,
  }) async {
    final db = _saleDao;
    final sale = await db.findById(saleId);
    if (sale == null) return;

    final newPaid = sale.amountPaid + amount;
    final newStatus = newPaid >= sale.finalAmount
        ? SaleStatus.paid.name
        : SaleStatus.partiallyPaid.name;

    await _saleDao.updateStatus(saleId, newStatus, newPaid);

    if (installmentId != null) {
      await _instDao.markPaid(installmentId, amount, DateTime.now());
    }

    await _paymentDao.insert(Payment(
      saleId: saleId,
      clientId: clientId,
      clientName: clientName,
      installmentId: installmentId,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentDate: DateTime.now(),
    ));

    await loadSales();
    notifyListeners();
  }

  Future<Map<String, dynamic>> getMonthlySummary(int year, int month) =>
      _saleDao.getMonthlySummary(year, month);

  Future<double> getEstimatedProfit(int year, int month) =>
      _saleDao.getEstimatedProfit(year, month);

  Future<List<Map<String, dynamic>>> getTopClients(int limit) =>
      _saleDao.getTopClients(limit);

  Future<List<Map<String, dynamic>>> getTopProducts(int limit) =>
      _saleDao.getTopProducts(limit);
}
