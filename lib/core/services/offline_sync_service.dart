import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../api/pocketbase_client.dart';
import '../utils/logger.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;

  late Box<String> _offlineBox;
  final PocketBaseClient _pbClient = PocketBaseClient();
  bool _isSyncing = false;

  OfflineSyncService._internal();

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _offlineBox = await Hive.openBox<String>('offline_data');

      // Escuchar cambios de conectividad
      Connectivity().onConnectivityChanged.listen((result) {
        if (result != ConnectivityResult.none) {
          syncPendingData();
        }
      });

      Logger.info('Servicio de sincronización offline inicializado');
    } catch (e) {
      Logger.error('Error al inicializar servicio offline', error: e);
      rethrow;
    }
  }

  // Guardar datos para sincronización posterior
  Future<void> saveOfflineData(
    String collection,
    String action,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    try {
      final offlineId = DateTime.now().millisecondsSinceEpoch.toString();
      final offlineData = {
        'id': offlineId,
        'collection': collection,
        'action': action,
        'recordId': id,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _offlineBox.put(offlineId, jsonEncode(offlineData));

      Logger.info('Datos guardados offline: $collection - $action');
    } catch (e) {
      Logger.error('Error al guardar datos offline', error: e);
      rethrow;
    }
  }

  // Sincronizar datos pendientes
  Future<void> syncPendingData() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      Logger.info('Iniciando sincronización de datos offline');

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        Logger.warning('No hay conexión para sincronizar');
        _isSyncing = false;
        return;
      }

      final keys = _offlineBox.keys.toList();
      Logger.info('${keys.length} elementos para sincronizar');

      for (var key in keys) {
        final offlineDataJson = _offlineBox.get(key);
        if (offlineDataJson == null) continue;

        final offlineData = jsonDecode(offlineDataJson) as Map<String, dynamic>;
        final collection = offlineData['collection'] as String;

        try {
          switch (offlineData['action']) {
            case 'create':
              // Manejar específicamente las inspecciones y reportes
              if (collection == 'inspections') {
                await _syncInspection(offlineData['data']);
              } else if (collection == 'reports') {
                await _syncReport(offlineData['data']);
              } else {
                await _pbClient.createRecord(
                  collection,
                  offlineData['data'],
                );
              }
              break;

            case 'update':
              if (offlineData['recordId'] != null) {
                await _pbClient.updateRecord(
                  collection,
                  offlineData['recordId'],
                  offlineData['data'],
                );
              }
              break;

            case 'delete':
              if (offlineData['recordId'] != null) {
                await _pbClient.deleteRecord(
                  collection,
                  offlineData['recordId'],
                );
              }
              break;
          }

          // Si la sincronización es exitosa, eliminar del almacenamiento local
          await _offlineBox.delete(key);
          Logger.info('Item sincronizado y eliminado: $key');
        } catch (e) {
          // Mantener en almacenamiento local si la sincronización falla
          Logger.error('Error al sincronizar item: $key', error: e);
        }
      }

      Logger.info('Sincronización completada');
    } catch (e) {
      Logger.error('Error durante sincronización', error: e);
    } finally {
      _isSyncing = false;
    }
  }

  // Función especial para sincronizar inspecciones con archivos
  Future<void> _syncInspection(Map<String, dynamic> data) async {
    try {
      // Preparar datos para envío - hace una copia del mapa original
      final Map<String, dynamic> formData = Map.from(data);

      // Eliminar el ID temporal offline si existe
      if (formData['id'] != null &&
          formData['id'].toString().startsWith('offline_')) {
        formData.remove('id');
      }

      // Procesar fotos - convertir paths a objetos File
      if (formData.containsKey('photosPaths')) {
        List<String> paths = List<String>.from(formData['photosPaths']);
        List<File> photoFiles = paths.map((path) => File(path)).toList();

        // Reemplazar paths por files
        formData.remove('photosPaths');
        formData['photos'] =
            photoFiles; // PocketBaseClient manejará esto correctamente
      }

      // Procesar firma - convertir path a objeto File
      if (formData.containsKey('signaturePath')) {
        String path = formData['signaturePath'];
        File signatureFile = File(path);

        // Reemplazar path por file
        formData.remove('signaturePath');
        formData['signature'] =
            signatureFile; // PocketBaseClient manejará esto correctamente
      }

      // Enviar a la API usando el cliente actualizado
      Logger.info('Sincronizando inspección: ${formData.keys.join(", ")}');
      await _pbClient.createRecord('inspections', formData);
      Logger.info('Inspección sincronizada con archivos');
    } catch (e) {
      Logger.error('Error sincronizando inspección con archivos: $e', error: e);
      throw e;
    }
  }

  // Función especial para sincronizar reportes con PDF
  Future<void> _syncReport(Map<String, dynamic> data) async {
    try {
      // Preparar datos para envío - hace una copia del mapa original
      final Map<String, dynamic> formData = Map.from(data);

      // Procesar path del PDF
      if (formData.containsKey('pdfReportPath')) {
        String path = formData['pdfReportPath'];
        File pdfFile = File(path);

        // Reemplazar path por file
        formData.remove('pdfReportPath');
        formData['pdfReport'] =
            pdfFile; // PocketBaseClient manejará esto correctamente
      }

      // Enviar a la API
      Logger.info('Sincronizando reporte PDF');
      await _pbClient.createRecord('reports', formData);
      Logger.info('Reporte PDF sincronizado');
    } catch (e) {
      Logger.error('Error sincronizando reporte PDF: $e', error: e);
      throw e;
    }
  }

  // Verificar si hay datos offline para una colección específica
  Future<bool> hasOfflineData(String collection) async {
    try {
      for (var key in _offlineBox.keys) {
        final offlineDataJson = _offlineBox.get(key);
        if (offlineDataJson == null) continue;

        final offlineData = jsonDecode(offlineDataJson) as Map<String, dynamic>;
        if (offlineData['collection'] == collection) {
          return true;
        }
      }
      return false;
    } catch (e) {
      Logger.error('Error al verificar datos offline', error: e);
      return false;
    }
  }

  // Obtener datos offline para una colección específica
  Future<List<Map<String, dynamic>>> getOfflineData(String collection) async {
    try {
      final result = <Map<String, dynamic>>[];

      for (var key in _offlineBox.keys) {
        final offlineDataJson = _offlineBox.get(key);
        if (offlineDataJson == null) continue;

        final offlineData = jsonDecode(offlineDataJson) as Map<String, dynamic>;
        if (offlineData['collection'] == collection) {
          result.add(offlineData['data']);
        }
      }

      return result;
    } catch (e) {
      Logger.error('Error al obtener datos offline', error: e);
      return [];
    }
  }

  // Limpiar todos los datos offline
  Future<void> clearOfflineData() async {
    try {
      await _offlineBox.clear();
      Logger.info('Datos offline eliminados');
    } catch (e) {
      Logger.error('Error al limpiar datos offline', error: e);
      rethrow;
    }
  }
}
