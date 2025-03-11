// lib/features/settings/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/localization.dart';
import '../../../core/models/warehouse.dart';
import '../../../core/models/user.dart';
import '../../../core/services/warehouse_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/auth_service.dart';

class SettingsProvider extends ChangeNotifier {
  final WarehouseService _warehouseService = WarehouseService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  List<Warehouse> _warehouses = [];
  Warehouse? _selectedWarehouse;
  User? _currentUser;
  bool _isDarkMode = false;
  Locale _appLocale = LocalizationService.defaultLocale;
  bool _isBiometricsEnabled = false;
  bool _isLoading = false;
  String? _error;

  List<Warehouse> get warehouses => _warehouses;
  Warehouse? get selectedWarehouse => _selectedWarehouse;
  User? get currentUser => _currentUser;
  bool get isDarkMode => _isDarkMode;
  Locale get appLocale => _appLocale;
  bool get isBiometricsEnabled => _isBiometricsEnabled;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Inicializar configuraciones
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cargar preferencias
      final prefs = await SharedPreferences.getInstance();

      // Cargar tema
      _isDarkMode = prefs.getBool('dark_mode') ?? false;

      // Cargar idioma
      final savedLocale = await LocalizationService.getPreferredLocale();
      _appLocale = savedLocale;

      // Verificar si biometría está habilitada
      _isBiometricsEnabled = await _authService.isBiometricsEnabled();

      // Cargar datos del usuario actual
      if (_authService.currentUser != null) {
        _currentUser = _authService.currentUser;
      }

      // Cargar almacenes
      await loadWarehouses();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al inicializar configuraciones: ${e.toString()}';
      notifyListeners();
    }
  }

  // Cargar almacenes disponibles
  Future<void> loadWarehouses() async {
    _isLoading = true;
    notifyListeners();

    try {
      _warehouses = await _warehouseService.getWarehouses();

      if (_warehouses.isNotEmpty && _selectedWarehouse == null) {
        _selectedWarehouse = _warehouses.first;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al cargar almacenes: ${e.toString()}';
      notifyListeners();
    }
  }

  // Seleccionar almacén
  void selectWarehouse(Warehouse warehouse) {
    _selectedWarehouse = warehouse;
    notifyListeners();
  }

  // Cambiar tema
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);

    notifyListeners();
  }

  // Cambiar idioma
  Future<void> changeLanguage(String languageCode) async {
    await LocalizationService.changeLanguage(languageCode);
    _appLocale = await LocalizationService.getPreferredLocale();
    notifyListeners();
  }

  // Habilitar/deshabilitar biometría
  Future<bool> toggleBiometrics(String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_isBiometricsEnabled) {
        await _authService.disableBiometrics();
        _isBiometricsEnabled = false;
      } else {
        await _authService.enableBiometrics(password);
        _isBiometricsEnabled = true;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al modificar biometría: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Actualizar perfil de usuario
  Future<bool> updateUserProfile({
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _userService.updateUser(
        userId: _currentUser!.id,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
      );

      _currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al actualizar perfil: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Actualizar contraseña
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _userService.updatePassword(
        userId: _currentUser!.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al actualizar contraseña: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Crear nuevo almacén
  Future<Warehouse?> createWarehouse({
    required String name,
    required String location,
    required String address,
    required Map<String, dynamic> coordinates,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final warehouse = await _warehouseService.createWarehouse(
        name: name,
        location: location,
        address: address,
        coordinates: coordinates,
        description: description,
      );

      _warehouses.add(warehouse);
      _isLoading = false;
      notifyListeners();
      return warehouse;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al crear almacén: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Actualizar almacén
  Future<bool> updateWarehouse({
    required String warehouseId,
    String? name,
    String? location,
    String? address,
    Map<String, dynamic>? coordinates,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedWarehouse = await _warehouseService.updateWarehouse(
        warehouseId: warehouseId,
        name: name,
        location: location,
        address: address,
        coordinates: coordinates,
        description: description,
      );

      // Actualizar almacén en la lista
      final index = _warehouses.indexWhere((w) => w.id == warehouseId);
      if (index >= 0) {
        _warehouses[index] = updatedWarehouse;
      }

      // Si el almacén seleccionado fue actualizado, actualizarlo también
      if (_selectedWarehouse?.id == warehouseId) {
        _selectedWarehouse = updatedWarehouse;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al actualizar almacén: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Desactivar almacén
  Future<bool> deactivateWarehouse(String warehouseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _warehouseService.deactivateWarehouse(warehouseId);

      if (result) {
        // Remover almacén de la lista
        _warehouses.removeWhere((w) => w.id == warehouseId);

        // Si el almacén seleccionado fue desactivado, seleccionar otro
        if (_selectedWarehouse?.id == warehouseId) {
          _selectedWarehouse =
              _warehouses.isNotEmpty ? _warehouses.first : null;
        }
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al desactivar almacén: ${e.toString()}';
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
