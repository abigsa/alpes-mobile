import 'package:flutter/material.dart';

class AlpesColors {
  static const cafeOscuro    = Color(0xFF2C1810);
  static const nogalMedio    = Color(0xFF8B6F47);
  static const arenaCalida   = Color(0xFFC4A882);
  static const cremaFondo    = Color(0xFFF7F3EE);
  static const verdeSelva    = Color(0xFF1A3A2A);
  static const oroGuatemalteco = Color(0xFFD4A853);
  static const rojoColonial    = Color(0xFF8B2E2E);
  static const pergamino       = Color(0xFFE8E0D5);
  static const grafito         = Color(0xFF4A4A4A);
  static const exito   = Color(0xFF2E7D32);
  static const error   = Color(0xFF8B2E2E);
  static const aviso   = Color(0xFFD4A853);
  static const info    = Color(0xFF1A3A2A);
}

class AlpesTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AlpesColors.cremaFondo,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary:        AlpesColors.cafeOscuro,
      onPrimary:      AlpesColors.cremaFondo,
      primaryContainer: AlpesColors.nogalMedio,
      onPrimaryContainer: AlpesColors.cremaFondo,
      secondary:      AlpesColors.oroGuatemalteco,
      onSecondary:    AlpesColors.cafeOscuro,
      secondaryContainer: AlpesColors.pergamino,
      onSecondaryContainer: AlpesColors.cafeOscuro,
      tertiary:       AlpesColors.verdeSelva,
      onTertiary:     AlpesColors.cremaFondo,
      error:          AlpesColors.rojoColonial,
      onError:        Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: AlpesColors.rojoColonial,
      surface:        Colors.white,
      onSurface:      AlpesColors.grafito,
      surfaceContainerHighest: AlpesColors.pergamino,
      outline:        AlpesColors.arenaCalida,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AlpesColors.cafeOscuro,
      foregroundColor: AlpesColors.cremaFondo,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AlpesColors.cremaFondo, letterSpacing: 1.2,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AlpesColors.cafeOscuro,
        foregroundColor: AlpesColors.cremaFondo,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.8),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AlpesColors.cafeOscuro,
        side: const BorderSide(color: AlpesColors.cafeOscuro, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AlpesColors.nogalMedio,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AlpesColors.arenaCalida),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AlpesColors.arenaCalida),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AlpesColors.cafeOscuro, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AlpesColors.rojoColonial),
      ),
      labelStyle: const TextStyle(color: AlpesColors.nogalMedio),
      hintStyle: const TextStyle(color: AlpesColors.arenaCalida),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(color: AlpesColors.pergamino, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: AlpesColors.pergamino,
      selectedColor: AlpesColors.cafeOscuro,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AlpesColors.cafeOscuro,
      unselectedItemColor: AlpesColors.arenaCalida,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    textTheme: const TextTheme(
      headlineLarge:  TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AlpesColors.cafeOscuro),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AlpesColors.cafeOscuro),
      headlineSmall:  TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AlpesColors.cafeOscuro),
      titleLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AlpesColors.cafeOscuro),
      titleMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AlpesColors.grafito),
      titleSmall:     TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AlpesColors.grafito),
      bodyLarge:      TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AlpesColors.grafito),
      bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AlpesColors.grafito),
      bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AlpesColors.nogalMedio),
      labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AlpesColors.cafeOscuro),
    ),
  );
}
