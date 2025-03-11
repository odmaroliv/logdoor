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
import '../features/inspections/screens/inspection_list_screen.dart';
import '../features/inspections/screens/inspection_form_screen.dart';
import '../features/inspections/screens/inspection_detail_screen.dart';
import '../features/reports/screens/report_list_screen.dart';
import '../features/reports/screens/report_viewer_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/profile_screen.dart';
import '../features/settings/screens/warehouse_settings_screen.dart';
import '../core/models/access.dart';
import '../core/models/inspection.dart';

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

      case '/inspection/list':
        return MaterialPageRoute(builder: (_) => const InspectionListScreen());

      case '/inspection/new':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => InspectionFormScreen(
            accessCode: args?['accessCode'],
          ),
        );

      case '/inspection/detail':
        final args = settings.arguments as Map<String, dynamic>;
        final inspectionId = args['inspectionId'] as String;
        return MaterialPageRoute(
          builder: (_) => InspectionDetailScreen(
            inspectionId: inspectionId,
          ),
        );

      case '/reports/list':
        return MaterialPageRoute(builder: (_) => const ReportListScreen());

      case '/reports/view':
        final args = settings.arguments as Map<String, dynamic>;
        final reportId = args['reportId'] as String;
        return MaterialPageRoute(
          builder: (_) => ReportViewerScreen(
            reportId: reportId,
          ),
        );

      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case '/settings/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case '/settings/warehouses':
        return MaterialPageRoute(
            builder: (_) => const WarehouseSettingsScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No se encontró la ruta: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
