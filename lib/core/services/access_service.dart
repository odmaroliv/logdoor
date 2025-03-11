// lib/core/services/access_service.dart
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../api/pocketbase_client.dart';
import '../models/access.dart';
import 'offline_sync_service.dart';
import 'geolocation_service.dart';

class AccessService {
  final PocketBaseClient _pbClient = PocketBaseClient();
  final OfflineSyncService _offlineSyncService = OfflineSyncService();
  final GeolocationService _geolocationService = GeolocationService();
  final _uuid = const Uuid();

  // Obtener lista de accesos
  Future<List<Access>> getAccessList({
    String? warehouseId,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      // Construir filtro
      List<String> filters = [];
      if (warehouseId != null) filters.add('warehouse = "$warehouseId"');
      if (userId != null) filters.add('user = "$userId"');
      if (fromDate != null)
        filters.add('timestamp >= "${fromDate.toIso8601String()}"');
      if (toDate != null)
        filters.add('timestamp <= "${toDate.toIso8601String()}"');

      final filterStr = filters.isNotEmpty ? filters.join(' && ') : '';

      // Intentar obtener datos en línea
      final isOffline = await _offlineSyncService.hasOfflineData('accesses');
      if (!isOffline) {
        final records = await _pbClient.getRecords(
          'accesses',
          page: page,
          perPage: perPage,
          filter: filterStr,
          expand: 'user,warehouse',
        );

        return records.map((record) {
          // Extraer nombre de usuario y almacén de la expansión
          String userName = 'Unknown';
          String warehouseName = 'Unknown';

          if (record.expand != null) {
            if (record.expand['user'] != null) {
              userName = record.expand['user'].data['name'];
            }
            if (record.expand['warehouse'] != null) {
              warehouseName = record.expand['warehouse'].data['name'];
            }
          }

          return Access(
            id: record.id,
            userId: record.data['user'],
            userName: userName,
            warehouseId: record.data['warehouse'],
            warehouseName: warehouseName,
            accessType: record.data['accessType'],
            vehicleData: record.data['vehicleData'],
            geolocation: record.data['geolocation'],
            accessCode: record.data['accessCode'],
            timestamp: DateTime.parse(record.data['timestamp']),
            isSync: record.data['isSync'] ?? true,
          );
        }).toList();
      } else {
        // Obtener datos offline
        final offlineData =
            await _offlineSyncService.getOfflineData('accesses');
        return offlineData.map((data) => Access.fromJson(data)).toList();
      }
    } catch (e) {
      print('Error al obtener lista de accesos: $e');
      // Obtener datos offline como fallback
      final offlineData = await _offlineSyncService.getOfflineData('accesses');
      return offlineData.map((data) => Access.fromJson(data)).toList();
    }
  }

  // Crear nuevo registro de acceso
  Future<Access> createAccess({
    required String userId,
    required String userName,
    required String warehouseId,
    required String warehouseName,
    required String accessType,
    Map<String, dynamic>? vehicleData,
  }) async {
    try {
      // Generar código de acceso único
      final accessCode = _generateAccessCode();

      // Obtener ubicación actual
      final location = await _geolocationService.getCurrentLocation();
      final geolocation = {
        'latitude': location.latitude,
        'longitude': location.longitude,
      };

      final accessData = {
        'user': userId,
        'userName': userName,
        'warehouse': warehouseId,
        'warehouseName': warehouseName,
        'accessType': accessType,
        'vehicleData': vehicleData ?? {},
        'geolocation': geolocation,
        'accessCode': accessCode,
        'timestamp': DateTime.now().toIso8601String(),
        'isSync': true,
      };

      // Intenta crear el registro en línea
      try {
        final record = await _pbClient.createRecord('accesses', accessData);

        // Construir acceso a partir de la respuesta
        return Access(
          id: record.id,
          userId: record.data['user'],
          userName: userName,
          warehouseId: record.data['warehouse'],
          warehouseName: warehouseName,
          accessType: record.data['accessType'],
          vehicleData: record.data['vehicleData'],
          geolocation: record.data['geolocation'],
          accessCode: record.data['accessCode'],
          timestamp: DateTime.parse(record.data['timestamp']),
          isSync: true,
        );
      } catch (e) {
        // Si falla la creación en línea, guardar offline
        accessData['isSync'] = false;

        // Generar ID temporal para offline
        final offlineId = 'offline_${_uuid.v4()}';
        accessData['id'] = offlineId;

        await _offlineSyncService.saveOfflineData(
            'accesses', 'create', accessData);

        return Access.fromJson(accessData);
      }
    } catch (e) {
      print('Error al crear acceso: $e');
      rethrow;
    }
  }

  // Verificar código de acceso
  Future<Access?> verifyAccessCode(String accessCode) async {
    try {
      // Intentar verificar en línea
      try {
        final records = await _pbClient.getRecords(
          'accesses',
          filter: 'accessCode = "$accessCode"',
          expand: 'user,warehouse',
        );

        if (records.isNotEmpty) {
          final record = records.first;

          // Extraer nombre de usuario y almacén
          String userName = 'Unknown';
          String warehouseName = 'Unknown';

          if (record.expand != null) {
            if (record.expand['user'] != null) {
              userName = record.expand['user'].data['name'];
            }
            if (record.expand['warehouse'] != null) {
              warehouseName = record.expand['warehouse'].data['name'];
            }
          }

          return Access(
            id: record.id,
            userId: record.data['user'],
            userName: userName,
            warehouseId: record.data['warehouse'],
            warehouseName: warehouseName,
            accessType: record.data['accessType'],
            vehicleData: record.data['vehicleData'],
            geolocation: record.data['geolocation'],
            accessCode: record.data['accessCode'],
            timestamp: DateTime.parse(record.data['timestamp']),
            isSync: record.data['isSync'] ?? true,
          );
        }
      } catch (e) {
        // Verificación offline
        final offlineData =
            await _offlineSyncService.getOfflineData('accesses');
        final matchingAccess = offlineData.firstWhere(
          (data) => data['accessCode'] == accessCode,
          orElse: () => <String, dynamic>{},
        );

        if (matchingAccess.isNotEmpty) {
          return Access.fromJson(matchingAccess);
        }
      }

      return null; // No se encontró el código
    } catch (e) {
      print('Error al verificar código de acceso: $e');
      return null;
    }
  }

  // Generar código de acceso único
  String _generateAccessCode() {
    // Generar código de 6 dígitos
    final random = Random();
    final code = List.generate(6, (index) => random.nextInt(10)).join();
    return code;
  }
}
