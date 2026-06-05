import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sale.dart';
import '../../models/installment.dart';
import '../../models/payment.dart';
import '../../providers/sale_provider.dart';
import '../../providers/installment_provider.dart';
import '../../database/payment_dao.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class SaleDetailScreen extends StatefulWidget {
  final int saleId;
  const SaleDetailScreen({super.key, required this.saleId});
  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> with SingleTickerProviderStateMixin {
  Sale? _sale;
  List<Installment> _installments = [];
  List<Payment> _payments = [];
  bool _loading = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _sale = await context.read<SaleProvider>().getSaleById(widget.saleId);
      _installments = await context.read<InstallmentProvider>().getBySale(widget.saleId);
      _payments = await PaymentDao().findBySale(widget.saleId);
    } catch (e) {
      debugPrint("Error loading sale details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar detalhes da venda: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    if (_sale == null) return const Scaffold(body: Center(child: Text('Venda não encontrada')));
    return Scaffold(
      appBar: AppBar(title: Text('Venda #${_sale!.id}')),
      body: Column(
        children: [
          _buildHeader(),
          TabBar(
            controller: _tabs,
            tabs: const [Tab(text: 'Produtos'), Tab(text: 'Parcelas'), Tab(text: 'Pagamentos')],
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [_buildItemsTab(), _buildInstallmentsTab(), _buildPaymentsTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: _sale!.status != SaleStatus.paid
          ? FloatingActionButton.extended(
              onPressed: _registerPayment,
              icon: const Icon(Icons.payment_rounded),
              label: const Text('Registrar Pagamento'),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_sale!.clientName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            Text(AppFormatters.date(_sale!.saleDate), style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          _statusChip(_sale!.status),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _statBlock('Total', AppFormatters.currency(_sale!.finalAmount)),
          _statBlock('Pago', AppFormatters.currency(_sale!.amountPaid), color: AppColors.success),
          _statBlock('Restante', AppFormatters.currency(_sale!.remaining), color: _sale!.remaining > 0 ? AppColors.warning : AppColors.success),
        ]),
      ]),
    );
  }

  Widget _statBlock(String label, String value, {Color color = Colors.white}) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ]);
  }

  Widget _statusChip(SaleStatus s) {
    Color c;
    switch (s) {
      case SaleStatus.paid: c = AppColors.success; break;
      case SaleStatus.partiallyPaid: c = AppColors.warning; break;
      default: c = Colors.white54;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: c.withOpacity(0.25), borderRadius: BorderRadius.circular(20), border: Border.all(color: c)),
      child: Text(s.label, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _buildItemsTab() {
    if (_sale!.items.isEmpty) return const Center(child: Text('Sem itens'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sale!.items.length,
      itemBuilder: (_, i) {
        final item = _sale!.items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.spa_rounded, color: AppColors.primary, size: 18)),
            title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text('${item.quantity}x ${AppFormatters.currency(item.unitPrice)}', style: const TextStyle(fontSize: 11)),
            trailing: Text(AppFormatters.currency(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        );
      },
    );
  }

  Widget _buildInstallmentsTab() {
    if (_installments.isEmpty) return const Center(child: Text('Sem parcelas'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _installments.length,
      itemBuilder: (_, i) {
        final inst = _installments[i];
        final color = inst.status == InstallmentStatus.paid ? AppColors.success : inst.isOverdue ? AppColors.overdue : AppColors.warning;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Center(child: Text('${inst.installmentNumber}', style: TextStyle(color: color, fontWeight: FontWeight.bold))),
            ),
            title: Text(AppFormatters.currency(inst.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('Venc.: ${AppFormatters.date(inst.dueDate)}', style: const TextStyle(fontSize: 11)),
            trailing: inst.status == InstallmentStatus.paid
                ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
                : ElevatedButton(
                    onPressed: () => _payInstallment(inst),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero),
                    child: const Text('Pagar', style: TextStyle(fontSize: 12)),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) return const Center(child: Text('Nenhum pagamento registrado'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (_, i) {
        final p = _payments[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.payments_rounded, color: AppColors.success),
            title: Text(AppFormatters.currency(p.amount), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
            subtitle: Text('${p.paymentMethod} · ${AppFormatters.date(p.paymentDate)}', style: const TextStyle(fontSize: 11)),
          ),
        );
      },
    );
  }

  Future<void> _payInstallment(Installment inst) async {
    final prov = context.read<SaleProvider>();
    try {
      await prov.registerPayment(
        saleId: inst.saleId, clientId: inst.clientId, clientName: inst.clientName,
        amount: inst.amount, paymentMethod: 'Dinheiro', installmentId: inst.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pagamento de parcela registrado com sucesso! ✓"), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      debugPrint("Error paying installment: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao registrar pagamento de parcela: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      _loadData();
    }
  }

  Future<void> _registerPayment() async {
    final methods = ['Dinheiro', 'PIX', 'Cartão Débito', 'Cartão Crédito'];
    String method = methods.first;
    double amount = _sale!.remaining;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Registrar Pagamento'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              initialValue: amount.toStringAsFixed(2),
              decoration: const InputDecoration(labelText: 'Valor (R\$)', prefixIcon: Icon(Icons.attach_money_rounded)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => amount = double.tryParse(v.replaceAll(',', '.')) ?? 0,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(labelText: 'Método'),
              items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => set(() => method = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<SaleProvider>().registerPayment(
                  saleId: _sale!.id!, clientId: _sale!.clientId, clientName: _sale!.clientName,
                  amount: amount, paymentMethod: method,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Pagamento registrado com sucesso! ✓"), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                debugPrint("Error registering payment: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erro ao registrar pagamento: $e"), backgroundColor: AppColors.error),
                  );
                }
              } finally {
                _loadData();
              }
            }, child: const Text('Confirmar')),
          ],
        ),
      ),
    );
  }
}
