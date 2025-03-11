// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../../../core/models/user.dart';
import '../../../core/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Verificar autenticación al iniciar
  Future<bool> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isAuthenticated = await _authService.checkAuth();
      if (isAuthenticated) {
        _currentUser = _authService.currentUser;
      }
      _isLoading = false;
      notifyListeners();
      return isAuthenticated;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Iniciar sesión con correo y contraseña
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error de inicio de sesión: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Verificar código MFA
  Future<bool> verifyMFA(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isVerified = await _authService.verifyMFA(code);
      _isLoading = false;
      if (!isVerified) {
        _error = 'Código de verificación inválido';
      }
      notifyListeners();
      return isVerified;
    } catch (e) {
      _isLoading = false;
      _error = 'Error de verificación: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Autenticación biométrica
  Future<bool> authenticateWithBiometrics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authenticated = await _authService.authenticateWithBiometrics();
      _isLoading = false;
      if (authenticated) {
        _currentUser = _authService.currentUser;
      } else {
        _error = 'Autenticación biométrica fallida';
      }
      notifyListeners();
      return authenticated;
    } catch (e) {
      _isLoading = false;
      _error = 'Error de autenticación biométrica: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Habilitar autenticación biométrica
  Future<bool> enableBiometrics(String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.enableBiometrics(password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al habilitar biometría: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Deshabilitar autenticación biométrica
  Future<bool> disableBiometrics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.disableBiometrics();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al deshabilitar biometría: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Verificar si biometría está habilitada
  Future<bool> isBiometricsEnabled() async {
    return await _authService.isBiometricsEnabled();
  }

  // Cerrar sesión
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al cerrar sesión: ${e.toString()}';
      notifyListeners();
    }
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
