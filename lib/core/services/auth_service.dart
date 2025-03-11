import 'package:local_auth/local_auth.dart';
import '../api/pocketbase_client.dart';
import '../models/user.dart';
import '../utils/secure_storage.dart';
import '../utils/logger.dart';

class AuthService {
  final PocketBaseClient _pbClient = PocketBaseClient();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorage _secureStorage = SecureStorage();

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Verificar si hay una sesión activa
  Future<bool> checkAuth() async {
    try {
      return _pbClient.pb.authStore.isValid;
    } catch (e) {
      Logger.error('Error al verificar autenticación', error: e);
      return false;
    }
  }

  // Iniciar sesión con email y contraseña
  Future<User> login(String email, String password) async {
    try {
      final auth = await _pbClient.signIn(email, password);
      _currentUser = User.fromRecord(auth.record!);
      return _currentUser!;
    } catch (e) {
      Logger.error('Error en login', error: e);
      rethrow;
    }
  }

  // Verificar código MFA
  Future<bool> verifyMFA(String code) async {
    try {
      if (_currentUser == null) {
        throw Exception('Usuario no iniciado');
      }

      return await _pbClient.verifyMFA(_currentUser!.id, code);
    } catch (e) {
      Logger.error('Error en verificación MFA', error: e);
      rethrow;
    }
  }

  // Autenticación biométrica
  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return false;
      }

      final savedUserId = await _secureStorage.read(key: 'biometric_user_id');
      if (savedUserId == null) {
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Autentícate para acceder a Logdoor',
      );

      if (didAuthenticate) {
        // Recuperar credenciales y hacer login
        final email = await _secureStorage.read(key: 'user_email');
        final password = await _secureStorage.read(key: 'user_password');

        if (email != null && password != null) {
          await login(email, password);
          return true;
        }
      }

      return false;
    } catch (e) {
      Logger.error('Error en autenticación biométrica', error: e);
      return false;
    }
  }

  // Habilitar autenticación biométrica
  Future<void> enableBiometrics(String password) async {
    try {
      if (_currentUser == null) {
        throw Exception('Usuario no iniciado');
      }

      await _secureStorage.write(
          key: 'biometric_user_id', value: _currentUser!.id);
      await _secureStorage.write(key: 'user_email', value: _currentUser!.email);
      await _secureStorage.write(key: 'user_password', value: password);

      Logger.info(
          'Autenticación biométrica habilitada para ${_currentUser!.email}');
    } catch (e) {
      Logger.error('Error al habilitar biometría', error: e);
      rethrow;
    }
  }

  // Deshabilitar autenticación biométrica
  Future<void> disableBiometrics() async {
    try {
      await _secureStorage.delete(key: 'biometric_user_id');
      await _secureStorage.delete(key: 'user_email');
      await _secureStorage.delete(key: 'user_password');

      Logger.info('Autenticación biométrica deshabilitada');
    } catch (e) {
      Logger.error('Error al deshabilitar biometría', error: e);
      rethrow;
    }
  }

  // Verificar si la autenticación biométrica está habilitada
  Future<bool> isBiometricsEnabled() async {
    try {
      final biometricUserId =
          await _secureStorage.read(key: 'biometric_user_id');
      return biometricUserId != null;
    } catch (e) {
      Logger.error('Error al verificar estado de biometría', error: e);
      return false;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      await _pbClient.signOut();
      _currentUser = null;

      Logger.info('Sesión cerrada');
    } catch (e) {
      Logger.error('Error al cerrar sesión', error: e);
      rethrow;
    }
  }
}
