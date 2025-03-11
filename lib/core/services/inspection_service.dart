import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../api/pocketbase_client.dart';
import '../models/inspection.dart';
import 'offline_sync_service.dart';
import 'geolocation_service.dart';
import '../utils/connectivity_utils.dart';
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
        // Upload inspection with files
        final formData = {
          ...inspectionData,
        };

        // Add signature file
        final signatureFile = File(signaturePath);
        formData['signature'] = signatureFile;

        // Add photos
        List<File> photoFiles =
            photos.map((xFile) => File(xFile.path)).toList();
        formData['photos'] = photoFiles;

        // Create record with files
        final record = await _pbClient.createRecord('inspections', formData);

        // Generate PDF report
        final inspection = Inspection.fromRecord(record);
        await _generatePdfReport(inspection);

        return inspection;
      } else {
        // Store locally for sync later
        // For simplicity, store photo paths and signature path for now
        // In a real implementation, you might want to copy these files to app storage
        inspectionData['photos'] = photos.map((p) => p.path).toList();
        inspectionData['signature'] = signaturePath;

        await _offlineSyncService.saveOfflineData(
            'inspections', 'create', inspectionData);

        // Create a temporary ID for offline storage
        inspectionData['id'] =
            'offline_${DateTime.now().millisecondsSinceEpoch}';

        return Inspection.fromJson(inspectionData);
      }
    } catch (e) {
      // Store offline on API error
      final inspectionData = {
        'access': accessId,
        'inspector': inspectorId,
        'inspectorName': inspectorName,
        'timestamp': timestamp.toIso8601String(),
        'checklist': checklist,
        'photos': photos.map((p) => p.path).toList(),
        'signature': signaturePath,
        'status': 'completed',
        'notes': notes,
        'isSync': false,
      };

      await _offlineSyncService.saveOfflineData(
          'inspections', 'create', inspectionData);

      // Create a temporary ID for offline storage
      inspectionData['id'] = 'offline_${DateTime.now().millisecondsSinceEpoch}';

      return Inspection.fromJson(inspectionData);
    }
  }

  // Generate PDF report for an inspection
  Future<String> _generatePdfReport(Inspection inspection) async {
    try {
      // Generate PDF
      final pdfPath = await _pdfService.generateInspectionReport(inspection);

      // Upload PDF to reports collection
      if (await _connectivityUtils.isConnected()) {
        final reportData = {
          'inspection': inspection.id,
          'generatedAt': DateTime.now().toIso8601String(),
          'generatedBy': inspection.inspectorId,
        };

        final formData = {
          ...reportData,
          'pdfReport': File(pdfPath),
        };

        await _pbClient.createRecord('reports', formData);
      } else {
        // Store for later upload
        final reportData = {
          'inspection': inspection.id,
          'generatedAt': DateTime.now().toIso8601String(),
          'generatedBy': inspection.inspectorId,
          'pdfReport': pdfPath,
        };

        await _offlineSyncService.saveOfflineData(
            'reports', 'create', reportData);
      }

      return pdfPath;
    } catch (e) {
      // Handle error
      print('Error generating report: $e');
      throw e;
    }
  }
}
