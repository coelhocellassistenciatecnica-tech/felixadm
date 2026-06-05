import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/sale_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic> _summary = {};
  double _profit = 0;
  List<Map<String, dynamic>> _topClients = [];
  List<Map<String, dynamic>> _topProducts = [];
  bool _loading = true;
  DateTime _selectedMonth = DateTime.now();

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
    final prov = context.read<SaleProvider>();
    _summary = await prov.getMonthlySummary(_selectedMonth.year, _selectedMonth.month);
    _profit = await prov.getEstimatedProfit(_selectedMonth.year, _selectedMonth.month);
    _topClients = await prov.getTopClients(5);
    _topProducts = await prov.getTopProducts(5);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Geral'), Tab(text: 'Clientes'), Tab(text: 'Produtos')],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabs,
                    children: [_buildGeneralTab(), _buildClientsTab(), _buildProductsTab()],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.cardBg,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
          onPressed: () { setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)); _loadData(); },
        ),
        GestureDetector(
          child: Text(AppFormatters.month(_selectedMonth).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          onPressed: () { setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)); _loadData(); },
        ),
      ]),
    );
  }

  Widget _buildGeneralTab() {
    final totalSales = (_summary['total_sales'] as num?)?.toInt() ?? 0;
    final totalAmount = (_summary['total_amount'] as num?)?.toDouble() ?? 0;
    final totalReceived = (_summary['total_received'] as num?)?.toDouble() ?? 0;
    final totalPending = (_summary['total_pending'] as num?)?.toDouble() ?? 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
          children: [
            _reportCard('Vendas', '$totalSales', Icons.shopping_bag_rounded, AppColors.primary),
            _reportCard('Faturado', AppFormatters.currency(totalAmount), Icons.attach_money_rounded, AppColors.secondary),
            _reportCard('Recebido', AppFormatters.currency(totalReceived), Icons.check_circle_rounded, AppColors.success),
            _reportCard('Pendente', AppFormatters.currency(totalPending), Icons.schedule_rounded, AppColors.warning),
          ],
        ),
        const SizedBox(height: 16),
        _reportCard('Lucro Estimado', AppFormatters.currency(_profit), Icons.trending_up_rounded, AppColors.primaryDark, fullWidth: true),
        const SizedBox(height: 20),
        if (totalAmount > 0) _buildPaymentChart(totalReceived, totalPending),
      ],
    );
  }

  Widget _buildPaymentChart(double received, double pending) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recebido vs Pendente', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: PieChart(PieChartData(
                sections: [
                  PieChartSectionData(value: received, color: AppColors.success, title: '${((received / (received + pending)) * 100).toStringAsFixed(0)}%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  PieChartSectionData(value: pending, color: AppColors.warning, title: '${((pending / (received + pending)) * 100).toStringAsFixed(0)}%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
                sectionsSpace: 3,
                centerSpaceRadius: 40,
              )),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _legend(AppColors.success, 'Recebido'),
              const SizedBox(width: 24),
              _legend(AppColors.warning, 'Pendente'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }

  Widget _buildClientsTab() {
    if (_topClients.isEmpty) return const Center(child: Text('Sem dados ainda'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Top 5 Clientes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 12),
        ..._topClients.asMap().entries.map((e) {
          final i = e.key; final c = e.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                child: Text('${i + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              title: Text(c['client_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${c['sale_count']} compra(s)', style: const TextStyle(fontSize: 11)),
              trailing: Text(AppFormatters.currency((c['total'] as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProductsTab() {
    if (_topProducts.isEmpty) return const Center(child: Text('Sem dados ainda'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Top 5 Produtos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 12),
        ..._topProducts.asMap().entries.map((e) {
          final i = e.key; final p = e.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.secondaryLight.withOpacity(0.2),
                child: Text('${i + 1}', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
              ),
              title: Text(p['product_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${p['qty']} vendido(s)', style: const TextStyle(fontSize: 11)),
              trailing: Text(AppFormatters.currency((p['revenue'] as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.secondary)),
            ),
          );
        }),
      ],
    );
  }

  Widget _reportCard(String label, String value, IconData icon, Color color, {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          ]),
        ],
      ),
    );
  }
}
