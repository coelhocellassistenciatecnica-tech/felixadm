import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/installment_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/summary_card.dart';
import '../../utils/backup_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _summary = {};
  double _profit = 0;
  int _clientCount = 0;
  int _stockTotal = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkAutoBackup();
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();
      final saleProv = context.read<SaleProvider>();
      final summary = await saleProv.getMonthlySummary(now.year, now.month);
      final profit = await saleProv.getEstimatedProfit(now.year, now.month);
      final clientCount = await context.read<ClientProvider>().count();
      final stockTotal = await context.read<ProductProvider>().totalStock();
      await context.read<InstallmentProvider>().load();
      setState(() {
        _summary = summary;
        _profit = profit;
        _clientCount = clientCount;
        _stockTotal = stockTotal;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar dados do dashboard: $e"), backgroundColor: AppColors.error),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _checkAutoBackup() async {
    final svc = BackupService();
    if (await svc.shouldAutoBackup()) {
      try {
        await svc.createBackup();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Backup automático realizado! ✓"), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        debugPrint("Error during auto backup: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao realizar backup automático: $e"), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inst = context.watch<InstallmentProvider>();
    final products = context.watch<ProductProvider>();
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 140,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.spa_rounded, color: Colors.white, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('JenniferFelix 💄', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                                        Text('Sua gestão de beleza', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                      onPressed: () => _showNotifications(context, inst),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppFormatters.month(now).toUpperCase(),
                                  style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSection('Resumo do Mês', children: [
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                            children: [
                              SummaryCard(
                                title: 'Total Vendas',
                                value: AppFormatters.currency((_summary['total_amount'] as num?)?.toDouble() ?? 0),
                                icon: Icons.shopping_bag_rounded,
                                color: AppColors.primary,
                              ),
                              SummaryCard(
                                title: 'Recebido',
                                value: AppFormatters.currency((_summary['total_received'] as num?)?.toDouble() ?? 0),
                                icon: Icons.check_circle_rounded,
                                color: AppColors.success,
                              ),
                              SummaryCard(
                                title: 'A Receber',
                                value: AppFormatters.currency((_summary['total_pending'] as num?)?.toDouble() ?? 0),
                                icon: Icons.schedule_rounded,
                                color: AppColors.warning,
                              ),
                              SummaryCard(
                                title: 'Lucro Est.',
                                value: AppFormatters.currency(_profit),
                                icon: Icons.trending_up_rounded,
                                color: AppColors.secondary,
                              ),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 8),
                        _buildSection('Visão Geral', children: [
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                            children: [
                              SummaryCard(
                                title: 'Clientes',
                                value: '$_clientCount',
                                icon: Icons.people_rounded,
                                color: AppColors.info,
                                onTap: () => Navigator.pushNamed(context, '/clients'),
                              ),
                              SummaryCard(
                                title: 'Em Estoque',
                                value: '$_stockTotal',
                                icon: Icons.inventory_2_rounded,
                                color: AppColors.accent,
                                onTap: () => Navigator.pushNamed(context, '/products'),
                              ),
                              SummaryCard(
                                title: 'Vendas',
                                value: '${(_summary['total_sales'] as num?)?.toInt() ?? 0}',
                                icon: Icons.receipt_long_rounded,
                                color: AppColors.primaryLight,
                                onTap: () => Navigator.pushNamed(context, '/sales'),
                              ),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 8),
                        if ((inst.summary['overdue_count'] as num? ?? 0) > 0)
                          _buildAlertCard(
                            '${(inst.summary['overdue_count'] as num).toInt()} parcelas atrasadas!',
                            AppFormatters.currency((inst.summary['total_overdue'] as num?)?.toDouble() ?? 0),
                            Icons.warning_rounded,
                            AppColors.overdue,
                            () => Navigator.pushNamed(context, '/installments'),
                          ),
                        if (products.lowStock.isNotEmpty)
                          _buildAlertCard(
                            '${products.lowStock.length} produtos com estoque baixo',
                            'Verificar agora',
                            Icons.inventory_2_rounded,
                            AppColors.warning,
                            () => Navigator.pushNamed(context, '/products'),
                          ),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSection(String title, {required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
        ...children,
      ],
    );
  }

  Widget _buildAlertCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
                  Text(subtitle, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _showNotifications(BuildContext ctx, InstallmentProvider inst) async {
    try {
      await inst.load(); // Ensure installments are loaded before showing notifications
      if (!mounted) return;
      showModalBottomSheet(
        context: ctx,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Notificações", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (inst.overdue.isEmpty)
                const Center(child: Text("Nenhuma notificação no momento 🎉"))
              else
                ...inst.overdue.take(5).map((i) => ListTile(
                  leading: const Icon(Icons.warning_rounded, color: AppColors.overdue),
                  title: Text("Parcela de ${i.clientName}", style: const TextStyle(fontSize: 13)),
                  subtitle: Text("${AppFormatters.currency(i.remaining)} - Venc. ${AppFormatters.date(i.dueDate)}", style: const TextStyle(fontSize: 12)),
                  dense: true,
                )),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error showing notifications: $e");
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text("Erro ao carregar notificações: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
