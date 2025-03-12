// lib/core/utils/exceptions.dart
class MfaRequiredException implements Exception {
  final String mfaId;
  final String email;

  MfaRequiredException(this.mfaId, this.email);

  @override
  String toString() =>
      'Se requiere verificación MFA para completar el inicio de sesión';
}
