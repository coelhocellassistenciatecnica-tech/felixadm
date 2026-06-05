import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sale_provider.dart';
import '../../models/sale.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'sale_form_screen.dart';
import 'sale_detail_screen.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});
  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<SaleProvider>().loadSales();
      } catch (e) {
        debugPrint("Error loading sales: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao carregar vendas: $e"), backgroundColor: AppColors.error),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SaleProvider>();
    final all = prov.sales;
    final filtered = _filterStatus == 'all' ? all : all.where((s) => s.status.name == _filterStatus).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Vendas')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: prov.loadSales,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _buildSaleCard(context, filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleFormScreen())),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _filterChip('Todas', 'all'),
          const SizedBox(width: 8),
          _filterChip('Pendentes', 'pending'),
          const SizedBox(width: 8),
          _filterChip('Parcial', 'partiallyPaid'),
          const SizedBox(width: 8),
          _filterChip('Pagas', 'paid'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, Sale sale) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SaleDetailScreen(saleId: sale.id!))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: _statusColor(sale.status).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.shopping_bag_rounded, color: _statusColor(sale.status), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sale.clientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('${AppFormatters.date(sale.saleDate)} · ${sale.paymentType.label}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(AppFormatters.currency(sale.finalAmount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    _statusBadge(sale.status),
                    if (sale.remaining > 0) ...[
                      const SizedBox(height: 2),
                      Text('Falta ${AppFormatters.currency(sale.remaining)}', style: const TextStyle(fontSize: 10, color: AppColors.warning)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(SaleStatus s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: _statusColor(s).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(s.label, style: TextStyle(color: _statusColor(s), fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Color _statusColor(SaleStatus s) {
    switch (s) {
      case SaleStatus.paid: return AppColors.success;
      case SaleStatus.partiallyPaid: return AppColors.warning;
      case SaleStatus.pending: return AppColors.textSecondary;
    }
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.primaryLight.withOpacity(0.5)),
      const SizedBox(height: 16),
      const Text('Nenhuma venda registrada', style: TextStyle(color: AppColors.textSecondary)),
    ]),
  );
}
