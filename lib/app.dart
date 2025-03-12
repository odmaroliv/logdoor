// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'config/localization.dart';
import 'core/services/auth_service.dart';
import 'core/services/offline_sync_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/access_control/providers/access_provider.dart';
import 'features/inspections/providers/inspection_provider.dart';
import 'features/reports/providers/report_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/admin_dashboard.dart';
import 'features/dashboard/screens/inspector_dashboard.dart';
import 'features/dashboard/screens/guard_dashboard.dart';
import 'features/access_control/screens/access_list_screen.dart';

class LogdoorApp extends StatefulWidget {
  const LogdoorApp({Key? key}) : super(key: key);

  @override
  State<LogdoorApp> createState() => _LogdoorAppState();
}

class _LogdoorAppState extends State<LogdoorApp> {
  Locale _appLocale = LocalizationService.defaultLocale;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    // Inicializar servicios
    await OfflineSyncService().init();
    await NotificationService().init();

    // Establecer orientación preferida
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Cargar preferencias de idioma
    final locale = await LocalizationService.getPreferredLocale();

    if (mounted) {
      setState(() {
        _appLocale = locale;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AccessProvider()),
        ChangeNotifierProvider(create: (_) => InspectionProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Logdoor',
        theme: appTheme,
        locale: _appLocale,
        home: const AuthGuard(),

        // Configuración de localización
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: LocalizationService.supportedLocales,
        localeResolutionCallback: LocalizationService.localeResolutionCallback,

        // Usar el sistema de rutas definido
        initialRoute: '/',
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}

class AuthGuard extends StatelessWidget {
  const AuthGuard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // No obtengas el provider aquí, solo construye el FutureBuilder
    return FutureBuilder<bool>(
      // Obten el provider directamente dentro del future
      future: Provider.of<AuthProvider>(context, listen: false).checkAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          // Usa el Provider.of con listen:false para evitar reconstrucciones
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
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
