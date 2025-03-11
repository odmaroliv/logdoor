import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String languagePreferenceKey = 'app_language';
  static const Locale defaultLocale = Locale('es', '');

  // Obtener las traducciones actuales basadas en el contexto
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations.of(context)!;
  }

  // Lista de idiomas soportados
  static final List<Locale> supportedLocales = [
    const Locale('es', ''), // Español
    const Locale('en', ''), // Inglés
  ];

  // Delegados de localización
  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizations.delegate;

  // Determinar el locale basado en el dispositivo o preferencia guardada
  static Locale? localeResolutionCallback(
      Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null) {
      return defaultLocale;
    }

    // Verificar si es un idioma soportado
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }

    // Si no hay coincidencia, usar el idioma por defecto
    return defaultLocale;
  }

  // Cambiar el idioma de la aplicación
  static Future<void> changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languagePreferenceKey, languageCode);
  }

  // Obtener el idioma guardado
  static Future<Locale> getPreferredLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(languagePreferenceKey);

    if (savedLanguage != null) {
      for (var locale in supportedLocales) {
        if (locale.languageCode == savedLanguage) {
          return locale;
        }
      }
    }

    return defaultLocale;
  }

  // Obtener el nombre del idioma para mostrar
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return 'Español';
    }
  }
}
