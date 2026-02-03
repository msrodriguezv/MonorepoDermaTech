import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage();

  /// Guardar datos (Token, Role, etc)
  Future<void> write({required String key, required String value}) async {
    if (kIsWeb) {
      // EN WEB: Usamos SharedPreferences porque no hay HTTPS (Secure Context)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      // EN MÓVIL: Usamos SecureStorage (Keychain/Keystore)
      await _secureStorage.write(key: key, value: value);
    }
  }

  /// Leer datos
  Future<String?> read({required String key}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  /// Borrar un dato específico
  Future<void> delete({required String key}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  /// Borrar TODO (Al hacer Logout)
  Future<void> deleteAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } else {
      await _secureStorage.deleteAll();
    }
  }
}