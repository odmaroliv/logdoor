import 'package:flutter/material.dart';
import '../../../core/models/access.dart';
import '../../../core/services/access_service.dart';
import '../../../core/utils/connectivity_utils.dart';

class AccessProvider extends ChangeNotifier {
  final AccessService _accessService = AccessService();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();

  List<Access> _accessList = [];
  bool _isLoading = false;
  String? _error;

  List<Access> get accessList => _accessList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Obtener lista de accesos
  Future<void> getAccesses({
    String? warehouseId,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _accessList = await _accessService.getAccessList(
        warehouseId: warehouseId,
        userId: userId,
        fromDate: fromDate,
        toDate: toDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al cargar accesos: ${e.toString()}';
      notifyListeners();
    }
  }

  // Crear nuevo acceso
  Future<Access?> createAccess({
    required String userId,
    required String userName,
    required String warehouseId,
    required String warehouseName,
    required String accessType,
    Map<String, dynamic>? vehicleData,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newAccess = await _accessService.createAccess(
        userId: userId,
        userName: userName,
        warehouseId: warehouseId,
        warehouseName: warehouseName,
        accessType: accessType,
        vehicleData: vehicleData,
      );

      // Agregar el nuevo acceso a la lista
      _accessList.insert(0, newAccess);
      _isLoading = false;
      notifyListeners();
      return newAccess;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al crear acceso: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Verificar código de acceso
  Future<bool> verifyAccessCode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final access = await _accessService.verifyAccessCode(code);
      _isLoading = false;
      notifyListeners();
      return access != null;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al verificar código: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Obtener acceso por código
  Future<Access?> getAccessByCode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final access = await _accessService.verifyAccessCode(code);
      _isLoading = false;
      notifyListeners();
      return access;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al obtener acceso: ${e.toString()}';
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
