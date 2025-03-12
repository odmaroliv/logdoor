import '../api/pocketbase_client.dart';
import '../models/warehouse.dart';
import '../utils/logger.dart';
import 'offline_sync_service.dart';

class WarehouseService {
  final PocketBaseClient _pbClient = PocketBaseClient();
  final OfflineSyncService _offlineSyncService = OfflineSyncService();

  // Obtener lista de almacenes
  Future<List<Warehouse>> getWarehouses({
    bool onlyActive = true,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      // Construir filtro
      String filter = onlyActive ? 'isActive = true' : '';

      // Intentar obtener datos en línea
      try {
        final records = await _pbClient.getRecords(
          'warehouses',
          page: page,
          perPage: perPage,
          // filter: filter,
        );

        final warehouses =
            records.map((record) => Warehouse.fromRecord(record)).toList();

        // Guardar datos para uso offline
        for (var warehouse in warehouses) {
          await _offlineSyncService.saveOfflineData(
              'warehouses_cache', 'cache', warehouse.toJson());
        }

        return warehouses;
      } catch (e) {
        // Obtener datos offline
        final offlineData =
            await _offlineSyncService.getOfflineData('warehouses_cache');
        return offlineData.map((data) => Warehouse.fromJson(data)).toList();
      }
    } catch (e) {
      Logger.error('Error al obtener almacenes', error: e);
      rethrow;
    }
  }

  // Obtener almacén por ID
  Future<Warehouse?> getWarehouseById(String warehouseId) async {
    try {
      try {
        final record = await _pbClient.getRecord('warehouses', warehouseId);
        return Warehouse.fromRecord(record);
      } catch (e) {
        // Buscar en caché offline
        final offlineData =
            await _offlineSyncService.getOfflineData('warehouses_cache');
        final matchingWarehouse = offlineData.firstWhere(
          (data) => data['id'] == warehouseId,
          orElse: () => <String, dynamic>{},
        );

        if (matchingWarehouse.isNotEmpty) {
          return Warehouse.fromJson(matchingWarehouse);
        }
      }
      return null;
    } catch (e) {
      Logger.error('Error al obtener almacén por ID', error: e);
      return null;
    }
  }

  // Crear nuevo almacén
  Future<Warehouse> createWarehouse({
    required String name,
    required String location,
    required String address,
    required Map<String, dynamic> coordinates,
    String? description,
  }) async {
    try {
      final warehouseData = {
        'name': name,
        'location': location,
        'description': description,
        'address': address,
        'coordinates': coordinates,
        'isActive': true,
      };

      final record = await _pbClient.createRecord('warehouses', warehouseData);
      return Warehouse.fromRecord(record);
    } catch (e) {
      Logger.error('Error al crear almacén', error: e);
      rethrow;
    }
  }

  // Actualizar almacén
  Future<Warehouse> updateWarehouse({
    required String warehouseId,
    String? name,
    String? location,
    String? address,
    Map<String, dynamic>? coordinates,
    String? description,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (location != null) updateData['location'] = location;
      if (address != null) updateData['address'] = address;
      if (coordinates != null) updateData['coordinates'] = coordinates;
      if (description != null) updateData['description'] = description;
      if (isActive != null) updateData['isActive'] = isActive;

      final record =
          await _pbClient.updateRecord('warehouses', warehouseId, updateData);
      return Warehouse.fromRecord(record);
    } catch (e) {
      Logger.error('Error al actualizar almacén', error: e);
      rethrow;
    }
  }

  // Desactivar almacén
  Future<bool> deactivateWarehouse(String warehouseId) async {
    try {
      await _pbClient
          .updateRecord('warehouses', warehouseId, {'isActive': false});
      return true;
    } catch (e) {
      Logger.error('Error al desactivar almacén', error: e);
      return false;
    }
  }
}
