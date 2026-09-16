import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DigiRoutes brand design system — mirrors the web's orange/dark theme exactly.
class AppTheme {
  // ─── Brand Colours ────────────────────────────────────────────────────────
  static const Color orange      = Color(0xFFF97316);
  static const Color orangeDark  = Color(0xFFEA6C0A);
  static const Color orangeLight = Color(0xFFFB923C);
  static const Color orangeGlow  = Color(0x40F97316);
  static const Color orangeSubtle= Color(0x1AF97316);

  // Dark palette
  static const Color darkBg      = Color(0xFF1A1A1A);
  static const Color darkBg2     = Color(0xFF111111);
  static const Color darkSurface = Color(0xFF242424);
  static const Color darkSurface2= Color(0xFF2E2E2E);
  static const Color darkBorder  = Color(0x17FFFFFF);
  static const Color darkText    = Color(0xFFF0F0F0);
  static const Color darkTextSec = Color(0xFFC0C0C0);
  static const Color darkMuted   = Color(0xFF888888);

  // Light palette
  static const Color lightBg      = Color(0xFFFFFFFF);
  static const Color lightBg2     = Color(0xFFF8F8F8);
  static const Color lightSurface = Color(0xFFF2F2F2);
  static const Color lightSurface2= Color(0xFFE8E8E8);
  static const Color lightBorder  = Color(0x17000000);
  static const Color lightText    = Color(0xFF1A1A1A);
  static const Color lightTextSec = Color(0xFF444444);
  static const Color lightMuted   = Color(0xFF777777);

  static const Color danger  = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color info    = Color(0xFF3B82F6);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, orangeLight],
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkBg, darkBg2],
  );

  // ─── Shared decorations ────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({bool dark = true}) => BoxDecoration(
    color: dark ? darkSurface : lightSurface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: dark ? darkBorder : lightBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(dark ? 0.35 : 0.08),
        blurRadius: dark ? 24 : 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration glowDecoration({bool dark = true}) => BoxDecoration(
    color: dark ? darkSurface : lightSurface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: orangeGlow, width: 1),
    boxShadow: [
      BoxShadow(color: orangeGlow, blurRadius: 32, spreadRadius: 0),
    ],
  );

  // ─── Dark ThemeData ────────────────────────────────────────────────────────
  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: orange,
        onPrimary: Colors.white,
        secondary: orangeLight,
        surface: darkSurface,
        error: danger,
      ),
      scaffoldBackgroundColor: darkBg,
      cardColor: darkSurface,
      dividerColor: darkBorder,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkText,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: orange,
          side: const BorderSide(color: orange),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: GoogleFonts.outfit(color: darkMuted),
        hintStyle: GoogleFonts.outfit(color: darkMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface2,
        labelStyle: GoogleFonts.outfit(color: darkText, fontSize: 13),
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: orange,
        unselectedItemColor: darkMuted,
        elevation: 0,
      ),
    );
  }

  // ─── Light ThemeData ───────────────────────────────────────────────────────
  static ThemeData light() {
    final base = ThemeData.light();
    return base.copyWith(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: orange,
        onPrimary: Colors.white,
        secondary: orangeLight,
        surface: lightSurface,
        error: danger,
      ),
      scaffoldBackgroundColor: lightBg,
      cardColor: lightSurface,
      dividerColor: lightBorder,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: lightText,
        displayColor: lightText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: lightText,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: orange,
          side: const BorderSide(color: orange),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: GoogleFonts.outfit(color: lightMuted),
        hintStyle: GoogleFonts.outfit(color: lightMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: orange,
        unselectedItemColor: lightMuted,
        elevation: 0,
      ),
    );
  }
}
