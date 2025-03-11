// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/services/offline_sync_service.dart';
import 'core/utils/logger.dart';

void main() async {
  // Asegurarse de que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Capturar errores no manejados
    FlutterError.onError = (FlutterErrorDetails details) {
      Logger.error('Error no manejado:',
          error: details.exception, stackTrace: details.stack);
      FlutterError.presentError(details);
    };

    // Ejecutar la aplicación
    runApp(const LogdoorApp());
  } catch (e, stackTrace) {
    Logger.error('Error fatal durante la inicialización:',
        error: e, stackTrace: stackTrace);
  }
}
