import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

//===============
class AppColors {
  // — Brand / Accent
  static const Color accent = Color(0xFF00FF88);
  static const Color accentDim = Color(0xFF00CC6A);
  static const Color accentGlow = Color(0x1A00FF88);

  /// Warna biru utama semua page (button, badge, highlight)
  static const Color brandBlue = Color(0xFF3B82F6);
  static const Color brandBlueDark = Color(0xFF2563EB);
  static const Color brandBlueGlow = Color(0x1A3B82F6);
  static const Color brandBlueSoft = Color(0xFFEFF6FF); // light mode glow
  static const Color brandBluePing = Color(0xFF60A5FA); // ping dot ring

  static const Color accentBlue = Color(0xFF4DAAFF);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPurple = Color(0xFF9D6FFF);
  static const Color accentOrange = Color(0xFFFF8C42);
  static const Color accentRed = Color(0xFFFF4D6D);

  // — Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFF43F5E);

  // — Dark theme
  static const Color darkBackground = Color(0xFF0B0B0B);
  static const Color darkCard = Color(0xFF111111);

  /// border card dark: 0x1A = 10% opacity white
  static const Color darkCardBorder = Color(0x1AFFFFFF);

  /// border card dark versi lebih tipis: 0x0D = 5% opacity white
  static const Color darkCardBorderSubtle = Color(0x0DFFFFFF);

  static const Color darkSurface = Color(0xFF161616);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);

  /// secondary text dark (label, hint)
  static const Color darkTextSecondary = Color(0xFFA1A1AA);

  static const Color darkTextMuted = Color(0xFF4A4A5A);

  /// warna dot terminal dark
  static const Color darkDot = Color(0xFF3F3F46);

  // — Light theme
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFCFCFC);

  /// border card light: 0x1A = 10% opacity black
  static const Color lightCardBorder = Color(0x1A000000);

  /// border card light versi lebih tipis: 0x0D = 5% opacity black
  static const Color lightCardBorderSubtle = Color(0x0D000000);

  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color lightTextPrimary = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF71717A);
  static const Color lightTextMuted = Color(0xFFA1A1AA);

  /// warna dot terminal light
  static const Color lightDot = Color(0xFFD4D4D8);

  // — Gradient
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00FF88), Color(0xFF00CCFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [brandBlue, Color(0xFF22D3EE)],
  );
}

//===============
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandBlue,
      ),
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandBlue,
        secondary: AppColors.accentBlue,
        surface: AppColors.darkCard,
        error: Color(0xFFF43F5E), // Langsung pakai Hex merah bawaan
        onPrimary: AppColors.darkBackground,
        onSecondary: AppColors.darkTextPrimary,
        onSurface: AppColors.darkTextPrimary,
      ),
      textTheme: _buildTextTheme(
        primary: AppColors.darkTextPrimary,
        secondary: AppColors.darkTextSecondary,
        muted: AppColors.darkTextMuted,
      ),
      appBarTheme: _buildAppBarTheme(
        bg: AppColors.darkBackground,
        text: AppColors.darkTextPrimary,
        isDark: true,
      ),
      cardTheme: _buildCardTheme(AppColors.darkCard, AppColors.darkCardBorder),
      inputDecorationTheme: _buildInputTheme(
        surface: AppColors.darkSurface,
        border: AppColors.darkCardBorder,
        muted: AppColors.darkTextMuted,
        secondary: AppColors.darkTextSecondary,
      ),
    );
  }

  //===============
  static ThemeData get lightTheme {
    return ThemeData(
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandBlue,
      ),
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandBlue,
        secondary: AppColors.accentBlue,
        surface: AppColors.lightCard,
        error: Color(0xFFF43F5E), // Langsung pakai Hex merah bawaan
        onPrimary: AppColors.lightBackground,
        onSecondary: AppColors.lightTextPrimary,
        onSurface: AppColors.lightTextPrimary,
      ),
      textTheme: _buildTextTheme(
        primary: AppColors.lightTextPrimary,
        secondary: AppColors.lightTextSecondary,
        muted: AppColors.lightTextMuted,
      ),
      appBarTheme: _buildAppBarTheme(
        bg: AppColors.lightBackground,
        text: AppColors.lightTextPrimary,
        isDark: false,
      ),
      cardTheme: _buildCardTheme(AppColors.lightCard, AppColors.lightCardBorder),
      inputDecorationTheme: _buildInputTheme(
        surface: AppColors.lightSurface,
        border: AppColors.lightCardBorder,
        muted: AppColors.lightTextMuted,
        secondary: AppColors.lightTextSecondary,
      ),
    );
  }

  //===============
  static TextTheme _buildTextTheme({
    required Color primary,
    required Color secondary,
    required Color muted,
  }) {
    return TextTheme(
      displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: primary),
      displayMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: primary),
      displaySmall: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
      headlineLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: secondary),
      bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: muted),
      labelLarge: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF00FF88)), // Manual local hex
      labelMedium: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelSmall: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w400, color: muted),
    );
  }

  //===============
  static AppBarTheme _buildAppBarTheme({
    required Color bg,
    required Color text,
    required bool isDark,
  }) {
    return AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: text, letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: text),
    );
  }

  //===============
  static CardTheme _buildCardTheme(Color card, Color border) {
    return CardTheme(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border, width: 1),
      ),
      margin: EdgeInsets.zero,
    );
  }

  //===============
  static InputDecorationTheme _buildInputTheme({
    required Color surface,
    required Color border,
    required Color muted,
    required Color secondary,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF43F5E)), // Manual local hex
      ),
      hintStyle: GoogleFonts.poppins(color: muted, fontSize: 13),
      labelStyle: GoogleFonts.poppins(color: secondary, fontSize: 13),
    );
  }
}
