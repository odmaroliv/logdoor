// lib/core/services/report_service.dart
import 'dart:io';
import 'package:flutter/services.dart';
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

      // Convertir los registros a objetos Report
      List<Report> reports = [];
      for (var record in records) {
        try {
          reports.add(Report.fromRecord(record));
        } catch (e) {
          Logger.error('Error al convertir registro a Report', error: e);
        }
      }

      return reports;
    } catch (e) {
      Logger.error('Error al obtener reportes', error: e);

      // Intentar obtener datos offline
      try {
        final offlineData = await _offlineSyncService.getOfflineData('reports');
        return offlineData.map((data) => Report.fromJson(data)).toList();
      } catch (offlineError) {
        Logger.error('Error al obtener datos offline', error: offlineError);
        return [];
      }
    }
  }

  // Obtener reporte por ID - CORREGIDO
  Future<Report?> getReportById(String reportId) async {
    try {
      final record = await _pbClient.getRecord('reports', reportId,
          expand: 'generatedBy,inspection');
      if (record != null) {
        return Report.fromRecord(record);
      }
      return null;
    } catch (e) {
      Logger.error('Error al obtener reporte por ID', error: e);

      // Buscar en datos offline
      try {
        final offlineData = await _offlineSyncService.getOfflineData('reports');
        final matchingReport = offlineData.firstWhere(
          (data) => data['id'] == reportId,
          orElse: () => <String, dynamic>{},
        );

        if (matchingReport.isNotEmpty) {
          return Report.fromJson(matchingReport);
        }
      } catch (offlineError) {
        Logger.error('Error al buscar reporte en datos offline',
            error: offlineError);
      }

      return null;
    }
  }

  // Generar reporte PDF para una inspección
  Future<Report> generateReport(Inspection inspection, String generatedById,
      String generatedByName) async {
    try {
      Logger.info(
          'Iniciando generación de reporte para inspección: ${inspection.id}');

      // Generar PDF con el servicio
      final pdfPath = await _pdfService.generateInspectionReport(inspection);
      Logger.info('PDF generado en: $pdfPath');

      final reportData = {
        'inspection': inspection.id,
        'generatedAt': DateTime.now().toIso8601String(),
        'generatedBy': generatedById,
        'generatedByName': generatedByName,
      };

      // Intentar crear reporte en línea
      try {
        Logger.info('Intentando crear reporte en línea');
        final file = File(pdfPath);

        if (!await file.exists()) {
          throw Exception('El archivo PDF no existe en la ruta: $pdfPath');
        }

        final formData = {
          ...reportData,
          'pdfReport': file,
        };

        final record =
            await _pbClient.createRecordWithFiles('reports', reportData, {
          'pdfReport': [file]
        });

        Logger.info('Reporte creado con éxito. ID: ${record.id}');
        return Report.fromRecord(record);
      } catch (e) {
        Logger.error('Error al crear reporte en línea, guardando offline',
            error: e);

        // Guardar para sincronización offline
        reportData['pdfReport'] = pdfPath;
        reportData['id'] = 'offline_${DateTime.now().millisecondsSinceEpoch}';

        await _offlineSyncService.saveOfflineData(
            'reports', 'create', reportData);

        // Para la experiencia del usuario, devolver un objeto con ID temporal
        return Report(
          id: reportData['id'] as String,
          inspectionId: inspection.id,
          generatedAt: DateTime.now(),
          pdfReport: pdfPath,
          generatedById: generatedById,
          generatedByName: generatedByName,
        );
      }
    } catch (e) {
      Logger.error('Error al generar reporte', error: e);
      throw Exception('Error al generar reporte: ${e.toString()}');
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

        // Implementar descarga del archivo
        // Por ahora, asumimos que ya tenemos el archivo local
        pdfFile = File(localPath);

        if (!await pdfFile.exists()) {
          throw Exception('No se pudo descargar el archivo remoto');
        }
      } else {
        // Es una ruta local
        pdfFile = File(report.pdfReport);

        if (!await pdfFile.exists()) {
          throw Exception('El archivo del reporte no existe en la ruta local');
        }
      }

      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Reporte de inspección CTPAT',
      );
    } catch (e) {
      Logger.error('Error al compartir reporte', error: e);
      rethrow;
    }
  }
}
