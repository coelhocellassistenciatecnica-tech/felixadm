import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class BackupService {
  static const _backupFolder = 'JenniferFelix_Backups';
  static const _maxBackups = 10;
  static const _encryptionKey = 'JenniferFelixApp2024SecureKey!!!';
  static const _kLastBackup = 'last_backup_date';
  static const _kAutoBackupEnabled = 'auto_backup_enabled';

  Future<Directory> _getBackupDir() async {
    Directory baseDir;
    if (Platform.isIOS) {
      baseDir = await getApplicationDocumentsDirectory();
    } else {
      final extDirs = await getExternalStorageDirectories();
      baseDir = extDirs?.first ?? await getApplicationDocumentsDirectory();
    }
    final backupDir = Directory('${baseDir.path}/$_backupFolder');
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    return backupDir;
  }

  String _encrypt(String data) {
    final key = enc.Key.fromUtf8(_encryptionKey.padRight(32).substring(0, 32));
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    final encrypted = encrypter.encrypt(data, iv: iv);
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  String _decrypt(String data) {
    final parts = data.split(':');
    final iv = enc.IV(base64Decode(parts[0]));
    final key = enc.Key.fromUtf8(_encryptionKey.padRight(32).substring(0, 32));
    final encrypter = enc.Encrypter(enc.AES(key));
    return encrypter.decrypt64(parts[1], iv: iv);
  }

  Future<String> createBackup() async {
    final dbHelper = DatabaseHelper();
    final data = await dbHelper.exportAll();
    final jsonStr = jsonEncode({
      'version': '1.0',
      'created_at': DateTime.now().toIso8601String(),
      'data': data,
    });

    final encrypted = _encrypt(jsonStr);
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .substring(0, 19);
    final fileName = 'backup_$timestamp.jfb';

    final backupDir = await _getBackupDir();
    final file = File('${backupDir.path}/$fileName');
    await file.writeAsString(encrypted);

    await _cleanOldBackups(backupDir);
    await _saveLastBackupDate();

    return file.path;
  }

  Future<void> restoreBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('Arquivo de backup não encontrado');

    final encrypted = await file.readAsString();
    final jsonStr = _decrypt(encrypted);
    final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

    final dbHelper = DatabaseHelper();
    await dbHelper.importAll(parsed['data'] as Map<String, dynamic>);
  }

  Future<List<BackupInfo>> listBackups() async {
    final backupDir = await _getBackupDir();
    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jfb'))
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files.map((f) {
      final stat = f.statSync();
      return BackupInfo(
        path: f.path,
        name: f.path.split('/').last,
        size: stat.size,
        createdAt: stat.modified,
      );
    }).toList();
  }

  Future<void> _cleanOldBackups(Directory dir) async {
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jfb'))
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    if (files.length > _maxBackups) {
      for (int i = _maxBackups; i < files.length; i++) {
        await files[i].delete();
      }
    }
  }

  Future<void> _saveLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastBackup, DateTime.now().toIso8601String());
  }

  Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kLastBackup);
    return str != null ? DateTime.parse(str) : null;
  }

  Future<bool> shouldAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kAutoBackupEnabled) ?? true;
    if (!enabled) return false;
    final lastStr = prefs.getString(_kLastBackup);
    if (lastStr == null) return true;
    final last = DateTime.parse(lastStr);
    return DateTime.now().difference(last).inDays >= 7;
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoBackupEnabled, enabled);
  }

  Future<bool> get autoBackupEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutoBackupEnabled) ?? true;
  }
}

class BackupInfo {
  final String path;
  final String name;
  final int size;
  final DateTime createdAt;
  BackupInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.createdAt,
  });
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
