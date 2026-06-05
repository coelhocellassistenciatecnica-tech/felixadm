import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProductProvider>().loadProducts());
  }

  @override
  void dispose() { _tabs.dispose(); _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [Tab(text: 'Todos (${prov.products.length})'), Tab(text: 'Estoque Baixo (${prov.lowStock.length})')],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Buscar produto...', prefixIcon: Icon(Icons.search_rounded)),
              onChanged: prov.setSearch,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildList(prov.products, prov),
                _buildList(prov.lowStock, prov, isLowStock: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen())),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildList(List<Product> products, ProductProvider prov, {bool isLowStock = false}) {
    if (prov.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.primaryLight.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(isLowStock ? 'Nenhum produto com estoque baixo 🎉' : 'Nenhum produto cadastrado', style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Slidable(
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(onPressed: (_) => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: p))),
                  backgroundColor: AppColors.info, foregroundColor: Colors.white, icon: Icons.edit_rounded, label: 'Editar',
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12))),
                SlidableAction(onPressed: (_) => _confirmDelete(prov, p.id!),
                  backgroundColor: AppColors.error, foregroundColor: Colors.white, icon: Icons.delete_rounded, label: 'Excluir',
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12))),
              ],
            ),
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
                  child: p.imagePath != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(p.imagePath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.spa_rounded, color: AppColors.primary)))
                      : const Icon(Icons.spa_rounded, color: AppColors.primary),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('${p.brand} · ${p.category}', style: const TextStyle(fontSize: 11)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(AppFormatters.currency(p.salePrice), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.isLowStock ? AppColors.warning.withOpacity(0.15) : AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${p.stockQuantity} un', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: p.isLowStock ? AppColors.warning : AppColors.success)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(ProductProvider prov, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true) await prov.deleteProduct(id);
  }
}
