import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../api/pocketbase_client.dart';
import '../models/report.dart';
import '../models/inspection.dart';
import '../utils/logger.dart';
import 'offline_sync_service.dart';
import 'pdf_service.dart';

class ReportService {
  final PocketBaseClient _pbClient = PocketBaseClient();
  final OfflineSyncService _offlineSyncService = OfflineSyncService();
  final PdfService _pdfService = PdfService();

  // Obtener lista de reportes
  Future<List<Report>> getReports({
    String? inspectionId,
    String? generatedById,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      // Construir filtro
      List<String> filters = [];
      if (inspectionId != null) filters.add('inspection = "$inspectionId"');
      if (generatedById != null) filters.add('generatedBy = "$generatedById"');
      if (fromDate != null)
        filters.add('generatedAt >= "${fromDate.toIso8601String()}"');
      if (toDate != null)
        filters.add('generatedAt <= "${toDate.toIso8601String()}"');

      final filterStr = filters.isNotEmpty ? filters.join(' && ') : '';

      // Intentar obtener datos en línea
      final records = await _pbClient.getRecords(
        'reports',
        page: page,
        perPage: perPage,
        filter: filterStr,
        expand: 'generatedBy,inspection',
      );

      return records.map((record) => Report.fromRecord(record)).toList();
    } catch (e) {
      Logger.error('Error al obtener reportes', error: e);
      // Intentar obtener datos offline
      final offlineData = await _offlineSyncService.getOfflineData('reports');
      return offlineData.map((data) => Report.fromJson(data)).toList();
    }
  }

  // Generar reporte PDF para una inspección
  Future<Report> generateReport(Inspection inspection, String generatedById,
      String generatedByName) async {
    try {
      // Generar PDF con el servicio
      final pdfPath = await _pdfService.generateInspectionReport(inspection);

      final reportData = {
        'inspection': inspection.id,
        'generatedAt': DateTime.now().toIso8601String(),
        'generatedBy': generatedById,
        'generatedByName': generatedByName,
      };

      // Intentar crear reporte en línea
      try {
        final formData = {
          ...reportData,
          'pdfReport': File(pdfPath),
        };

        final record =
            await _pbClient.createRecordWithFiles('reports', reportData, {
          'pdfReport': [File(pdfPath)]
        });

        return Report.fromRecord(record);
      } catch (e) {
        // Guardar para sincronización offline
        reportData['pdfReport'] = pdfPath;
        await _offlineSyncService.saveOfflineData(
            'reports', 'create', reportData);

        // Para la experiencia del usuario, devolver un objeto con ID temporal
        return Report(
          id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
          inspectionId: inspection.id,
          generatedAt: DateTime.now(),
          pdfReport: pdfPath,
          generatedById: generatedById,
          generatedByName: generatedByName,
        );
      }
    } catch (e) {
      Logger.error('Error al generar reporte', error: e);
      rethrow;
    }
  }

  // Obtener reporte por ID
  Future<Report?> getReportById(String reportId) async {
    try {
      final record = await _pbClient.getRecord('reports', reportId,
          expand: 'generatedBy,inspection');
      return Report.fromRecord(record);
    } catch (e) {
      Logger.error('Error al obtener reporte por ID', error: e);

      // Buscar en datos offline
      final offlineData = await _offlineSyncService.getOfflineData('reports');
      final matchingReport = offlineData.firstWhere(
        (data) => data['id'] == reportId,
        orElse: () => <String, dynamic>{},
      );

      if (matchingReport.isNotEmpty) {
        return Report.fromJson(matchingReport);
      }

      return null;
    }
  }

  // Compartir reporte
  Future<void> shareReport(Report report) async {
    try {
      File pdfFile;

      // Si es una URL remota, descargarla primero
      if (report.pdfReport.startsWith('http')) {
        final tempDir = await getTemporaryDirectory();
        final localPath = '${tempDir.path}/report_${report.id}.pdf';

        // Aquí deberías implementar la descarga del archivo
        // Por simplicidad, asumimos que ya tenemos el archivo local
        pdfFile = File(localPath);
      } else {
        // Es una ruta local
        pdfFile = File(report.pdfReport);
      }

      if (await pdfFile.exists()) {
        await Share.shareXFiles(
          [XFile(pdfFile.path)],
          text: 'Reporte de inspección CTPAT',
        );
      } else {
        throw Exception('El archivo del reporte no existe');
      }
    } catch (e) {
      Logger.error('Error al compartir reporte', error: e);
      rethrow;
    }
  }
}
