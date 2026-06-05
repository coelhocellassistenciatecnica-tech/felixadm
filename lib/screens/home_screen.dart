import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'clients/client_list_screen.dart';
import 'products/product_list_screen.dart';
import 'sales/sale_list_screen.dart';
import 'installments/installment_list_screen.dart';
import 'reports/report_screen.dart';
import 'backup/backup_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ClientListScreen(),
    ProductListScreen(),
    SaleListScreen(),
    InstallmentListScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Clientes'),
    BottomNavigationBarItem(icon: Icon(Icons.spa_rounded), label: 'Produtos'),
    BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'Vendas'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Parcelas'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().updateActivity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: _navItems,
        ),
      ),
      drawer: _buildDrawer(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset('assets/images/logo.webp', height: 80, errorBuilder: (_, __, ___) =>
                  const Icon(Icons.spa_rounded, size: 60, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('JenniferFelix', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const Text('Controle de Vendas', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          _drawerItem(Icons.dashboard_rounded, 'Dashboard', () { Navigator.pop(context); setState(() => _currentIndex = 0); }),
          _drawerItem(Icons.people_rounded, 'Clientes', () { Navigator.pop(context); setState(() => _currentIndex = 1); }),
          _drawerItem(Icons.spa_rounded, 'Produtos', () { Navigator.pop(context); setState(() => _currentIndex = 2); }),
          _drawerItem(Icons.shopping_bag_rounded, 'Vendas', () { Navigator.pop(context); setState(() => _currentIndex = 3); }),
          _drawerItem(Icons.calendar_month_rounded, 'Parcelamentos', () { Navigator.pop(context); setState(() => _currentIndex = 4); }),
          const Divider(),
          _drawerItem(Icons.bar_chart_rounded, 'Relatórios', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())); }),
          _drawerItem(Icons.backup_rounded, 'Backup', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())); }),
          _drawerItem(Icons.settings_rounded, 'Configurações', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
          const Spacer(),
          _drawerItem(Icons.logout_rounded, 'Sair', () {
            Navigator.pop(context);
            context.read<AuthProvider>().logout();
            Navigator.pushReplacementNamed(context, '/login');
          }, color: AppColors.error),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
      title: Text(label, style: TextStyle(color: color ?? AppColors.textPrimary, fontWeight: FontWeight.w500)),
      onTap: onTap,
      dense: true,
    );
  }
}
