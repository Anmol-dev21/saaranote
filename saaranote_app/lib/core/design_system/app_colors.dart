import 'package:flutter/material.dart';

/// SaaraNote Color System
/// Implements the design system defined in SAARANOTE_UI_UX_DESIGN.md
class AppColors {
  AppColors._();

  // ==================== LIGHT MODE ====================
  
  // Primary Colors
  static const Color primaryLight = Color(0xFF5B7BF5);
  static const Color primaryLightHover = Color(0xFF4A6AE4);
  static const Color primaryLightActive = Color(0xFF3959D3);
  static const Color primaryLightSubtle = Color(0xFFE8ECFD);
  
  // Neutral Colors (Light Mode)
  static const Color gray50Light = Color(0xFFFAFAFA);
  static const Color gray100Light = Color(0xFFF5F5F5);
  static const Color gray200Light = Color(0xFFEEEEEE);
  static const Color gray300Light = Color(0xFFE0E0E0);
  static const Color gray400Light = Color(0xFFBDBDBD);
  static const Color gray500Light = Color(0xFF9E9E9E);
  static const Color gray600Light = Color(0xFF757575);
  static const Color gray700Light = Color(0xFF616161);
  static const Color gray800Light = Color(0xFF424242);
  static const Color gray900Light = Color(0xFF212121);
  
  // Semantic Colors (Light Mode)
  static const Color successLight = Color(0xFF10B981);
  static const Color successLightBg = Color(0xFFD1FAE5);
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningLightBg = Color(0xFFFEF3C7);
  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorLightBg = Color(0xFFFEE2E2);
  static const Color infoLight = Color(0xFF3B82F6);
  static const Color infoLightBg = Color(0xFFDBEAFE);
  
  // Surface Colors (Light Mode)
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color cardLight = Color(0xFFFFFFFF);
  
  // Text Colors (Light Mode)
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textDisabledLight = Color(0xFFBDBDBD);
  
  // ==================== DARK MODE ====================
  
  // Primary Colors (Dark Mode - desaturated)
  static const Color primaryDark = Color(0xFF7890FF);
  static const Color primaryDarkHover = Color(0xFF89A0FF);
  static const Color primaryDarkActive = Color(0xFF9AB0FF);
  static const Color primaryDarkSubtle = Color(0xFF1E2847);
  
  // Neutral Colors (Dark Mode)
  static const Color gray50Dark = Color(0xFF1A1A1A);
  static const Color gray100Dark = Color(0xFF242424);
  static const Color gray200Dark = Color(0xFF2E2E2E);
  static const Color gray300Dark = Color(0xFF404040);
  static const Color gray400Dark = Color(0xFF525252);
  static const Color gray500Dark = Color(0xFF737373);
  static const Color gray600Dark = Color(0xFFA3A3A3);
  static const Color gray700Dark = Color(0xFFD4D4D4);
  static const Color gray800Dark = Color(0xFFE5E5E5);
  static const Color gray900Dark = Color(0xFFF5F5F5);
  
  // Semantic Colors (Dark Mode - muted)
  static const Color successDark = Color(0xFF34D399);
  static const Color successDarkBg = Color(0xFF064E3B);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color warningDarkBg = Color(0xFF78350F);
  static const Color errorDark = Color(0xFFF87171);
  static const Color errorDarkBg = Color(0xFF7F1D1D);
  static const Color infoDark = Color(0xFF60A5FA);
  static const Color infoDarkBg = Color(0xFF1E3A8A);
  
  // Surface Colors (Dark Mode)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color cardDark = Color(0xFF242424);
  
  // Text Colors (Dark Mode)
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFA3A3A3);
  static const Color textDisabledDark = Color(0xFF525252);
  
  // ==================== ACCENT COLORS ====================
  
  static const Color folderYellow = Color(0xFFFBBF24);
  static const Color tagBlue = Color(0xFF3B82F6);
  static const Color tagGreen = Color(0xFF10B981);
  static const Color tagPurple = Color(0xFF8B5CF6);
  static const Color tagRed = Color(0xFFEF4444);
  static const Color tagOrange = Color(0xFFF59E0B);
  
  // ==================== HELPER METHODS ====================
  
  /// Get primary color based on brightness
  static Color primary(Brightness brightness) {
    return brightness == Brightness.light ? primaryLight : primaryDark;
  }
  
  /// Get background color based on brightness
  static Color background(Brightness brightness) {
    return brightness == Brightness.light ? backgroundLight : backgroundDark;
  }
  
  /// Get surface color based on brightness
  static Color surface(Brightness brightness) {
    return brightness == Brightness.light ? surfaceLight : surfaceDark;
  }
  
  /// Get card color based on brightness
  static Color card(Brightness brightness) {
    return brightness == Brightness.light ? cardLight : cardDark;
  }
  
  /// Get text primary color based on brightness
  static Color textPrimary(Brightness brightness) {
    return brightness == Brightness.light ? textPrimaryLight : textPrimaryDark;
  }
  
  /// Get text secondary color based on brightness
  static Color textSecondary(Brightness brightness) {
    return brightness == Brightness.light ? textSecondaryLight : textSecondaryDark;
  }
  
  /// Get success color based on brightness
  static Color success(Brightness brightness) {
    return brightness == Brightness.light ? successLight : successDark;
  }
  
  /// Get error color based on brightness
  static Color error(Brightness brightness) {
    return brightness == Brightness.light ? errorLight : errorDark;
  }
  
  /// Get warning color based on brightness
  static Color warning(Brightness brightness) {
    return brightness == Brightness.light ? warningLight : warningDark;
  }
}
