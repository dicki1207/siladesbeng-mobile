import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Warna Dasar Terang (Light Mode) ---
  static const Color primaryLight = Color(0xFF2FA2F1);
  static const Color secondaryLight = Color(0xFF6DC4F7);
  static const Color bgLight = Color(0xFFF1F8FF);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrayLight = Color(0xFF64748B);
  static const Color cardLight = Colors.white;

  // --- Warna Dasar Gelap (Dark Mode) ---
  static const Color primaryDark = Color(0xFF1E88E5);
  static const Color bgDark = Color(0xFF0F172A); // Navy blue pekat elegan
  static const Color cardDark = Color(0xFF1E293B); // Navy sedikit lebih terang
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textGrayDark = Color(0xFF94A3B8);

  // Gradient
  static const LinearGradient mainGradientLight = LinearGradient(
    colors: [primaryLight, bgLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.4],
  );

  static const LinearGradient mainGradientDark = LinearGradient(
    colors: [Color(0xFF1E293B), bgDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.4],
  );

  // --- Tema Terang ---
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: bgLight,
      cardColor: cardLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryLight,
        brightness: Brightness.light,
        surface: bgLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textGrayLight,
        ),
      ),
    );
  }

  // --- Tema Gelap ---
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: bgDark,
      cardColor: cardDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryDark,
        brightness: Brightness.dark,
        surface: bgDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: textLight),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textLight,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textLight,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textGrayDark,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardDark,
        selectedItemColor: primaryDark,
        unselectedItemColor: textGrayDark,
      ),
    );
  }

  // Backwards compatibility untuk Gradient (karena gradient butuh BuildContext untuk cek brightness)
  static LinearGradient getGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? mainGradientDark
        : mainGradientLight;
  }
}
