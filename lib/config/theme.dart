import 'package:flutter/material.dart';

// Tema claro (original modificado)
final ThemeData appLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1A5276),
    brightness: Brightness.light,
  ),
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Color(0xFF1A5276),
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      backgroundColor: const Color(0xFF1A5276),
      foregroundColor: Colors.white,
    ),
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    filled: true,
    fillColor: Colors.grey[50],
  ),
);

// Tema oscuro
final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1A5276),
    brightness: Brightness.dark,
  ),
  fontFamily: 'Roboto',
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.grey[900],
    foregroundColor: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  cardColor: const Color(0xFF1E1E1E),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      backgroundColor: const Color(0xFF2980B9),
      foregroundColor: Colors.white,
    ),
  ),
  cardTheme: CardTheme(
    elevation: 2,
    color: const Color(0xFF1E1E1E),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    filled: true,
    fillColor: const Color(0xFF2D2D2D),
  ),
  dialogBackgroundColor: const Color(0xFF1E1E1E),
  dividerColor: Colors.grey[800],
);

// Variable de compatibilidad para código existente
final ThemeData appTheme = appLightTheme;
