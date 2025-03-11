// lib/core/services/alert_service.dart
import '../api/pocketbase_client.dart';
import '../models/alert.dart';
import '../utils/logger.dart';
import 'geolocation_service.dart';
import 'offline_sync_service.dart';

class AlertService {
  final PocketBaseClient _pbClient = PocketBaseClient();
  final GeolocationService _geolocationService = GeolocationService();
  final OfflineSyncService _offlineSyncService = OfflineSyncService();

  // Obtener alertas
  Future<List<Alert>> getAlerts({
    String? userId,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      // Construir filtro
      List<String> filters = [];
      if (userId != null) filters.add('user = "$userId"');
      if (status != null) filters.add('status = "$status"');
      if (fromDate != null)
        filters.add('timestamp >= "${fromDate.toIso8601String()}"');
      if (toDate != null)
        filters.add('timestamp <= "${toDate.toIso8601String()}"');

      final filterStr = filters.isNotEmpty ? filters.join(' && ') : '';

      // Intentar obtener datos en línea
      final records = await _pbClient.getRecords(
        'alerts',
        page: page,
        perPage: perPage,
        filter: filterStr,
        expand: 'user,resolvedBy',
      );

      return records.map((record) => Alert.fromRecord(record)).toList();
    } catch (e) {
      Logger.error('Error al obtener alertas', error: e);
      // Intentar obtener datos offline
      final offlineData = await _offlineSyncService.getOfflineData('alerts');
      return offlineData.map((data) => Alert.fromJson(data)).toList();
    }
  }

  // Crear alerta
  Future<Alert> createAlert({
    required String userId,
    required String userName,
    required String alertType,
    String? notes,
  }) async {
    try {
      // Obtener ubicación actual
      final location = await _geolocationService.getCurrentLocation();
      final geolocation = {
        'latitude': location.latitude,
        'longitude': location.longitude,
      };

      final alertData = {
        'user': userId,
        'userName': userName,
        'alertType': alertType,
        'timestamp': DateTime.now().toIso8601String(),
        'geolocation': geolocation,
        'status': 'active',
        'notes': notes,
      };

      // Intentar crear en línea
      try {
        final record = await _pbClient.createRecord('alerts', alertData);
        return Alert.fromRecord(record);
      } catch (e) {
        // Guardar para sincronización offline
        alertData['isSync'] = false;
        await _offlineSyncService.saveOfflineData(
            'alerts', 'create', alertData);
        return Alert.fromJson(alertData);
      }
    } catch (e) {
      Logger.error('Error al crear alerta', error: e);
      rethrow;
    }
  }

  // Resolver alerta
  Future<Alert> resolveAlert({
    required String alertId,
    required String resolvedById,
    required String resolvedByName,
    required String status, // 'resolved' o 'false_alarm'
    String? notes,
  }) async {
    try {
      final updateData = {
        'resolvedBy': resolvedById,
        'resolvedByName': resolvedByName,
        'resolvedAt': DateTime.now().toIso8601String(),
        'status': status,
        'notes': notes,
      };

      // Intentar actualizar en línea
      try {
        final record =
            await _pbClient.updateRecord('alerts', alertId, updateData);
        return Alert.fromRecord(record);
      } catch (e) {
        // Guardar para sincronización offline
        await _offlineSyncService
            .saveOfflineData('alerts', 'update', updateData, id: alertId);

        // Para la experiencia del usuario, devolver un objeto actualizado
        // aunque aún no se haya sincronizado
        return Alert(
          id: alertId,
          userId: updateData['user'] ?? '',
          userName: updateData['userName'] ?? 'Unknown',
          alertType: updateData['alertType'] ?? 'unknown',
          timestamp: DateTime.now(),
          geolocation: updateData['geolocation'] as Map<String, dynamic>? ??
              {'latitude': 0, 'longitude': 0},
          status: status,
          resolvedById: resolvedById,
          resolvedByName: resolvedByName,
          resolvedAt: DateTime.now(),
          notes: notes,
        );
      }
    } catch (e) {
      Logger.error('Error al resolver alerta', error: e);
      rethrow;
    }
  }
}
