// lib/core/api/pocketbase_client.dart
import 'dart:io';
import 'package:logdoor/core/utils/exceptions.dart';
import 'package:pocketbase/pocketbase.dart';
import '../utils/logger.dart';
import '../utils/secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

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
      try {
        // Deserializa el String authData a un Map<String, dynamic>
        final authDataMap = jsonDecode(authData) as Map<String, dynamic>;

        // Usa el método fromJson para crear un RecordModel a partir del Map
        final recordModel = RecordModel.fromJson(authDataMap);

        // Usa el método correcto para restaurar la sesión
        pb.authStore.save(authToken, recordModel);
      } catch (e) {
        Logger.error('Error al restaurar sesión', error: e);
      }
    }

    // Escuchar cambios de autenticación
    pb.authStore.onChange.listen((e) {
      if (pb.authStore.isValid) {
        // Guarda los datos de autenticación en formato de cadena serializada
        _secureStorage.write(
            key: 'pb_auth', value: jsonEncode(pb.authStore.model.toJson()));
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
        Logger.info('mfaId stored: $mfaId');
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
      await pb.send('/api/collections/users/auth-verify',
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
      Logger.info("Obteniendo registros de colección: $collection");

      // Ajusta el parámetro de ordenación: si es descendente, se antepone un guion
      String sortParam =
          sortOrder.toLowerCase() == 'desc' ? '-$sortField' : sortField;

      // Ajusta el filtro
      String correctedFilter = filter ?? '';
      if (correctedFilter.isNotEmpty) {
        correctedFilter = correctedFilter.replaceAll("'", '"');
      }

      Logger.info(
          "Parámetros: page=$page, perPage=$perPage, filter=$correctedFilter");

      final result = await pb.collection(collection).getList(
            page: page,
            perPage: perPage,
            sort: sortParam,
            filter: correctedFilter,
            expand: expand ?? '',
          );

      Logger.info(
          "Éxito! Se obtuvieron ${result.items.length} registros de $collection");
      return result.items;
    } catch (e) {
      Logger.error('Error al obtener registros de $collection', error: e);

      // Si es un problema de autenticación, se intenta refrescar la sesión
      if (e.toString().contains('401') || e.toString().contains('auth')) {
        Logger.warning("Posible problema de autenticación");
        if (!pb.authStore.isValid) {
          Logger.warning("Sesión inválida o expirada");
        }
      }
      rethrow;
    }
  }

  Future<List<RecordModel>> getWarehousesSimple() async {
    try {
      // Simplemente obtener los registros sin filtros
      Logger.info("Intentando obtener warehouses con método simple");

      final result = await pb.collection('warehouses').getList(
            page: 1,
            perPage: 50,
            // Sin filtro, sin argumentos adicionales
          );

      Logger.info(
          "Éxito! Se obtuvieron ${result.items.length} registros de warehouses");
      return result.items;
    } catch (e) {
      Logger.error("Error al obtener warehouses simplificado", error: e);
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

  // MÉTODO MEJORADO: Utiliza la API correcta de PocketBase para crear registros con archivos
  Future<RecordModel> createRecord(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      // Verificar si hay archivos en los datos
      bool hasFiles = _containsFiles(data);

      if (hasFiles) {
        // Procesar los archivos según la API oficial de PocketBase
        return await _createRecordWithFiles(collection, data);
      } else {
        // Usar el método estándar para datos sin archivos
        return await pb.collection(collection).create(body: data);
      }
    } catch (e) {
      Logger.error('Error al crear registro en $collection: $e');
      rethrow;
    }
  }

  // Método para verificar si el mapa contiene archivos
  bool _containsFiles(Map<String, dynamic> data) {
    for (var value in data.values) {
      if (value is File ||
          value is XFile ||
          (value is List &&
              value.isNotEmpty &&
              (value.first is File || value.first is XFile))) {
        return true;
      }
    }
    return false;
  }

  // Método especializado para crear registros con archivos
  Future<RecordModel> _createRecordWithFiles(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      Logger.info('Creando registro con archivos en $collection');

      // Body y archivos separados
      final body = <String, dynamic>{};
      final files = <http.MultipartFile>[];

      for (var entry in data.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is File) {
          files.add(await http.MultipartFile.fromPath(
            key,
            value.path,
            filename: path.basename(value.path),
          ));
        } else if (value is XFile) {
          files.add(await http.MultipartFile.fromPath(
            key,
            value.path,
            filename: path.basename(value.path),
          ));
        } else if (value is List && value.isNotEmpty) {
          if (value.first is File) {
            for (File file in value) {
              files.add(await http.MultipartFile.fromPath(
                key,
                file.path,
                filename: path.basename(file.path),
              ));
            }
          } else if (value.first is XFile) {
            for (XFile xfile in value) {
              files.add(await http.MultipartFile.fromPath(
                key,
                xfile.path,
                filename: path.basename(xfile.path),
              ));
            }
          } else {
            body[key] = value;
          }
        } else {
          body[key] = value;
        }
      }

      // Ahora usa la API correcta con archivos separados
      return await pb.collection(collection).create(
            body: body,
            files: files,
          );
    } catch (e) {
      Logger.error('Error al crear registro con archivos en $collection: $e');
      rethrow;
    }
  }

  Future<RecordModel> updateRecord(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
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

  // Método legacy mantenido para compatibilidad
  Future<RecordModel> createRecordWithFiles(
    String collection,
    Map<String, dynamic> data,
    Map<String, List<dynamic>> filesMap,
  ) async {
    try {
      // Preparar el body
      final body = Map<String, dynamic>.from(data);

      // Preparar los files según la API de PocketBase
      final files = <http.MultipartFile>[];

      // Procesar los archivos del mapa de archivos
      for (var entry in filesMap.entries) {
        final fieldName = entry.key;
        final filesList = entry.value;

        for (var fileData in filesList) {
          if (fileData is File) {
            files.add(
              await http.MultipartFile.fromPath(
                fieldName,
                fileData.path,
                filename: path.basename(fileData.path),
              ),
            );
          } else if (fileData is String) {
            // Asumimos que es una ruta de archivo
            files.add(
              await http.MultipartFile.fromPath(
                fieldName,
                fileData,
                filename: path.basename(fileData),
              ),
            );
          }
        }
      }

      // Crear el registro con archivos
      return await pb.collection(collection).create(
            body: body,
            files: files,
          );
    } catch (e) {
      Logger.error('Error al crear registro con archivos en $collection',
          error: e);
      rethrow;
    }
  }
}
