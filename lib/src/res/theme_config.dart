import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemeConfig {
  // Font sizes
  static const double titleFontSize = 20.0;
  static const double bodyFontSize = 14.0;
  static const double smallFontSize = 12.0;

  // Light theme (matching your current theme)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: Colors.grey.shade700,
        secondary: Colors.grey,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black87,
        // Removed deprecated background and onBackground
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.poppins(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: bodyFontSize,
          color: Colors.black87,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: smallFontSize,
          color: Colors.black54,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.grey.shade900,
        selectionColor: Colors.grey.shade900.withAlpha(24),
        selectionHandleColor: Colors.grey.shade400,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 52,
      ),
      iconTheme: IconThemeData(color: Colors.grey.shade700, size: 20),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.grey.shade800;
          }
          if (states.contains(WidgetState.dragged)) {
            return Colors.grey.shade900;
          }
          return Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        thickness: WidgetStateProperty.all(8.0),
        radius: const Radius.circular(12.0),
        thumbVisibility: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.dragged) ||
              states.contains(WidgetState.scrolledUnder)) {
            return true;
          }
          return false;
        }),
        trackVisibility: WidgetStateProperty.all(false),
        crossAxisMargin: 2.0,
        mainAxisMargin: 8.0,
        interactive: true,
      ),
      // Add bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.grey.shade700,
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: Colors.grey.shade300,
        secondary: Colors.grey.shade600,
        onPrimary: Colors.white,
        surface: Colors.grey.shade900,
        onSurface: Colors.white,
        // Removed deprecated background and onBackground
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.poppins(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: bodyFontSize,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: smallFontSize,
          color: Colors.white70,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.white,
        selectionColor: Colors.white.withAlpha(24),
        selectionHandleColor: Colors.grey.shade400,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 52,
      ),
      iconTheme: IconThemeData(color: Colors.white, size: 20),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.grey.shade400;
          }
          if (states.contains(WidgetState.dragged)) {
            return Colors.grey.shade300;
          }
          return Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        thickness: WidgetStateProperty.all(8.0),
        radius: const Radius.circular(12.0),
        thumbVisibility: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.dragged) ||
              states.contains(WidgetState.scrolledUnder)) {
            return true;
          }
          return false;
        }),
        trackVisibility: WidgetStateProperty.all(false),
        crossAxisMargin: 2.0,
        mainAxisMargin: 8.0,
        interactive: true,
      ),
      // Add bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: Colors.grey.shade300,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
