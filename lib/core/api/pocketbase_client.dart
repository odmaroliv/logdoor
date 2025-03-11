// lib/core/api/pocketbase_client.dart
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';
import '../utils/secure_storage.dart';

class PocketBaseClient {
  static final PocketBaseClient _instance = PocketBaseClient._internal();
  factory PocketBaseClient() => _instance;

  late PocketBase pb;
  final String baseUrl =
      'http://YOUR_POCKETBASE_URL:8090'; // Cambiar a la URL correcta en producción
  final SecureStorage _secureStorage = SecureStorage();

  PocketBaseClient._internal() {
    pb = PocketBase(baseUrl);
    _initAuthStore();
  }

  Future<void> _initAuthStore() async {
    final authData = await _secureStorage.read(key: 'pb_auth');
    final authToken = await _secureStorage.read(key: 'pb_auth_token');

    if (authData != null && authToken != null) {
      // Usa el método correcto para restaurar la sesión
      pb.authStore.save(authToken, authData);
    }

    // Escuchar cambios de autenticación
    pb.authStore.onChange.listen((e) {
      if (pb.authStore.isValid) {
        // Guarda los datos de autenticación en formato de cadena serializada
        _secureStorage.write(
            key: 'pb_auth', value: pb.authStore.model.toString());
        _secureStorage.write(key: 'pb_auth_token', value: pb.authStore.token);
      } else {
        _secureStorage.delete(key: 'pb_auth');
        _secureStorage.delete(key: 'pb_auth_token');
      }
    });
  }

  // Métodos de autenticación
  Future<RecordAuth> signIn(String email, String password) async {
    try {
      return await pb.collection('users').authWithPassword(email, password);
    } catch (e) {
      Logger.error('Error en inicio de sesión', error: e);
      rethrow;
    }
  }

  Future<bool> verifyMFA(String userId, String code) async {
    try {
      // Corregido: pasar el código como parte del body
      await pb.collection('users').authRefresh(body: {"code": code});
      return true;
    } catch (e) {
      Logger.error('Error en verificación MFA', error: e);
      return false;
    }
  }

  Future<void> signOut() async {
    pb.authStore.clear();
  }

  // Suscripción en tiempo real
  Future<UnsubscribeFunc> subscribe(
    String collection,
    String recordId,
    Function(RecordSubscriptionEvent) callback,
  ) async {
    try {
      return await pb.collection(collection).subscribe(recordId, callback);
    } catch (e) {
      Logger.error('Error en suscripción', error: e);
      rethrow;
    }
  }

  // Operaciones CRUD con soporte offline
  Future<List<RecordModel>> getRecords(
    String collection, {
    int page = 1,
    int perPage = 50,
    String sortField = 'created',
    String sortOrder = 'desc',
    String filter = '',
    String expand = '',
  }) async {
    try {
      final result = await pb.collection(collection).getList(
            page: page,
            perPage: perPage,
            sort: '$sortField $sortOrder',
            filter: filter,
            expand: expand,
          );

      return result.items;
    } catch (e) {
      Logger.error('Error al obtener registros de $collection', error: e);
      rethrow;
    }
  }

  Future<RecordModel?> getRecord(
    String collection,
    String id, {
    String expand = '',
  }) async {
    try {
      return await pb.collection(collection).getOne(id, expand: expand);
    } catch (e) {
      Logger.error('Error al obtener registro $id de $collection', error: e);
      rethrow;
    }
  }

  Future<RecordModel> createRecord(
      String collection, Map<String, dynamic> data) async {
    try {
      return await pb.collection(collection).create(body: data);
    } catch (e) {
      Logger.error('Error al crear registro en $collection', error: e);
      rethrow;
    }
  }

  Future<RecordModel> updateRecord(
      String collection, String id, Map<String, dynamic> data) async {
    try {
      return await pb.collection(collection).update(id, body: data);
    } catch (e) {
      Logger.error('Error al actualizar registro $id en $collection', error: e);
      rethrow;
    }
  }

  Future<void> deleteRecord(String collection, String id) async {
    try {
      await pb.collection(collection).delete(id);
    } catch (e) {
      Logger.error('Error al eliminar registro $id en $collection', error: e);
      rethrow;
    }
  }

  // Métodos para cargar archivos
  Future<RecordModel> createRecordWithFiles(
    String collection,
    Map<String, dynamic> data,
    Map<String, List<dynamic>> files,
  ) async {
    try {
      final formData = {...data};

      // Agregar archivos al FormData
      for (final entry in files.entries) {
        formData[entry.key] = entry.value;
      }

      return await pb.collection(collection).create(body: formData);
    } catch (e) {
      Logger.error('Error al crear registro con archivos en $collection',
          error: e);
      rethrow;
    }
  }
}
