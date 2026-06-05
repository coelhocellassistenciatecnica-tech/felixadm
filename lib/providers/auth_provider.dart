import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  static const _kPin = 'app_pin';
  static const _kBiometric = 'biometric_enabled';
  static const _kLockTimeout = 'lock_timeout_minutes';
  static const _kLastActivity = 'last_activity';

  bool _authenticated = false;
  bool _hasPin = false;
  bool _biometricEnabled = false;
  int _lockTimeoutMinutes = 5;
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool get authenticated => _authenticated;
  bool get hasPin => _hasPin;
  bool get biometricEnabled => _biometricEnabled;
  int get lockTimeoutMinutes => _lockTimeoutMinutes;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _hasPin = prefs.getString(_kPin) != null;
    _biometricEnabled = prefs.getBool(_kBiometric) ?? false;
    _lockTimeoutMinutes = prefs.getInt(_kLockTimeout) ?? 5;
    notifyListeners();
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPin, _hashPin(pin));
    _hasPin = true;
    notifyListeners();
    return true;
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kPin);
    if (stored == null) {
      _authenticated = true;
      notifyListeners();
      return true;
    }
    final match = stored == _hashPin(pin);
    if (match) {
      _authenticated = true;
      await _updateActivity();
      notifyListeners();
    }
    return match;
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      if (!available) return false;
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Use sua biometria para entrar',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (didAuth) {
        _authenticated = true;
        await _updateActivity();
        notifyListeners();
      }
      return didAuth;
    } catch (e) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometric, enabled);
    _biometricEnabled = enabled;
    notifyListeners();
  }

  Future<void> setLockTimeout(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLockTimeout, minutes);
    _lockTimeoutMinutes = minutes;
    notifyListeners();
  }

  Future<void> _updateActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastActivity, DateTime.now().toIso8601String());
  }

  Future<bool> checkSessionExpired() async {
    if (!_authenticated) return true;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_kLastActivity);
    if (last == null) return false;
    final lastActivity = DateTime.parse(last);
    final diff = DateTime.now().difference(lastActivity).inMinutes;
    if (diff >= _lockTimeoutMinutes) {
      _authenticated = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  void updateActivity() async => await _updateActivity();

  void logout() {
    _authenticated = false;
    notifyListeners();
  }

  Future<bool> get canUseBiometric async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      final devices = await _localAuth.getAvailableBiometrics();
      return available && devices.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
