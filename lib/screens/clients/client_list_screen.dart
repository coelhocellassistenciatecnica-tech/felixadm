import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../providers/client_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'client_form_screen.dart';
import 'client_detail_screen.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});
  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ClientProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_rounded), onPressed: () => _openForm(context)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => prov.setSearch(v),
            ),
          ),
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : prov.clients.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: prov.loadClients,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: prov.clients.length,
                          itemBuilder: (ctx, i) {
                            final c = prov.clients[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Slidable(
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) => _openForm(context, client: c),
                                      backgroundColor: AppColors.info,
                                      foregroundColor: Colors.white,
                                      icon: Icons.edit_rounded,
                                      label: 'Editar',
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                    ),
                                    SlidableAction(
                                      onPressed: (_) => _confirmDelete(context, prov, c.id!),
                                      backgroundColor: AppColors.error,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete_rounded,
                                      label: 'Excluir',
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                    ),
                                  ],
                                ),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: ListTile(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDetailScreen(clientId: c.id!))),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                                      child: Text(
                                        c.name.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(AppFormatters.phone(c.phone), style: const TextStyle(fontSize: 12)),
                                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _openForm(BuildContext ctx, {client}) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => ClientFormScreen(client: client)));
  }

  Future<void> _confirmDelete(BuildContext ctx, ClientProvider prov, int id) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Excluir cliente?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed == true) await prov.deleteClient(id);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: AppColors.primaryLight.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Nenhum cliente cadastrado', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('Toque no + para adicionar', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
        ],
      ),
    );
  }
}
