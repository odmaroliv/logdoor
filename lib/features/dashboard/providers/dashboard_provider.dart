// lib/features/dashboard/providers/dashboard_provider.dart
import 'package:flutter/material.dart';
import '../../../core/models/alert.dart';
import '../../../core/services/access_service.dart';
import '../../../core/services/inspection_service.dart';
import '../../../core/services/alert_service.dart';

class DashboardProvider extends ChangeNotifier {
  final AccessService _accessService = AccessService();
  final InspectionService _inspectionService = InspectionService();
  final AlertService _alertService = AlertService();

  bool _isLoading = false;
  String? _error;

  // Estadísticas
  int _totalAccess = 0;
  int _totalInspections = 0;
  int _totalEntries = 0;
  int _totalExits = 0;
  int _totalAlerts = 0;
  double _issueRate = 0.0;

  // Datos
  List<Map<String, dynamic>> _recentActivities = [];
  List<Alert> _activeAlerts = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalAccess => _totalAccess;
  int get totalInspections => _totalInspections;
  int get totalEntries => _totalEntries;
  int get totalExits => _totalExits;
  int get totalAlerts => _totalAlerts;
  double get issueRate => _issueRate;
  List<Map<String, dynamic>> get recentActivities => _recentActivities;
  List<Alert> get activeAlerts => _activeAlerts;

  // Cargar datos del dashboard
  Future<void> loadDashboardData({
    String? warehouseId,
    String? userId,
    String? inspectorId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Obtener accesos
      final accesses = await _accessService.getAccessList(
        warehouseId: warehouseId,
        userId: userId,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Contadores de accesos
      _totalAccess = accesses.length;
      _totalEntries = accesses.where((a) => a.accessType == 'entry').length;
      _totalExits = accesses.where((a) => a.accessType == 'exit').length;

      // Obtener inspecciones
      final inspections = await _inspectionService.getInspections(
        accessId: null,
        inspectorId: inspectorId,
        fromDate: fromDate,
        toDate: toDate,
      );

      _totalInspections = inspections.length;

      // Calcular tasa de problemas
      int inspectionsWithIssues = inspections.where((i) => i.hasIssues).length;
      _issueRate = inspections.isEmpty
          ? 0.0
          : (inspectionsWithIssues / inspections.length) * 100;

      // Obtener alertas activas
      _activeAlerts = await _alertService.getAlerts(
        status: 'active',
        fromDate: fromDate,
        toDate: toDate,
      );

      _totalAlerts = _activeAlerts.length;

      // Crear lista de actividades recientes
      _recentActivities = [];

      // Agregar últimos accesos (máximo 5)
      for (var i = 0; i < accesses.length && i < 5; i++) {
        _recentActivities.add({
          'type': 'access',
          'subtype': accesses[i].accessType,
          'title': accesses[i].accessType == 'entry' ? 'Entrada' : 'Salida',
          'description': 'Conductor: ${accesses[i].userName}',
          'timestamp': accesses[i].timestamp,
          'data': accesses[i],
        });
      }

      // Agregar últimas inspecciones (máximo 5)
      for (var i = 0; i < inspections.length && i < 5; i++) {
        _recentActivities.add({
          'type': 'inspection',
          'subtype': inspections[i].hasIssues ? 'issues' : 'ok',
          'title': 'Inspección',
          'description': 'Inspector: ${inspections[i].inspectorName}',
          'timestamp': inspections[i].timestamp,
          'data': inspections[i],
        });
      }

      // Ordenar por fecha más reciente
      _recentActivities.sort((a, b) {
        return (b['timestamp'] as DateTime)
            .compareTo(a['timestamp'] as DateTime);
      });

      // Limitar a 10 actividades
      if (_recentActivities.length > 10) {
        _recentActivities = _recentActivities.sublist(0, 10);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al cargar datos: ${e.toString()}';
      notifyListeners();
    }
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
