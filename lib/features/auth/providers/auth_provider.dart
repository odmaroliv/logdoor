// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:logdoor/core/utils/exceptions.dart';
import '../../../core/models/user.dart';
import '../../../core/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _requiresMfa = false;
  String? _mfaEmail;
  String? _mfaId;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get requiresMfa => _requiresMfa;
  String? get mfaEmail => _mfaEmail;
  String? get mfaId => _mfaId;

// Verificar autenticación al iniciar
  Future<bool> checkAuth() async {
    // No cambies el valor de _isLoading ni llames a notifyListeners() aquí
    try {
      final isAuthenticated = await _authService.checkAuth();
      if (isAuthenticated) {
        _currentUser = _authService.currentUser;
      }

      // Actualiza _isLoading y notifica después de que la operación asíncrona se complete
      _isLoading = false;
      notifyListeners();

      return isAuthenticated;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
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

      // Detectar si es una excepción MFA
      if (e is MfaRequiredException) {
        // No establecer error, solo indicar que se requiere MFA
        _requiresMfa = true;
        _mfaEmail = e.email;
        _mfaId = e.mfaId;
        notifyListeners();

        // Devolver true para indicar que el proceso de login continúa en la pantalla MFA
        return true;
      }

      _error = 'Error de inicio de sesión: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Verificar código MFA
  Future<bool> verifyMFA(String otpId, String code) async {
    try {
      final isVerified = await _authService.verifyMFA(otpId, code);
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

  // Método para reenviar el código OTP
  Future<void> resendOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService
          .requestOtp(email); // Llamamos al servicio para reenviar el OTP
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al reenviar código: ${e.toString()}';
      notifyListeners();
    }
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
