import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../models/sale.dart';
import '../../providers/client_provider.dart';
import '../../providers/sale_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'client_form_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final int clientId;
  const ClientDetailScreen({super.key, required this.clientId});
  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> with SingleTickerProviderStateMixin {
  Client? _client;
  List<Sale> _sales = [];
  double _totalPurchased = 0;
  double _totalPending = 0;
  bool _loading = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    _client = await context.read<ClientProvider>().getById(widget.clientId);
    _sales = await context.read<SaleProvider>().sales.isEmpty
        ? await _fetchSales()
        : context.read<SaleProvider>().sales.where((s) => s.clientId == widget.clientId).toList();
    _totalPurchased = _sales.fold<double>(0.0, (sum, s) => sum + s.finalAmount);
    _totalPending = _sales.fold<double>(0.0, (sum, s) => sum + s.remaining);
    setState(() => _loading = false);
  }

  Future<List<Sale>> _fetchSales() async {
    final prov = context.read<SaleProvider>();
    await prov.loadSales(clientId: widget.clientId);
    return prov.sales.where((s) => s.clientId == widget.clientId).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    if (_client == null) return const Scaffold(body: Center(child: Text('Cliente não encontrado')));
    return Scaffold(
      appBar: AppBar(
        title: Text(_client!.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => ClientFormScreen(client: _client)));
            _loadData();
          }),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          TabBar(
            controller: _tabs,
            tabs: const [Tab(text: 'Compras'), Tab(text: 'Informações')],
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [_buildSalesTab(), _buildInfoTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: Text(_client!.name[0].toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_client!.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Text(AppFormatters.phone(_client!.phone), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statChip('Comprado', AppFormatters.currency(_totalPurchased)),
                    const SizedBox(width: 8),
                    _statChip('A Receber', AppFormatters.currency(_totalPending), color: AppColors.warning),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, {Color color = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9)),
          Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    if (_sales.isEmpty) return const Center(child: Text('Nenhuma compra registrada'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sales.length,
      itemBuilder: (_, i) {
        final s = _sales[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _statusColor(s.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.shopping_bag_rounded, color: _statusColor(s.status), size: 20),
            ),
            title: Text(AppFormatters.currency(s.finalAmount), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${AppFormatters.date(s.saleDate)} · ${s.paymentType.label}', style: const TextStyle(fontSize: 11)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _statusColor(s.status).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Text(s.status.label, style: TextStyle(color: _statusColor(s.status), fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                if (s.remaining > 0)
                  Text('Falta: ${AppFormatters.currency(s.remaining)}', style: const TextStyle(fontSize: 10, color: AppColors.warning)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoTile(Icons.phone_rounded, 'Telefone', AppFormatters.phone(_client!.phone)),
        if (_client!.whatsapp != null) _infoTile(Icons.chat_rounded, 'WhatsApp', AppFormatters.phone(_client!.whatsapp!)),
        if (_client!.address != null) _infoTile(Icons.home_rounded, 'Endereço', _client!.address!),
        if (_client!.neighborhood != null) _infoTile(Icons.location_on_rounded, 'Bairro', _client!.neighborhood!),
        if (_client!.city != null) _infoTile(Icons.location_city_rounded, 'Cidade', _client!.city!),
        if (_client!.notes != null) _infoTile(Icons.notes_rounded, 'Observações', _client!.notes!),
        _infoTile(Icons.calendar_today_rounded, 'Cadastrado em', AppFormatters.date(_client!.createdAt)),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 20),
        title: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        dense: true,
      ),
    );
  }

  Color _statusColor(SaleStatus s) {
    switch (s) {
      case SaleStatus.paid: return AppColors.success;
      case SaleStatus.partiallyPaid: return AppColors.warning;
      case SaleStatus.pending: return AppColors.textSecondary;
    }
  }
}
