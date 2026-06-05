import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../utils/backup_service.dart';
import '../../utils/formatters.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _svc = BackupService();
  List<BackupInfo> _backups = [];
  DateTime? _lastBackup;
  bool _autoBackupEnabled = true;
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    _backups = await _svc.listBackups();
    _lastBackup = await _svc.getLastBackupDate();
    _autoBackupEnabled = await _svc.autoBackupEnabled;
    setState(() => _loading = false);
  }

  Future<void> _createBackup() async {
    setState(() => _creating = true);
    try {
      await _svc.createBackup();
      await _loadData();
      if (mounted) _showSuccess('Backup criado com sucesso!');
    } catch (e) {
      if (mounted) _showError('Erro ao criar backup: $e');
    }
    setState(() => _creating = false);
  }

  Future<void> _restoreBackup(BackupInfo info) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restaurar Backup?'),
        content: Text('Todos os dados atuais serão substituídos pelos dados do backup:\n\n${info.name}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning), child: const Text('Restaurar')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _svc.restoreBackup(info.path);
      if (mounted) _showSuccess('Dados restaurados com sucesso!');
    } catch (e) {
      if (mounted) _showError('Erro ao restaurar: $e');
    }
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, allowedExtensions: ['jfb']);
    if (result == null || result.files.single.path == null) return;
    final info = BackupInfo(path: result.files.single.path!, name: result.files.single.name, size: result.files.single.size ?? 0, createdAt: DateTime.now());
    await _restoreBackup(info);
  }

  Future<void> _shareBackup(BackupInfo info) async {
    await Share.shareXFiles([XFile(info.path)], text: 'Backup JenniferFelix - ${info.name}');
  }

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));
  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup e Restauração')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildActions(),
                  const SizedBox(height: 24),
                  if (_backups.isNotEmpty) ...[
                    const Text('Backups Disponíveis', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const Text('Mantidos os últimos 10 backups', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    const SizedBox(height: 12),
                    ..._backups.map(_buildBackupCard),
                  ] else ...[
                    Center(
                      child: Column(children: [
                        const SizedBox(height: 32),
                        Icon(Icons.backup_outlined, size: 64, color: AppColors.primaryLight.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('Nenhum backup encontrado', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        const Text('Crie seu primeiro backup agora!', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.shield_rounded, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text('Status do Backup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Último backup', style: TextStyle(color: Colors.white60, fontSize: 11)),
            Text(
              _lastBackup != null ? AppFormatters.dateTime(_lastBackup!) : 'Nunca realizado',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Auto backup', style: TextStyle(color: Colors.white60, fontSize: 11)),
            Switch(
              value: _autoBackupEnabled,
              onChanged: (v) async {
                await _svc.setAutoBackupEnabled(v);
                setState(() => _autoBackupEnabled = v);
              },
              activeColor: Colors.white,
              activeTrackColor: Colors.white30,
            ),
          ]),
        ]),
        if (_autoBackupEnabled) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: const Text('Backup automático a cada 7 dias ✓', style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ]),
    );
  }

  Widget _buildActions() {
    return Row(children: [
      Expanded(child: ElevatedButton.icon(
        onPressed: _creating ? null : _createBackup,
        icon: _creating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.backup_rounded),
        label: Text(_creating ? 'Criando...' : 'Fazer Backup Agora'),
      )),
      const SizedBox(width: 12),
      Expanded(child: OutlinedButton.icon(
        onPressed: _importBackup,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Importar Backup'),
      )),
    ]);
  }

  Widget _buildBackupCard(BackupInfo info) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(info.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis),
            Text('${AppFormatters.dateTime(info.createdAt)} · ${info.formattedSize}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textHint),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'restore', child: Row(children: [Icon(Icons.restore_rounded, size: 18), SizedBox(width: 8), Text('Restaurar')])),
              const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_rounded, size: 18), SizedBox(width: 8), Text('Compartilhar')])),
            ],
            onSelected: (v) {
              if (v == 'restore') _restoreBackup(info);
              if (v == 'share') _shareBackup(info);
            },
          ),
        ]),
      ),
    );
  }
}
