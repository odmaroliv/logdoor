import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  SecureStorage._internal();

  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      Logger.error('Error al leer de almacenamiento seguro: $key', error: e);
      return null;
    }
  }

  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      Logger.error('Error al escribir en almacenamiento seguro: $key',
          error: e);
      rethrow;
    }
  }

  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      Logger.error('Error al eliminar de almacenamiento seguro: $key',
          error: e);
      rethrow;
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      Logger.error('Error al eliminar todo el almacenamiento seguro', error: e);
      rethrow;
    }
  }

  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      Logger.error('Error al leer todo el almacenamiento seguro', error: e);
      return {};
    }
  }
}
