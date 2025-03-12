// lib/features/settings/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/localization.dart';
import '../../../core/models/warehouse.dart';
import '../../../core/models/user.dart';
import '../../../core/services/warehouse_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/logger.dart';

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
      Logger.info('Inicializando configuraciones...');

      // Cargar preferencias
      final prefs = await SharedPreferences.getInstance();

      // Cargar tema
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      Logger.info('Modo oscuro cargado: $_isDarkMode');

      // Cargar idioma
      final savedLocale = await LocalizationService.getPreferredLocale();
      _appLocale = savedLocale;
      Logger.info('Locale cargado: ${_appLocale.languageCode}');

      // Verificar si biometría está habilitada
      _isBiometricsEnabled = await _authService.isBiometricsEnabled();
      Logger.info('Biometría habilitada: $_isBiometricsEnabled');

      // Cargar datos del usuario actual
      if (_authService.currentUser != null) {
        _currentUser = _authService.currentUser;
        Logger.info('Usuario actual cargado: ${_currentUser?.name}');
      }

      // Cargar almacenes
      await loadWarehouses();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      Logger.error('Error al inicializar configuraciones', error: e);
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
      Logger.info('${_warehouses.length} almacenes cargados');

      if (_warehouses.isNotEmpty && _selectedWarehouse == null) {
        _selectedWarehouse = _warehouses.first;
        Logger.info(
            'Almacén seleccionado por defecto: ${_selectedWarehouse?.name}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      Logger.error('Error al cargar almacenes', error: e);
      _isLoading = false;
      _error = 'Error al cargar almacenes: ${e.toString()}';
      notifyListeners();
    }
  }

  // Seleccionar almacén
  void selectWarehouse(Warehouse warehouse) {
    _selectedWarehouse = warehouse;
    Logger.info('Almacén seleccionado: ${warehouse.name}');
    notifyListeners();
  }

  // Cambiar tema
  Future<void> toggleDarkMode() async {
    try {
      _isDarkMode = !_isDarkMode;
      Logger.info('Modo oscuro cambiado a: $_isDarkMode');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', _isDarkMode);
      Logger.info('Preferencia de modo oscuro guardada');

      notifyListeners();
    } catch (e) {
      Logger.error('Error al cambiar tema', error: e);
      _error = 'Error al cambiar tema: ${e.toString()}';
      notifyListeners();
    }
  }

  // Cambiar idioma
  Future<void> changeLanguage(String languageCode) async {
    try {
      await LocalizationService.changeLanguage(languageCode);
      _appLocale = await LocalizationService.getPreferredLocale();
      Logger.info('Idioma cambiado a: ${_appLocale.languageCode}');
      notifyListeners();
    } catch (e) {
      Logger.error('Error al cambiar idioma', error: e);
      _error = 'Error al cambiar idioma: ${e.toString()}';
      notifyListeners();
    }
  }

  // Habilitar/deshabilitar biometría
  Future<bool> toggleBiometrics(String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_isBiometricsEnabled) {
        await _authService.disableBiometrics();
        _isBiometricsEnabled = false;
        Logger.info('Biometría deshabilitada');
      } else {
        await _authService.enableBiometrics(password);
        _isBiometricsEnabled = true;
        Logger.info('Biometría habilitada');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      Logger.error('Error al modificar biometría', error: e);
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
    if (_currentUser == null) {
      Logger.warning(
          'No se puede actualizar el perfil: usuario no inicializado');
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Logger.info('Actualizando perfil para usuario: ${_currentUser?.id}');

      final updatedUser = await _userService.updateUser(
        userId: _currentUser!.id,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
      );

      _currentUser = updatedUser;
      Logger.info('Perfil actualizado con éxito');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      Logger.error('Error al actualizar perfil', error: e);
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
    if (_currentUser == null) {
      Logger.warning(
          'No se puede actualizar la contraseña: usuario no inicializado');
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Logger.info('Actualizando contraseña para usuario: ${_currentUser?.id}');

      final result = await _userService.updatePassword(
        userId: _currentUser!.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _isLoading = false;
      notifyListeners();

      if (result) {
        Logger.info('Contraseña actualizada con éxito');
      } else {
        Logger.warning('No se pudo actualizar la contraseña');
      }

      return result;
    } catch (e) {
      Logger.error('Error al actualizar contraseña', error: e);
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
      Logger.info('Creando nuevo almacén: $name');

      final warehouse = await _warehouseService.createWarehouse(
        name: name,
        location: location,
        address: address,
        coordinates: coordinates,
        description: description,
      );

      _warehouses.add(warehouse);
      Logger.info('Almacén creado con éxito: ${warehouse.id}');

      _isLoading = false;
      notifyListeners();
      return warehouse;
    } catch (e) {
      Logger.error('Error al crear almacén', error: e);
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
    bool? isActive,
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
        isActive: isActive,
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
      Logger.info('Desactivando almacén: $warehouseId');

      final result = await _warehouseService.deactivateWarehouse(warehouseId);

      if (result) {
        // Remover almacén de la lista
        _warehouses.removeWhere((w) => w.id == warehouseId);
        Logger.info('Almacén removido de la lista');

        // Si el almacén seleccionado fue desactivado, seleccionar otro
        if (_selectedWarehouse?.id == warehouseId) {
          _selectedWarehouse =
              _warehouses.isNotEmpty ? _warehouses.first : null;
          Logger.info(
              'Seleccionado nuevo almacén por defecto: ${_selectedWarehouse?.name}');
        }
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      Logger.error('Error al desactivar almacén', error: e);
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
