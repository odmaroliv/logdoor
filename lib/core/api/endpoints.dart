class ApiEndpoints {
  // Endpoints para autenticación
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyMFA = '/auth/verify-mfa';
  static const String refreshToken = '/auth/refresh-token';

  // Endpoints para usuarios
  static const String users = '/users';
  static const String userProfile = '/users/profile';

  // Endpoints para almacenes
  static const String warehouses = '/warehouses';

  // Endpoints para accesos
  static const String accesses = '/accesses';
  static const String verifyAccess = '/accesses/verify';

  // Endpoints para inspecciones
  static const String inspections = '/inspections';

  // Endpoints para reportes
  static const String reports = '/reports';

  // Endpoints para alertas
  static const String alerts = '/alerts';

  // Utilidad para obtener endpoint con ID
  static String getEndpointWithId(String endpoint, String id) {
    return '$endpoint/$id';
  }
}
