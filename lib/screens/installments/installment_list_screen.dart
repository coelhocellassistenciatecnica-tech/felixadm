import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/installment_provider.dart';
import '../../models/installment.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class InstallmentListScreen extends StatefulWidget {
  const InstallmentListScreen({super.key});
  @override
  State<InstallmentListScreen> createState() => _InstallmentListScreenState();
}

class _InstallmentListScreenState extends State<InstallmentListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<InstallmentProvider>().load();
      } catch (e) {
        debugPrint("Error loading installments: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao carregar parcelas: $e"), backgroundColor: AppColors.error),
          );
        }
      }
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<InstallmentProvider>();
    final overdue = prov.pending.where((i) => i.isOverdue).toList();
    final upcoming = prov.pending.where((i) => !i.isOverdue).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcelamentos'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Atrasadas (${overdue.length})'),
            Tab(text: 'Pendentes (${upcoming.length})'),
            const Tab(text: 'Resumo'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildList(overdue, isOverdue: true),
          _buildList(upcoming),
          _buildSummary(prov),
        ],
      ),
    );
  }

  Widget _buildList(List<Installment> items, {bool isOverdue = false}) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isOverdue ? Icons.check_circle_outline_rounded : Icons.schedule_outlined, size: 64, color: isOverdue ? AppColors.success.withOpacity(0.5) : AppColors.warning.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(isOverdue ? 'Nenhuma parcela atrasada! 🎉' : 'Nenhuma parcela pendente', style: const TextStyle(color: AppColors.textSecondary)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await context.read<InstallmentProvider>().load();
        } catch (e) {
          debugPrint("Error refreshing installments: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erro ao atualizar parcelas: $e"), backgroundColor: AppColors.error),
            );
          }
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCard(items[i], isOverdue: isOverdue),
      ),
    );
  }

  Widget _buildCard(Installment inst, {bool isOverdue = false}) {
    final color = isOverdue ? AppColors.overdue : AppColors.warning;
    final daysLabel = isOverdue
        ? '${DateTime.now().difference(inst.dueDate).inDays} dias atrasado'
        : 'Vence em ${inst.dueDate.difference(DateTime.now()).inDays + 1} dias';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(isOverdue ? Icons.warning_rounded : Icons.schedule_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(inst.clientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('Parcela ${inst.installmentNumber}/${inst.totalInstallments}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(daysLabel, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(AppFormatters.currency(inst.remaining), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
            Text(AppFormatters.date(inst.dueDate), style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildSummary(InstallmentProvider prov) {
    final overdueAmount = (prov.summary['total_overdue'] as num?)?.toDouble() ?? 0;
    final pendingAmount = (prov.summary['total_pending'] as num?)?.toDouble() ?? 0;
    final overdueCount = (prov.summary['overdue_count'] as num?)?.toInt() ?? 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCard('Total a Receber', AppFormatters.currency(pendingAmount), Icons.account_balance_wallet_rounded, AppColors.primary),
        const SizedBox(height: 12),
        _summaryCard('Total Atrasado', AppFormatters.currency(overdueAmount), Icons.warning_rounded, AppColors.overdue),
        const SizedBox(height: 12),
        _summaryCard('Parcelas Atrasadas', '$overdueCount parcelas', Icons.error_outline_rounded, AppColors.warning),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        ]),
      ]),
    );
  }
}
