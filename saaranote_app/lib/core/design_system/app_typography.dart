import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SaaraNote Typography System
/// Based on Inter font family with optimized reading settings
class AppTypography {
  AppTypography._();

  // Font family
  static const String fontFamily = 'Inter';
  
  // Base font settings for reading optimization
  static const double baseLineHeight = 1.7;
  static const double headingLineHeight = 1.3;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  /// Display text style (32px, Bold)
  /// Usage: Main headlines, page titles
  static TextStyle display({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 32,
      height: headingLineHeight,
      fontWeight: fontWeight ?? bold,
      color: color,
      letterSpacing: -0.5,
    );
  }

  /// Heading 1 text style (24px, Semibold)
  /// Usage: Section headers
  static TextStyle h1({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 24,
      height: headingLineHeight,
      fontWeight: fontWeight ?? semiBold,
      color: color,
      letterSpacing: -0.3,
    );
  }

  /// Heading 2 text style (20px, SemiBold)
  /// Usage: Sub-section headers
  static TextStyle h2({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 20,
      height: headingLineHeight,
      fontWeight: fontWeight ?? semiBold,
      color: color,
      letterSpacing: -0.2,
    );
  }

  /// Heading 3 text style (18px, Medium) - Card titles, dialog headers
  static TextStyle h3({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 18,
      height: headingLineHeight,
      fontWeight: fontWeight ?? medium,
      color: color,
      letterSpacing: -0.1,
    );
  }

  /// Body text style (16px, Regular) - Main content
  static TextStyle body({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 16,
      height: 1.6,
      fontWeight: fontWeight ?? regular,
      color: color,
      letterSpacing: 0,
    );
  }

  /// Body Small text style (14px, Regular)
  /// Usage: Descriptions, metadata
  static TextStyle bodySmall({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 14,
      height: 1.5,
      fontWeight: fontWeight ?? regular,
      color: color,
      letterSpacing: 0,
    );
  }

  /// Label text style (14px, Medium) - Input labels, navigation
  static TextStyle label({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 14,
      height: 1.4,
      fontWeight: fontWeight ?? medium,
      color: color,
      letterSpacing: 0.1,
    );
  }

  /// Button text style (16px, Medium) - Button labels, CTAs
  static TextStyle button({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 16,
      height: 1.0,
      fontWeight: fontWeight ?? medium,
      color: color,
      letterSpacing: 0,
    );
  }

  /// Caption text style (12px, Regular)
  /// Usage: Timestamps, footnotes, helper text
  static TextStyle caption({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 12,
      height: 1.4,
      fontWeight: fontWeight ?? regular,
      color: color,
      letterSpacing: 0.2,
    );
  }

  /// Note Content text style (18px, Regular)
  /// Usage: Reading-optimized text for note detail view
  /// Based on design spec: "Font size: 18px (larger for reading comfort)"
  static TextStyle noteContent({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 18,
      height: 1.7, // Generous line height for comprehension
      fontWeight: fontWeight ?? regular,
      color: color,
      letterSpacing: 0,
    );
  }

  /// Get complete TextTheme for Material theme
  static TextTheme getTextTheme(Brightness brightness, Color textColor) {
    return TextTheme(
      displayLarge: display(color: textColor),
      displayMedium: display(color: textColor).copyWith(fontSize: 28),
      displaySmall: display(color: textColor).copyWith(fontSize: 24),
      
      headlineLarge: h1(color: textColor),
      headlineMedium: h2(color: textColor),
      headlineSmall: h3(color: textColor),
      
      titleLarge: h3(color: textColor),
      titleMedium: bodySmall(color: textColor, fontWeight: semiBold),
      titleSmall: label(color: textColor, fontWeight: semiBold),
      
      bodyLarge: body(color: textColor),
      bodyMedium: bodySmall(color: textColor),
      bodySmall: caption(color: textColor),
      
      labelLarge: label(color: textColor),
      labelMedium: label(color: textColor).copyWith(fontSize: 13),
      labelSmall: caption(color: textColor, fontWeight: medium),
    );
  }
}
