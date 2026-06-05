import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _pinController = TextEditingController();
  bool _loading = false;
  String _error = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation = Tween<double>(begin: 0, end: 12).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    final auth = context.read<AuthProvider>();
    if (auth.biometricEnabled) {
      final ok = await auth.authenticateWithBiometric();
      if (ok && mounted) _navigate();
    }
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.length < 4) return;
    setState(() { _loading = true; _error = ''; });
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyPin(_pinController.text);
    if (ok && mounted) {
      _navigate();
    } else {
      _pinController.clear();
      _shakeController.forward(from: 0);
      setState(() { _loading = false; _error = 'PIN incorreto. Tente novamente.'; });
    }
  }

  void _navigate() => Navigator.pushReplacementNamed(context, '/home');

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.spa_rounded, size: 52, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'JenniferFelix',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gestão para Revendedoras',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        children: [
                          const Text('Bem-vinda de volta! 💄', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          const Text('Digite seu PIN para continuar', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(height: 24),
                          AnimatedBuilder(
                            animation: _shakeAnimation,
                            builder: (ctx, child) => Transform.translate(
                              offset: Offset(_shakeAnimation.value, 0),
                              child: child,
                            ),
                            child: TextField(
                              controller: _pinController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '● ● ● ●',
                                errorText: _error.isEmpty ? null : _error,
                              ),
                              onChanged: (v) {
                                if (v.length >= 4) _verifyPin();
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _verifyPin,
                              child: _loading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Entrar'),
                            ),
                          ),
                          if (auth.biometricEnabled) ...[
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _tryBiometric,
                              icon: const Icon(Icons.fingerprint, size: 22),
                              label: const Text('Usar Biometria'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
