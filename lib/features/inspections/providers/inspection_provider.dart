import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/inspection.dart';
import '../../../core/services/inspection_service.dart';

class InspectionProvider extends ChangeNotifier {
  final InspectionService _inspectionService = InspectionService();

  List<Inspection> _inspections = [];
  Inspection? _currentInspection;
  bool _isLoading = false;
  String? _error;

  List<Inspection> get inspections => _inspections;
  Inspection? get currentInspection => _currentInspection;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Obtener lista de inspecciones
  Future<void> getInspections({
    String? accessId,
    String? inspectorId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _inspections = await _inspectionService.getInspections(
        accessId: accessId,
        inspectorId: inspectorId,
        fromDate: fromDate,
        toDate: toDate,
        status: status,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al cargar inspecciones: ${e.toString()}';
      notifyListeners();
    }
  }

  // Obtener inspección por ID
  Future<Inspection?> getInspectionById(String inspectionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Buscar primero en la lista local
      _currentInspection = _inspections.firstWhere(
        (inspection) => inspection.id == inspectionId,
        orElse: () => null as Inspection,
      );

      // Si no se encontró, obtener de la base de datos
      if (_currentInspection == null) {
        final inspections = await _inspectionService.getInspections(
          accessId: null,
          inspectorId: null,
          fromDate: null,
          toDate: null,
          status: null,
        );

        _currentInspection = inspections.firstWhere(
          (inspection) => inspection.id == inspectionId,
          orElse: () => null as Inspection,
        );
      }

      _isLoading = false;
      notifyListeners();
      return _currentInspection;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al obtener inspección: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Enviar nueva inspección
  Future<Inspection?> submitInspection({
    required Map<String, dynamic> inspectionData,
    required List<XFile> photos,
    required String signaturePath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final inspection = await _inspectionService.submitInspection(
        accessId: inspectionData['access'],
        inspectorId: inspectionData['inspector'],
        inspectorName: inspectionData['inspectorName'],
        checklist: inspectionData['checklist'],
        photos: photos,
        signaturePath: signaturePath,
        notes: inspectionData['notes'],
      );

      // Agregar la nueva inspección a la lista
      if (inspection != null) {
        _inspections.insert(0, inspection);
        _currentInspection = inspection;
      }

      _isLoading = false;
      notifyListeners();
      return inspection;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al enviar inspección: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
