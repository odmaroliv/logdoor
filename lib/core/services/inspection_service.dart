import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../api/pocketbase_client.dart';
import '../models/inspection.dart';
import 'offline_sync_service.dart';
import 'geolocation_service.dart';
import '../utils/connectivity_utils.dart';
import '../utils/logger.dart';
import 'pdf_service.dart';

class InspectionService {
  final PocketBaseClient _pbClient = PocketBaseClient();
  final OfflineSyncService _offlineSyncService = OfflineSyncService();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  final PdfService _pdfService = PdfService();

  // Get inspections with offline support
  Future<List<Inspection>> getInspections({
    String? accessId,
    String? inspectorId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      // Build filter
      List<String> filters = [];
      if (accessId != null) filters.add('access = "$accessId"');
      if (inspectorId != null) filters.add('inspector = "$inspectorId"');
      if (fromDate != null)
        filters.add('timestamp >= "${fromDate.toIso8601String()}"');
      if (toDate != null)
        filters.add('timestamp <= "${toDate.toIso8601String()}"');
      if (status != null) filters.add('status = "$status"');

      final filterStr = filters.isNotEmpty ? filters.join(' && ') : '';

      // Try online fetch first
      if (await _connectivityUtils.isConnected()) {
        final records = await _pbClient.getRecords(
          'inspections',
          page: page,
          perPage: perPage,
          filter: filterStr,
          expand: 'inspector',
        );

        return records.map((record) => Inspection.fromRecord(record)).toList();
      } else {
        // Offline: Get from local storage
        final offlineData =
            await _offlineSyncService.getOfflineData('inspections');
        return offlineData.map((data) => Inspection.fromJson(data)).toList();
      }
    } catch (e) {
      Logger.error('Error al obtener inspecciones', error: e);
      // Fallback to offline if API fails
      final offlineData =
          await _offlineSyncService.getOfflineData('inspections');
      return offlineData.map((data) => Inspection.fromJson(data)).toList();
    }
  }

  // Submit a new inspection with offline support
  Future<Inspection> submitInspection({
    required String accessId,
    required String inspectorId,
    required String inspectorName,
    required Map<String, dynamic> checklist,
    required List<XFile> photos,
    required String signaturePath,
    String? notes,
  }) async {
    final timestamp = DateTime.now();
    final isOnline = await _connectivityUtils.isConnected();

    try {
      // Prepare inspection data
      final inspectionData = {
        'access': accessId,
        'inspector': inspectorId,
        'inspectorName': inspectorName,
        'timestamp': timestamp.toIso8601String(),
        'checklist': checklist,
        'status': 'completed',
        'notes': notes,
        'isSync': isOnline,
      };

      if (isOnline) {
        // Online mode: Upload to server directly
        Logger.info('Enviando inspección en modo online');
        Logger.info('🔍 accessId enviado: "$accessId"');
        Logger.info('🔍 inspectorId enviado: "$inspectorId"');
        // Ahora podemos pasar los archivos directamente
        // El PocketBaseClient actualizado manejará los objetos File y XFile correctamente
        final formData = {
          ...inspectionData,
          'signature':
              File(signaturePath), // Pasar el archivo de firma directamente
          'photos': photos, // Pasar la lista de XFile directamente
        };

        // Usar el PocketBaseClient actualizado que maneja archivos
        final record = await _pbClient.createRecord('inspections', formData);

        // Generate PDF report
        final inspection = Inspection.fromRecord(record);
        await _generatePdfReport(inspection);

        return inspection;
      } else {
        // Offline mode: Store locally for later sync
        Logger.info('Guardando inspección en modo offline');

        // En modo offline, guardar solo las rutas
        final Map<String, dynamic> offlineData = {
          ...inspectionData,
          'photosPaths': photos.map((p) => p.path).toList(),
          'signaturePath': signaturePath,
        };

        // Generar un ID temporal para la inspección offline
        final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
        offlineData['id'] = offlineId;

        // Guardar para sincronización posterior
        await _offlineSyncService.saveOfflineData(
          'inspections',
          'create',
          offlineData,
        );
        Logger.info('🔍 accessId enviado: "$accessId"');
        Logger.info('🔍 inspectorId enviado: "$inspectorId"');

        // Crear objeto Inspection a partir de los datos offline
        return Inspection.fromJson(offlineData);
      }
    } catch (e) {
      Logger.error('Error al enviar inspección: $e', error: e);

      // Guardar offline en caso de error
      final Map<String, dynamic> offlineData = {
        'access': accessId,
        'inspector': inspectorId,
        'inspectorName': inspectorName,
        'timestamp': timestamp.toIso8601String(),
        'checklist': checklist,
        'photosPaths': photos.map((p) => p.path).toList(),
        'signaturePath': signaturePath,
        'status': 'completed',
        'notes': notes,
        'isSync': false,
      };

      // Generar un ID temporal para la inspección offline
      final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      offlineData['id'] = offlineId;

      // Guardar para sincronización posterior
      await _offlineSyncService.saveOfflineData(
        'inspections',
        'create',
        offlineData,
      );

      return Inspection.fromJson(offlineData);
    }
  }

  // Generate PDF report for an inspection
  Future<String> _generatePdfReport(Inspection inspection) async {
    try {
      // Generate PDF
      final pdfPath = await _pdfService.generateInspectionReport(inspection);

      // Upload PDF to reports collection if online
      if (await _connectivityUtils.isConnected()) {
        final reportData = {
          'inspection': inspection.id,
          'generatedAt': DateTime.now().toIso8601String(),
          'generatedBy': inspection.inspectorId,
          'pdfReport': File(pdfPath), // Pasar el archivo directamente
        };

        await _pbClient.createRecord('reports', reportData);
      } else {
        // Store for later upload
        final reportData = {
          'inspection': inspection.id,
          'generatedAt': DateTime.now().toIso8601String(),
          'generatedBy': inspection.inspectorId,
          'pdfReportPath': pdfPath,
        };

        await _offlineSyncService.saveOfflineData(
          'reports',
          'create',
          reportData,
        );
      }

      return pdfPath;
    } catch (e) {
      Logger.error('Error al generar reporte PDF: $e', error: e);
      throw e;
    }
  }
}
