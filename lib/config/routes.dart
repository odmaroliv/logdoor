// lib/config/routes.dart
import 'package:flutter/material.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/mfa_screen.dart';
import '../features/dashboard/screens/admin_dashboard.dart';
import '../features/dashboard/screens/inspector_dashboard.dart';
import '../features/dashboard/screens/guard_dashboard.dart';
import '../features/access_control/screens/access_list_screen.dart';
import '../features/access_control/screens/access_form_screen.dart';
import '../features/access_control/screens/qr_scanner_screen.dart';
import '../features/access_control/screens/qr_generator_screen.dart';
import '../core/models/access.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case '/mfa':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MfaScreen(
            email: args?['email'] ?? '',
            password: args?['password'] ?? '',
            otpId: args?['otpId'] ?? '', // Añadir este parámetro
          ),
        );

      case '/dashboard/admin':
        return MaterialPageRoute(builder: (_) => const AdminDashboard());

      case '/dashboard/inspector':
        return MaterialPageRoute(builder: (_) => const InspectorDashboard());

      case '/dashboard/guard':
        return MaterialPageRoute(builder: (_) => const GuardDashboard());

      case '/access/list':
        return MaterialPageRoute(builder: (_) => const AccessListScreen());

      case '/access/new':
        return MaterialPageRoute(builder: (_) => const AccessFormScreen());

      case '/access/scan':
        return MaterialPageRoute(builder: (_) => const QrScannerScreen());

      case '/access/qr':
        final args = settings.arguments as Map<String, dynamic>;
        final access = args['access'] as Access;
        return MaterialPageRoute(
          builder: (_) => QrGeneratorScreen(access: access),
        );

      // Pantallas temporales para rutas que aún no están implementadas
      case '/inspection/list':
      case '/inspection/detail':
      case '/inspection/new':
      case '/reports/list':
      case '/reports/view':
      case '/settings':
      case '/settings/profile':
      case '/settings/warehouses':
        // Pantalla temporal para rutas no implementadas
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text('${settings.name} - En desarrollo'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.construction,
                    size: 64,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'La pantalla ${settings.name} está en desarrollo',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(_).pop(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Ruta no encontrada'),
            ),
            body: Center(
              child: Text('No se encontró la ruta: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
