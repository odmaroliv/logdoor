// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'core/services/offline_sync_service.dart';
import 'core/services/auth_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/access_control/providers/access_provider.dart';
import 'features/inspections/providers/inspection_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/admin_dashboard.dart';
import 'features/dashboard/screens/inspector_dashboard.dart';
import 'features/dashboard/screens/guard_dashboard.dart';
import 'features/access_control/screens/access_list_screen.dart';
import 'features/access_control/screens/access_form_screen.dart';
import 'features/access_control/screens/qr_scanner_screen.dart';
import 'features/access_control/screens/qr_generator_screen.dart';
import 'features/inspections/screens/inspection_list_screen.dart';
import 'features/inspections/screens/inspection_form_screen.dart';
import 'features/inspections/screens/inspection_detail_screen.dart';
import 'features/reports/screens/report_list_screen.dart';
import 'features/reports/screens/report_viewer_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/profile_screen.dart';
import 'features/settings/screens/warehouse_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicios
  final offlineSyncService = OfflineSyncService();
  await offlineSyncService.init();

  // Establecer orientación preferida
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const LogdoorApp());
}

class LogdoorApp extends StatelessWidget {
  const LogdoorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AccessProvider()),
        ChangeNotifierProvider(create: (_) => InspectionProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Logdoor',
        theme: appTheme,
        home: const AuthGuard(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard/admin': (context) => const AdminDashboard(),
          '/dashboard/inspector': (context) => const InspectorDashboard(),
          '/dashboard/guard': (context) => const GuardDashboard(),
          '/access/list': (context) => const AccessListScreen(),
          '/access/new': (context) => const AccessFormScreen(),
          '/access/scan': (context) => const QrScannerScreen(),
          '/inspection/list': (context) => const InspectionListScreen(),
          '/inspection/detail': (context) => const InspectionDetailScreen(),
          '/reports/list': (context) => const ReportListScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/settings/profile': (context) => const ProfileScreen(),
          '/settings/warehouses': (context) => const WarehouseSettingsScreen(),
        },
        onGenerateRoute: (settings) {
          // Rutas que requieren argumentos específicos
          if (settings.name == '/access/qr') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => QrGeneratorScreen(
                access: args['access'],
              ),
            );
          } else if (settings.name == '/inspection/new') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => InspectionFormScreen(
                accessCode: args?['accessCode'],
              ),
            );
          } else if (settings.name == '/reports/view') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ReportViewerScreen(
                reportId: args['reportId'],
              ),
            );
          }

          // Ruta por defecto
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(
                child: Text('Ruta no encontrada'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AuthGuard extends StatelessWidget {
  const AuthGuard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return FutureBuilder<bool>(
      future: authProvider.checkAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          // Si el usuario está autenticado, redirigir basado en su rol
          if (authProvider.currentUser != null) {
            if (authProvider.currentUser!.isAdmin) {
              return const AdminDashboard();
            } else if (authProvider.currentUser!.isInspector) {
              return const InspectorDashboard();
            } else if (authProvider.currentUser!.isGuard) {
              return const GuardDashboard();
            } else {
              return const AccessListScreen();
            }
          }
        }

        // Si no está autenticado, mostrar pantalla de login
        return const LoginScreen();
      },
    );
  }
}
