import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- STUDIO COLORS ---
  static const Color obsidian = Color(0xFF030712); // Deep Rich Black
  static const Color deepSlate = Color(0xFF0F172A); // Midnight Grey
  static const Color slate = Color(0xFF1F2937); // Component Surface
  static const Color violet = Color(0xFF2563EB); // Elegant Sapphire Blue instead of Purple
  static const Color violetLight = Color(0xFF60A5FA);

  // Aliases for compatibility
  static const Color gold = Color(0xFF2563EB); // Reuse primary alias
  static const Color accent = Color(0xFF60A5FA);
  static const Color alert = Color(0xFFEF4444);
  static const Color charcoal = Color(0xFF64748B);
  static const Color coolGrey = Color(0xFFF8FAFC);
  static const Color ebony = obsidian;

  // --- LIGHT STUDIO REFINEMENTS ---
  static const Color studioGrey = Color(0xFFF8FAFC); // Clean, Premium Grey
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSecond = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidian,
      primaryColor: violet,
      colorScheme: const ColorScheme.dark(
        primary: violet,
        secondary: violetLight,
        surface: deepSlate,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      cardTheme: CardThemeData(
        color: deepSlate,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: obsidian,
        selectedItemColor: violet,
        unselectedItemColor: Colors.white38,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: studioGrey,
      primaryColor: violet,
      colorScheme: const ColorScheme.light(
        primary: violet,
        secondary: textSecond,
        surface: Colors.white,
        onSurface: textMain,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme,
      ).apply(bodyColor: textSecond, displayColor: textMain),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: const Color(0xFFE2E8F0),
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: violet,
        unselectedItemColor: textSecond.withValues(alpha: 0.4),
      ),
    );
  }
}
