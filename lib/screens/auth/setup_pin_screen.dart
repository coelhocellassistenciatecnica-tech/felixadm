import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});
  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final _pin1 = TextEditingController();
  final _pin2 = TextEditingController();
  String _error = '';

  Future<void> _save() async {
    if (_pin1.text.length < 4) { setState(() => _error = 'PIN deve ter pelo menos 4 dígitos'); return; }
    if (_pin1.text != _pin2.text) { setState(() => _error = 'Os PINs não coincidem'); return; }
    final auth = context.read<AuthProvider>();
    await auth.setPin(_pin1.text);
    await auth.verifyPin(_pin1.text);
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() { _pin1.dispose(); _pin2.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryDark, AppColors.secondary]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_rounded, size: 40, color: Colors.white)),
                  const SizedBox(height: 20),
                  const Text('Criar PIN de Acesso', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Crie um PIN para proteger seus dados', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: Column(children: [
                      const Text('💄 Bem-vinda ao JenniferFelix!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      const Text('Configure seu PIN de segurança', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _pin1,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(counterText: '', labelText: 'Crie seu PIN'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pin2,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(counterText: '', labelText: 'Confirme o PIN', errorText: _error.isEmpty ? null : _error),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('Entrar no Aplicativo'))),
                      const SizedBox(height: 12),
                      const Text('Guarde este PIN em local seguro', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
