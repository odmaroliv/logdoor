import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'config/localization.dart';
import 'core/services/auth_service.dart';
import 'core/services/offline_sync_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/access_control/providers/access_provider.dart';
import 'features/inspections/providers/inspection_provider.dart';
import 'features/reports/providers/report_provider.dart';
import 'features/settings/providers/settings_provider.dart';

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

        // Configuración de localización
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: LocalizationService.supportedLocales,
        localeResolutionCallback: LocalizationService.localeResolutionCallback,

        initialRoute: '/',
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
