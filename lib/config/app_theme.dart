import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF2E7D32); // Green for plant theme
  static const _secondaryColor = Color(0xFF81C784);
  static const _tertiaryColor = Color(0xFF4CAF50);
  static const _errorColor = Color(0xFFBA1A1A);

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFA5D6A7),
      onPrimaryContainer: Color(0xFF002106),
      secondary: _secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFC8E6C9),
      onSecondaryContainer: Color(0xFF003822),
      tertiary: _tertiaryColor,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFDCEDC8),
      onTertiaryContainer: Color(0xFF0A1F0A),
      error: _errorColor,
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFFCFCFC),
      onSurface: Color(0xFF1A1C1A),
      surfaceContainerHighest: Color(0xFFE0E3DE),
      onSurfaceVariant: Color(0xFF43483F),
      outline: Color(0xFF73796E),
      outlineVariant: Color(0xFFC3C7BE),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF2F312E),
      onInverseSurface: Color(0xFFF0F1EC),
      inversePrimary: Color(0xFF81C784),
    ),
    // Card theme
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    // AppBar theme
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 3,
    ),
    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorColor, width: 2),
      ),
    ),
    // Chip theme
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    // Dialog theme
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    // Floating action button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF81C784),
      onPrimary: Color(0xFF003A08),
      primaryContainer: Color(0xFF1B5E20),
      onPrimaryContainer: Color(0xFFA5D6A7),
      secondary: Color(0xFFA5D6A7),
      onSecondary: Color(0xFF003822),
      secondaryContainer: Color(0xFF2E7D32),
      onSecondaryContainer: Color(0xFFC8E6C9),
      tertiary: Color(0xFFAED581),
      onTertiary: Color(0xFF1A3818),
      tertiaryContainer: Color(0xFF2E5F2E),
      onTertiaryContainer: Color(0xFFDCEDC8),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF1A1C1A),
      onSurface: Color(0xFFE2E3DE),
      surfaceContainerHighest: Color(0xFF43483F),
      onSurfaceVariant: Color(0xFFC3C7BE),
      outline: Color(0xFF8D9388),
      outlineVariant: Color(0xFF43483F),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE2E3DE),
      onInverseSurface: Color(0xFF2F312E),
      inversePrimary: _primaryColor,
    ),
    // Card theme
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    // AppBar theme
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 3,
    ),
    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF81C784), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 2),
      ),
    ),
    // Chip theme
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    // Dialog theme
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    // Floating action button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}