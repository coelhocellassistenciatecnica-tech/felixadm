import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _canUseBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    _canUseBiometric = await context.read<AuthProvider>().canUseBiometric;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _sectionTitle('Segurança'),
          _buildSecuritySection(auth),
          const SizedBox(height: 20),
          _sectionTitle('Notificações'),
          _buildNotificationsSection(),
          const SizedBox(height: 20),
          _sectionTitle('Sobre'),
          _buildAboutSection(),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text('Sair do Aplicativo', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.spa_rounded, size: 36, color: Colors.white),
        ),
        const SizedBox(width: 16),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('JenniferFelix', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          Text('Controle de Vendas', style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: 4),
          Text('Versão 1.0.0', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary, letterSpacing: 0.5)),
    );
  }

  Widget _buildSecuritySection(AuthProvider auth) {
    return Card(
      child: Column(children: [
        ListTile(
          leading: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
          title: const Text('Alterar PIN', style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(auth.hasPin ? 'PIN configurado' : 'Nenhum PIN configurado'),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          onTap: () => _showChangePinDialog(auth),
        ),
        const Divider(height: 0),
        if (_canUseBiometric) ...[
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
            title: const Text('Biometria', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text('Entrar com impressão digital ou Face ID'),
            value: auth.biometricEnabled,
            activeColor: AppColors.primary,
            onChanged: (v) => auth.setBiometricEnabled(v),
          ),
          const Divider(height: 0),
        ],
        ListTile(
          leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
          title: const Text('Bloqueio Automático', style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text('Bloquear após ${auth.lockTimeoutMinutes} minutos'),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          onTap: () => _showLockTimeoutDialog(auth),
        ),
      ]),
    );
  }

  Widget _buildNotificationsSection() {
    return Card(
      child: Column(children: [
        const SwitchListTile(
          secondary: Icon(Icons.notifications_outlined, color: AppColors.primary),
          title: Text('Parcelas Vencidas', style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text('Notificar sobre parcelas em atraso'),
          value: true,
          activeColor: AppColors.primary,
          onChanged: null,
        ),
        const Divider(height: 0),
        const SwitchListTile(
          secondary: Icon(Icons.upcoming_outlined, color: AppColors.primary),
          title: Text('Vencimentos Próximos', style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text('Avisar 3 dias antes do vencimento'),
          value: true,
          activeColor: AppColors.primary,
          onChanged: null,
        ),
        const Divider(height: 0),
        const SwitchListTile(
          secondary: Icon(Icons.inventory_2_outlined, color: AppColors.primary),
          title: Text('Estoque Baixo', style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text('Alertar quando estoque estiver baixo'),
          value: true,
          activeColor: AppColors.primary,
          onChanged: null,
        ),
      ]),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Column(children: [
        const ListTile(
          leading: Icon(Icons.info_outline_rounded, color: AppColors.primary),
          title: Text('Versão', style: TextStyle(fontWeight: FontWeight.w500)),
          trailing: Text('1.0.0', style: TextStyle(color: AppColors.textSecondary)),
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.storage_rounded, color: AppColors.primary),
          title: const Text('Armazenamento', style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: const Text('Dados armazenados localmente'),
          trailing: const Icon(Icons.lock_rounded, size: 16, color: AppColors.success),
          onTap: () {},
        ),
        const Divider(height: 0),
        const ListTile(
          leading: Icon(Icons.offline_bolt_rounded, color: AppColors.primary),
          title: Text('Modo Offline', style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text('100% funcional sem internet'),
          trailing: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
        ),
      ]),
    );
  }

  Future<void> _showChangePinDialog(AuthProvider auth) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Definir PIN'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(hintText: 'Digite o novo PIN (4-6 dígitos)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            if (ctrl.text.length >= 4) {
              await auth.setPin(ctrl.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN alterado com sucesso! ✓'), backgroundColor: AppColors.success));
              }
            }
          }, child: const Text('Salvar')),
        ],
      ),
    );
  }

  Future<void> _showLockTimeoutDialog(AuthProvider auth) async {
    final options = [1, 2, 5, 10, 15, 30, 60];
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bloqueio Automático'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((m) => RadioListTile<int>(
            title: Text('$m minutos'),
            value: m,
            groupValue: auth.lockTimeoutMinutes,
            activeColor: AppColors.primary,
            onChanged: (v) async {
              await auth.setLockTimeout(v!);
              if (mounted) Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }
}
