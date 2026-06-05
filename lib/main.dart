import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'database/database_helper.dart';

import 'providers/client_provider.dart';
import 'providers/product_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/installment_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/setup_pin_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      await initializeDateFormatting('pt_BR', null);
      await DatabaseHelper().database; // Inicializa o banco de dados local
    } catch (e) {
      debugPrint('Erro ao inicializar data: $e');
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    runApp(const JenniferFelixApp());
  } catch (e) {
    debugPrint('Erro fatal na inicialização: $e');
    // Tenta rodar o app mesmo se algo falhar
    runApp(const JenniferFelixApp());
  }
}

class JenniferFelixApp extends StatelessWidget {
  const JenniferFelixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => InstallmentProvider()),
      ],
      child: MaterialApp(
        title: 'JenniferFelix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/setup-pin': (_) => const SetupPinScreen(),
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0)));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2000), _navigate);
  }

  Future<void> _navigate() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.init().timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (!auth.hasPin) {
        Navigator.pushReplacementNamed(context, '/setup-pin');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint('Erro ao navegar: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/setup-pin');
      }
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark, AppColors.secondary],
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 4)]),
                  child: ClipOval(
                    child: Image.asset('assets/images/logo.webp', fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.spa_rounded, size: 70, color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('JenniferFelix', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text('Controle de Vendas', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), letterSpacing: 2)),
                const SizedBox(height: 48),
                const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
