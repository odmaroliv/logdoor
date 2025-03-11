// lib/features/reports/providers/report_provider.dart
import 'package:flutter/material.dart';
import '../../../core/models/report.dart';
import '../../../core/models/inspection.dart';
import '../../../core/services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  List<Report> _reports = [];
  Report? _currentReport;
  bool _isLoading = false;
  String? _error;

  List<Report> get reports => _reports;
  Report? get currentReport => _currentReport;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Obtener lista de reportes
  Future<void> getReports({
    String? inspectionId,
    String? generatedById,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _reportService.getReports(
        inspectionId: inspectionId,
        generatedById: generatedById,
        fromDate: fromDate,
        toDate: toDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al cargar reportes: ${e.toString()}';
      notifyListeners();
    }
  }

  // Obtener reporte por ID
  Future<Report?> getReportById(String reportId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentReport = await _reportService.getReportById(reportId);
      _isLoading = false;
      notifyListeners();
      return _currentReport;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al obtener reporte: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Generar reporte para una inspección
  Future<Report?> generateReport(Inspection inspection, String generatedById,
      String generatedByName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final report = await _reportService.generateReport(
          inspection, generatedById, generatedByName);

      // Agregar el nuevo reporte a la lista
      _reports.insert(0, report);
      _currentReport = report;

      _isLoading = false;
      notifyListeners();
      return report;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al generar reporte: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Compartir reporte
  Future<bool> shareReport(Report report) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _reportService.shareReport(report);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al compartir reporte: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
