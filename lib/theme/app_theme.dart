import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF2C2C2C);
  static const Color secondaryColor = Color(0xFF4A4A4A);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF2C2C2C);
  static const Color subtitleColor = Color(0xFF757575);
  
  // Status Colors
  static const Color statusBlue = Color(0xFF29B6F6);
  static const Color statusGreen = Color(0xFF8BC34A);
  static const Color statusRed = Color(0xFF607D8B);
  static const Color statusYellow = Color(0xFFFFCA28);

  // Gradient Colors
  static const List<Color> backgroundGradientColors = [
    Colors.white,
    Color(0xFFFAFAFA),
    Color(0xFFF1F8E9),
    Color(0xFFE6EEF6),
  ];

  // Text Styles
  static TextStyle get titleStyle => GoogleFonts.unna(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: 0.15,
  );

  static TextStyle get subtitleStyle => GoogleFonts.unna(
    fontSize: 18,
    color: subtitleColor,
    letterSpacing: 0.15,
  );

  static TextStyle get phaseHeaderStyle => GoogleFonts.unna(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: subtitleColor,
    letterSpacing: 1.5,
  );

  static TextStyle get phaseTextStyle => GoogleFonts.unna(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: primaryColor,
    letterSpacing: 0.5,
  );

  static TextStyle get pillTextStyle => GoogleFonts.unna(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static TextStyle get cardTitleStyle => GoogleFonts.unna(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryColor,
    letterSpacing: 1.2,
  );

  static TextStyle get cardBodyStyle => TextStyle(
    fontSize: 14,
    color: primaryColor.withOpacity(0.8),
    height: 1.4,
  );

  static TextStyle get tagLabelStyle => TextStyle(
    fontSize: 12,
    color: Colors.grey[600],
    fontWeight: FontWeight.w500,
  );

  static TextStyle get tagValueStyle => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.grey[800],
  );

  static TextStyle get appBarTitleStyle => GoogleFonts.unna(
    color: primaryColor,
    fontSize: 24,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get dateStyle => GoogleFonts.unna(
    fontSize: 20,
    fontWeight: FontWeight.w300,
  );

  static TextStyle get phaseStyle => GoogleFonts.unna(
    fontSize: 24,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get poeticMessageStyle => GoogleFonts.unna(
    fontSize: 16,
    fontStyle: FontStyle.italic,
    color: primaryColor,
    height: 1.6,
    letterSpacing: 0.5,
  );

  static TextStyle get errorTextStyle => TextStyle(
    color: Colors.red[700],
    fontSize: 12,
  );

  // Card Decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get glassCardDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.85),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withOpacity(0.3),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration get entryTileDecoration => BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey[300]!),
  );

  // Tag Decoration
  static BoxDecoration get tagDecoration => BoxDecoration(
    color: Colors.black.withOpacity(0.05),
    borderRadius: BorderRadius.circular(12),
  );

  // Input Decoration
  static InputDecoration get textFieldDecoration => InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: primaryColor),
    ),
  );

  // Button Styles
  static ButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 0,
  );

  // Padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets tagPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  static const EdgeInsets glassCardPadding = EdgeInsets.all(24.0);
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);

  // Spacing
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 20.0;
  static const double borderRadiusXLarge = 24.0;

  // Constraints
  static const BoxConstraints maxWidthConstraint = BoxConstraints(maxWidth: 720);
  static const BoxConstraints maxFormWidthConstraint = BoxConstraints(maxWidth: 480);
} 