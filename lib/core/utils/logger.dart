import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;

  Logger._internal();

  static bool _initialized = false;
  static late File _logFile;
  static const int _maxLogSizeBytes = 5 * 1024 * 1024; // 5 MB

  static Future<void> _initializeLogger() async {
    if (_initialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/logdoor_logs.txt';
      _logFile = File(filePath);

      // Verificar tamaño del archivo y rotarlo si es necesario
      if (await _logFile.exists()) {
        if ((await _logFile.length()) > _maxLogSizeBytes) {
          // Crear archivo de respaldo y limpiar el actual
          final backupFilePath =
              '${directory.path}/logdoor_logs_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
          await _logFile.copy(backupFilePath);
          await _logFile.writeAsString(''); // Limpiar archivo
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing logger: $e');
    }
  }

  static Future<void> _writeToFile(String message) async {
    if (!_initialized) await _initializeLogger();

    try {
      await _logFile.writeAsString('$message\\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Error writing to log file: $e');
    }
  }

  static String _formatLogMessage(LogLevel level, String message) {
    final timestamp =
        DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final levelStr = level.toString().split('.').last.toUpperCase();
    return '[$timestamp] $levelStr: $message';
  }

  static void debug(String message) {
    final formattedMessage = _formatLogMessage(LogLevel.debug, message);
    debugPrint(formattedMessage);
    if (!kDebugMode) return; // Solo escribir en archivo en debug mode
    _writeToFile(formattedMessage);
  }

  static void info(String message) {
    final formattedMessage = _formatLogMessage(LogLevel.info, message);
    debugPrint(formattedMessage);
    _writeToFile(formattedMessage);
  }

  static void warning(String message) {
    final formattedMessage = _formatLogMessage(LogLevel.warning, message);
    debugPrint(formattedMessage);
    _writeToFile(formattedMessage);
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    final formattedMessage = _formatLogMessage(LogLevel.error, message);
    final errorDetails = error != null ? '\\nError: $error' : '';
    final stackDetails =
        stackTrace != null ? '\\nStack trace: $stackTrace' : '';

    debugPrint('$formattedMessage$errorDetails$stackDetails');
    _writeToFile('$formattedMessage$errorDetails$stackDetails');
  }

  // Método para obtener los logs para compartir
  static Future<String> getLogs() async {
    if (!_initialized) await _initializeLogger();

    try {
      if (await _logFile.exists()) {
        return await _logFile.readAsString();
      }
      return 'No hay logs disponibles';
    } catch (e) {
      return 'Error al leer logs: $e';
    }
  }

  // Método para limpiar logs
  static Future<void> clearLogs() async {
    if (!_initialized) await _initializeLogger();

    try {
      if (await _logFile.exists()) {
        await _logFile.writeAsString('');
      }
    } catch (e) {
      debugPrint('Error clearing logs: $e');
    }
  }
}
