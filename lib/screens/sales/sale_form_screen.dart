import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../models/sale_item.dart';
import '../../providers/client_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class SaleFormScreen extends StatefulWidget {
  const SaleFormScreen({super.key});
  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  Client? _selectedClient;
  final List<_CartItem> _cart = [];
  PaymentType _paymentType = PaymentType.cash;
  int _installments = 1;
  double _discount = 0;
  final _discountCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  DateTime _saleDate = DateTime.now();
  bool _saving = false;

  double get _subtotal => _cart.fold(0, (sum, i) => sum + i.total);
  double get _total => (_subtotal - _discount).clamp(0, double.infinity);

  @override
  void dispose() { _discountCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  Future<void> _selectClient() async {
    final clients = context.read<ClientProvider>().clients;
    if (clients.isEmpty) await context.read<ClientProvider>().loadClients();
    if (!mounted) return;
    final result = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ClientPickerSheet(clients: context.read<ClientProvider>().clients),
    );
    if (result != null) setState(() => _selectedClient = result);
  }

  Future<void> _addProduct() async {
    final products = context.read<ProductProvider>().products;
    if (products.isEmpty) await context.read<ProductProvider>().loadProducts();
    if (!mounted) return;
    final result = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProductPickerSheet(products: context.read<ProductProvider>().products),
    );
    if (result != null) {
      final existing = _cart.where((i) => i.product.id == result.id);
      if (existing.isNotEmpty) {
        setState(() => existing.first.qty++);
      } else {
        setState(() => _cart.add(_CartItem(product: result)));
      }
    }
  }

  Future<void> _save() async {
    if (_selectedClient == null) { _showError('Selecione uma cliente'); return; }
    if (_cart.isEmpty) { _showError('Adicione pelo menos um produto'); return; }
    setState(() => _saving = true);
    final prov = context.read<SaleProvider>();
    final sale = Sale(
      clientId: _selectedClient!.id!,
      clientName: _selectedClient!.name,
      totalAmount: _subtotal,
      discount: _discount,
      finalAmount: _total,
      paymentType: _paymentType,
      installmentsCount: _installments,
      saleDate: _saleDate,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );
    final items = _cart.map((i) => SaleItem(
      saleId: 0,
      productId: i.product.id!,
      productName: i.product.name,
      productBrand: i.product.brand,
      unitPrice: i.product.salePrice,
      costPrice: i.product.costPrice,
      quantity: i.qty,
    )).toList();
    await prov.createSale(sale, items);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venda registrada com sucesso! ✓'), backgroundColor: AppColors.success));
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Venda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Cliente', child: GestureDetector(
            onTap: _selectClient,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
              child: Row(children: [
                const Icon(Icons.person_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(_selectedClient?.name ?? 'Selecionar cliente...', style: TextStyle(color: _selectedClient != null ? AppColors.textPrimary : AppColors.textHint))),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              ]),
            ),
          )),
          const SizedBox(height: 16),
          _buildSection('Produtos', child: Column(
            children: [
              ..._cart.map((item) => _buildCartItem(item)),
              TextButton.icon(onPressed: _addProduct, icon: const Icon(Icons.add_rounded), label: const Text('Adicionar Produto')),
            ],
          )),
          const SizedBox(height: 16),
          _buildSection('Pagamento', child: Column(
            children: [
              DropdownButtonFormField<PaymentType>(
                value: _paymentType,
                decoration: const InputDecoration(labelText: 'Forma de Pagamento', prefixIcon: Icon(Icons.payment_rounded)),
                items: PaymentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) => setState(() {
                  _paymentType = v!;
                  if (v != PaymentType.installments) _installments = 1;
                }),
              ),
              if (_paymentType == PaymentType.installments) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _installments,
                  decoration: const InputDecoration(labelText: 'Número de Parcelas', prefixIcon: Icon(Icons.calendar_month_rounded)),
                  items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}x de ${AppFormatters.currency(_total / (i + 1))}'))).toList(),
                  onChanged: (v) => setState(() => _installments = v!),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountCtrl,
                decoration: const InputDecoration(labelText: 'Desconto (R\$)', prefixIcon: Icon(Icons.discount_rounded)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => setState(() => _discount = double.tryParse(v.replaceAll(',', '.')) ?? 0),
              ),
            ],
          )),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'Observações', prefixIcon: Icon(Icons.notes_rounded)),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _summaryRow('Subtotal', AppFormatters.currency(_subtotal)),
                if (_discount > 0) _summaryRow('Desconto', '- ${AppFormatters.currency(_discount)}', color: AppColors.success),
                const Divider(height: 16),
                _summaryRow('Total', AppFormatters.currency(_total), bold: true, color: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Registrar Venda'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, {required Widget child}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      child,
    ]);
  }

  Widget _buildCartItem(_CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(AppFormatters.currency(item.product.salePrice), style: const TextStyle(color: AppColors.primary, fontSize: 12)),
          ])),
          Row(children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline_rounded), iconSize: 20, onPressed: () => setState(() { if (item.qty > 1) item.qty--; else _cart.remove(item); })),
            Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.w700)),
            IconButton(icon: const Icon(Icons.add_circle_outline_rounded), iconSize: 20, onPressed: () => setState(() => item.qty++)),
          ]),
          Text(AppFormatters.currency(item.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: bold ? 15 : 13)),
      Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: bold ? 15 : 13, color: color)),
    ]);
  }
}

class _CartItem {
  final Product product;
  int qty;
  _CartItem({required this.product, this.qty = 1});
  double get total => product.salePrice * qty;
}

class _ClientPickerSheet extends StatefulWidget {
  final List<Client> clients;
  const _ClientPickerSheet({required this.clients});
  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.clients.where((c) => c.name.toLowerCase().contains(_q.toLowerCase())).toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(children: [
        const SizedBox(height: 12),
        const Text('Selecionar Cliente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(hintText: 'Buscar...', prefixIcon: Icon(Icons.search_rounded)),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        Expanded(child: ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) => ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.primaryLight.withOpacity(0.3), child: Text(filtered[i].name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
            title: Text(filtered[i].name),
            subtitle: Text(AppFormatters.phone(filtered[i].phone), style: const TextStyle(fontSize: 12)),
            onTap: () => Navigator.pop(context, filtered[i]),
          ),
        )),
      ]),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final List<Product> products;
  const _ProductPickerSheet({required this.products});
  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) => p.name.toLowerCase().contains(_q.toLowerCase())).toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(children: [
        const SizedBox(height: 12),
        const Text('Selecionar Produto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(hintText: 'Buscar...', prefixIcon: Icon(Icons.search_rounded)),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        Expanded(child: ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) => ListTile(
            leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.spa_rounded, color: AppColors.primary, size: 18)),
            title: Text(filtered[i].name, style: const TextStyle(fontSize: 13)),
            subtitle: Text('${filtered[i].brand} · ${AppFormatters.currency(filtered[i].salePrice)}', style: const TextStyle(fontSize: 11)),
            trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: filtered[i].isLowStock ? AppColors.warning.withOpacity(0.15) : AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text('${filtered[i].stockQuantity} un', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: filtered[i].isLowStock ? AppColors.warning : AppColors.success))),
            onTap: () => Navigator.pop(context, filtered[i]),
          ),
        )),
      ]),
    );
  }
}
