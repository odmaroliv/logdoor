// lib/core/api/pocketbase_client.dart
import 'package:logdoor/core/utils/exceptions.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';
import '../utils/secure_storage.dart';
import 'dart:convert';

class PocketBaseClient {
  static final PocketBaseClient _instance = PocketBaseClient._internal();
  factory PocketBaseClient() => _instance;

  late PocketBase pb;
  final String baseUrl =
      'https://odkm.pockethost.io'; // Cambiar a la URL correcta en producción
  final SecureStorage _secureStorage = SecureStorage();

  PocketBaseClient._internal() {
    pb = PocketBase(baseUrl);
    _initAuthStore();
  }

  Future<void> _initAuthStore() async {
    final authData = await _secureStorage.read(key: 'pb_auth');
    final authToken = await _secureStorage.read(key: 'pb_auth_token');

    if (authData != null && authToken != null) {
      // Deserializa el String authData a un Map<String, dynamic>
      final authDataMap = jsonDecode(authData) as Map<String, dynamic>;

      // Usa el método fromJson para crear un RecordModel a partir del Map
      final recordModel = RecordModel.fromJson(authDataMap);

      // Usa el método correcto para restaurar la sesión
      pb.authStore.save(authToken, recordModel);
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
      // Verificar si es un error MFA
      if (e is ClientException &&
          e.response != null &&
          e.response['mfaId'] != null) {
        // Guardar el ID MFA para uso posterior
        final mfaId = e.response['mfaId'];

        // Puedes guardar el mfaId para usarlo en el paso de verificación MFA
        await _secureStorage.write(key: 'mfa_id', value: mfaId);
        print('mfaId stored: $mfaId'); // Verifica si se guarda correctamente
        // Lanzar una excepción específica para MFA que tu app pueda manejar
        throw MfaRequiredException(mfaId, email);
      }

      Logger.error('Error en inicio de sesión', error: e);
      rethrow;
    }
  }

  Future<bool> verifyMFA(String code) async {
    try {
      // Obtener el ID MFA guardado previamente
      final mfaId = await _secureStorage.read(key: 'mfa_id');
      if (mfaId == null) {
        throw Exception('No hay sesión MFA activa');
      }

      // Enviar el código al endpoint correcto con el ID MFA
      final result = await pb.send('/api/collections/users/auth-verify',
          method: 'POST', body: {"mfaId": mfaId, "code": code});

      // Si tenemos éxito, la API debería devolver un token y actualizar el AuthStore
      return pb.authStore.isValid;
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
    String? filter,
    String? expand,
  }) async {
    try {
      final result = await pb.collection(collection).getList(
            page: page,
            perPage: perPage,
            sort: '$sortField $sortOrder',
            filter: filter ?? '', // Evitar filtro vacío
            expand: expand ?? '', // Evitar expand vacío
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
