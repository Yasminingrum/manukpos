// config/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Brand Colors - Berdasarkan palet warna dari gambar
  static const Color primaryColor = Color(0xFF78ABA8); // Teal/Blue
  static const Color accentColor = Color(0xFFEF9C66);  // Orange
  static const Color secondaryColor = Color(0xFFFCDC94); // Yellow
  static const Color tertiaryColor = Color(0xFFC8CFA0); // Sage/Light Green
  static const Color backgroundColor = Color(0xFFF8F9FE); // Soft Grey 
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFF5365C); 
  static const Color successColor = Color(0xFF2DCE89);
  static const Color warningColor = Color(0xFFFFBB33); 
  static const Color infoColor = Color(0xFF78ABA8); 

  // Text Colors - Enhanced for readability
  static const Color textDark = Color(0xFF344767); 
  static const Color textMedium = Color(0xFF67748E); 
  static const Color textLight = Color(0xFFADB5BD); 
  static const Color textWhite = Colors.white;

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: textDark,
      onTertiary: textDark,
      onSurface: textDark,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundColor,
    
    // Modern App Bar with reduced shadow and cleaner design
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: surfaceColor,
      foregroundColor: textDark,
      iconTheme: IconThemeData(color: textDark),
    ),
    
    // More rounded card with softer shadow
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withAlpha(26), // 0.1 as alpha
    ),
    
    // Modern input fields with soft fill and cleaner borders
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      labelStyle: const TextStyle(color: textMedium),
      hintStyle: const TextStyle(color: textLight), 
    ),
    
    // Modern pill-shaped buttons with softer shadows
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1, 
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Outlined buttons with rounder corners
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5), 
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Text buttons with more padding
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Modern icon colors
    iconTheme: const IconThemeData(
      color: primaryColor,
      size: 24,
    ),
    
    // Floating action buttons with accent color
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor, 
      foregroundColor: Colors.white,
      elevation: 2, 
      shape: CircleBorder(),
    ),
    
    // Softer dividers
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEEEEEE), 
      thickness: 1,
      space: 1,
    ),
    
    // Tab bar with underlined accent
    tabBarTheme: const TabBarTheme(
      labelColor: accentColor, 
      unselectedLabelColor: textMedium,
      indicatorColor: accentColor, 
      indicatorSize: TabBarIndicatorSize.label,
    ),
    
    // Modern bottom navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: textMedium,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: false,
    ),
    
    // Modern typography with Poppins
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        color: textDark,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.poppins(
        color: textDark,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.poppins(
        color: textDark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.poppins(
        color: textDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineSmall: GoogleFonts.poppins(
        color: textDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.poppins(
        color: textDark,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      ),
      titleMedium: GoogleFonts.poppins(
        color: textDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      ),
      bodyLarge: GoogleFonts.poppins(
        color: textDark,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.3,
      ),
      bodyMedium: GoogleFonts.poppins(
        color: textDark,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.3,
      ),
      bodySmall: GoogleFonts.poppins(
        color: textMedium,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.3,
      ),
      labelLarge: GoogleFonts.poppins(
        color: textDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
      ),
      labelMedium: GoogleFonts.poppins(
        color: textDark,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
      ),
      labelSmall: GoogleFonts.poppins(
        color: textMedium,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
      ),
    ),
  );

  // Dark Theme - Complete implementation to match light theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      surface: const Color(0xFF2A2D3E),
      error: const Color(0xFFF5365C),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onTertiary: Colors.black,
      onSurface: Colors.white,
      onError: Colors.black,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF1E1E2D),
    
    // Dark theme app bar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Color(0xFF2A2D3E),
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    
    // Dark theme card with subtle glow
    cardTheme: CardTheme(
      color: const Color(0xFF2A2D3E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: primaryColor.withAlpha(26), // 0.1 as alpha
    ),
    
    // Dark theme input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2D3E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
    ),
    
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3F4164),
      thickness: 1,
      space: 1,
    ),
    
    // Dark theme bottom navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF2A2D3E),
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.white60,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: false,
    ),
    
    // Dark theme floating action button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    
    // Dark theme text
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      bodyLarge: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.3,
      ),
      bodyMedium: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.3,
      ),
      bodySmall: GoogleFonts.poppins(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.3,
      ),
    ),
  );
}