import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DigiRoutes brand design system — a glassy, frosted look with an orange
/// accent, fully adaptive across light and dark mode. Screens should never
/// hardcode a `dark*`/`light*` constant directly for text/surface/border —
/// use the context-aware helpers below (or plain `Theme.of(context)`) so
/// every screen follows whichever mode is active.
class AppTheme {
  // ─── Brand Colours ────────────────────────────────────────────────────────
  static const Color orange      = Color(0xFFF97316);
  static const Color orangeDark  = Color(0xFFEA6C0A);
  static const Color orangeLight = Color(0xFFFB923C);
  static const Color orangeGlow  = Color(0x40F97316);
  static const Color orangeSubtle= Color(0x1AF97316);

  // Dark palette
  static const Color darkBg      = Color(0xFF15151A);
  static const Color darkBg2     = Color(0xFF0D0D10);
  static const Color darkSurface = Color(0xFF1E1E24);
  static const Color darkSurface2= Color(0xFF28282F);
  static const Color darkBorder  = Color(0x1EFFFFFF);
  static const Color darkText    = Color(0xFFF3F3F5);
  static const Color darkTextSec = Color(0xFFB8B8C0);
  static const Color darkMuted   = Color(0xFF87878F);

  // Light palette — soft warm off-white, never stark #FFFFFF
  static const Color lightBg      = Color(0xFFF7F6F3);
  static const Color lightBg2     = Color(0xFFEFEEEA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2= Color(0xFFF1F0EC);
  static const Color lightBorder  = Color(0x14000000);
  static const Color lightText    = Color(0xFF1C1C1E);
  static const Color lightTextSec = Color(0xFF54545C);
  static const Color lightMuted   = Color(0xFF87878F);

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

  static const LinearGradient lightBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightBg, lightBg2],
  );

  // ─── Context-aware helpers ──────────────────────────────────────────────
  // Prefer these over the raw dark*/light* constants in every screen so
  // colours always follow the active ThemeMode.
  static bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
  static Color bgColor(BuildContext c) => _isDark(c) ? darkBg : lightBg;
  static Color textColor(BuildContext c) => _isDark(c) ? darkText : lightText;
  static Color textSecColor(BuildContext c) => _isDark(c) ? darkTextSec : lightTextSec;
  static Color mutedColor(BuildContext c) => _isDark(c) ? darkMuted : lightMuted;
  static Color surfaceColor(BuildContext c) => _isDark(c) ? darkSurface : lightSurface;
  static Color surface2Color(BuildContext c) => _isDark(c) ? darkSurface2 : lightSurface2;
  static Color borderColor(BuildContext c) => _isDark(c) ? darkBorder : lightBorder;

  // ─── Shared decorations ────────────────────────────────────────────────────
  static BoxDecoration cardDecoration(BuildContext context) {
    final dark = _isDark(context);
    return BoxDecoration(
      color: (dark ? darkSurface : Colors.white).withOpacity(dark ? 0.7 : 0.85),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: dark ? darkBorder : lightBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(dark ? 0.35 : 0.06),
          blurRadius: dark ? 24 : 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration glowDecoration(BuildContext context) {
    final dark = _isDark(context);
    return BoxDecoration(
      color: (dark ? darkSurface : Colors.white).withOpacity(dark ? 0.7 : 0.85),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: orangeGlow, width: 1),
      boxShadow: const [
        BoxShadow(color: orangeGlow, blurRadius: 32, spreadRadius: 0),
      ],
    );
  }

  // ─── Shared InputDecorationTheme builder ──────────────────────────────────
  static InputDecorationTheme _inputTheme({required bool dark}) {
    final muted = dark ? darkMuted : lightMuted;
    final fill = dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.032);
    final radius = BorderRadius.circular(14);
    OutlineInputBorder side(Color c, double w) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c, width: w));
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      isDense: true,
      border: side(Colors.transparent, 0),
      enabledBorder: side(Colors.transparent, 0),
      disabledBorder: side(Colors.transparent, 0),
      focusedBorder: side(orange, 1.6),
      errorBorder: side(danger.withOpacity(0.7), 1.2),
      focusedErrorBorder: side(danger, 1.6),
      prefixIconColor: muted,
      suffixIconColor: muted,
      iconColor: muted,
      labelStyle: GoogleFonts.outfit(color: muted, fontSize: 14),
      floatingLabelStyle: GoogleFonts.outfit(color: orange, fontWeight: FontWeight.w600),
      hintStyle: GoogleFonts.outfit(color: muted.withOpacity(0.8), fontSize: 14),
      errorStyle: GoogleFonts.outfit(color: danger, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ─── Dark ThemeData ────────────────────────────────────────────────────────
  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: orange,
        onPrimary: Colors.white,
        secondary: orangeLight,
        surface: darkSurface,
        onSurface: darkText,
        error: danger,
      ),
      scaffoldBackgroundColor: darkBg,
      cardColor: darkSurface,
      dividerColor: darkBorder,
      hintColor: darkMuted,
      splashColor: orange.withOpacity(0.12),
      highlightColor: orange.withOpacity(0.06),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),
      iconTheme: const IconThemeData(color: darkTextSec),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkText),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkText,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: orange.withOpacity(0.35),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: orange,
          side: const BorderSide(color: orange),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkTextSec,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: _inputTheme(dark: true),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface2,
        labelStyle: GoogleFonts.outfit(color: darkText, fontSize: 13),
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
            color: darkText, fontWeight: FontWeight.w700, fontSize: 18),
        contentTextStyle: GoogleFonts.outfit(color: darkTextSec, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurface2,
        contentTextStyle: GoogleFonts.outfit(color: darkText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: orange,
        unselectedItemColor: darkMuted,
        elevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? orangeSubtle : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? orange : darkTextSec),
          side: WidgetStateProperty.all(const BorderSide(color: darkBorder)),
        ),
      ),
    );
  }

  // ─── Light ThemeData ───────────────────────────────────────────────────────
  static ThemeData light() {
    final base = ThemeData.light();
    return base.copyWith(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: orange,
        onPrimary: Colors.white,
        secondary: orangeLight,
        surface: lightSurface,
        onSurface: lightText,
        error: danger,
      ),
      scaffoldBackgroundColor: lightBg,
      cardColor: lightSurface,
      dividerColor: lightBorder,
      hintColor: lightMuted,
      splashColor: orange.withOpacity(0.10),
      highlightColor: orange.withOpacity(0.05),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: lightText,
        displayColor: lightText,
      ),
      iconTheme: const IconThemeData(color: lightTextSec),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: lightText),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: lightText,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: orange.withOpacity(0.35),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: orange,
          side: const BorderSide(color: orange),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightTextSec,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: _inputTheme(dark: false),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface2,
        labelStyle: GoogleFonts.outfit(color: lightText, fontSize: 13),
        side: const BorderSide(color: lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
            color: lightText, fontWeight: FontWeight.w700, fontSize: 18),
        contentTextStyle: GoogleFonts.outfit(color: lightTextSec, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightText,
        contentTextStyle: GoogleFonts.outfit(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: orange,
        unselectedItemColor: lightMuted,
        elevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? orangeSubtle : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? orange : lightTextSec),
          side: WidgetStateProperty.all(const BorderSide(color: lightBorder)),
        ),
      ),
    );
  }
}
