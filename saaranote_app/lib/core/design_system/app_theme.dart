import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// SaaraNote App Theme
/// Material Design 3 implementation with custom design system
class AppTheme {
  AppTheme._();

  // ==================== LIGHT THEME ====================
  
  static ThemeData lightTheme() {
    const brightness = Brightness.light;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryLight,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryLightSubtle,
        onPrimaryContainer: AppColors.primaryLightActive,
        
        secondary: AppColors.gray600Light,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.gray100Light,
        onSecondaryContainer: AppColors.gray800Light,
        
        tertiary: AppColors.tagPurple,
        onTertiary: Colors.white,
        
        error: AppColors.errorLight,
        onError: Colors.white,
        errorContainer: AppColors.errorLightBg,
        onErrorContainer: AppColors.errorLight,
        
        background: AppColors.backgroundLight,
        onBackground: AppColors.textPrimaryLight,
        
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        surfaceVariant: AppColors.gray50Light,
        onSurfaceVariant: AppColors.textSecondaryLight,
        
        outline: AppColors.gray300Light,
        outlineVariant: AppColors.gray200Light,
        
        shadow: AppColors.gray900Light.withOpacity(0.08),
        scrim: AppColors.gray900Light.withOpacity(0.5),
      ),
      
      // Typography
      textTheme: AppTypography.getTextTheme(brightness, AppColors.textPrimaryLight),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundLight,
      
      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimaryLight,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.h3(
          color: AppColors.textPrimaryLight,
          fontWeight: AppTypography.semiBold,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimaryLight,
          size: AppSpacing.iconLg,
        ),
      ),
      
      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          side: BorderSide(
            color: AppColors.gray200Light,
            width: 1,
          ),
        ),
        color: AppColors.cardLight,
        margin: EdgeInsets.zero,
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.gray200Light,
          disabledForegroundColor: AppColors.textDisabledLight,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: AppSpacing.horizontalLg.add(AppSpacing.verticalMd),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: AppTypography.label(fontWeight: AppTypography.semiBold),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: AppSpacing.horizontalMd.add(AppSpacing.verticalSm),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: AppTypography.label(fontWeight: AppTypography.medium),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: BorderSide(color: AppColors.gray300Light, width: 1),
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: AppSpacing.horizontalLg.add(AppSpacing.verticalMd),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: AppTypography.label(fontWeight: AppTypography.medium),
        ),
      ),
      
      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: EdgeInsets.all(AppSpacing.sm),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: AppSpacing.elevationMd,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray50Light,
        contentPadding: AppSpacing.horizontalMd.add(AppSpacing.verticalMd),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: AppColors.gray300Light, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: AppColors.gray300Light, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: AppColors.errorLight, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: AppColors.errorLight, width: 2),
        ),
        labelStyle: AppTypography.label(color: AppColors.textSecondaryLight),
        hintStyle: AppTypography.bodySmall(color: AppColors.textDisabledLight),
        helperStyle: AppTypography.caption(color: AppColors.textSecondaryLight),
        errorStyle: AppTypography.caption(color: AppColors.errorLight),
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray100Light,
        selectedColor: AppColors.primaryLightSubtle,
        disabledColor: AppColors.gray200Light,
        labelStyle: AppTypography.label(color: AppColors.textPrimaryLight),
        secondaryLabelStyle: AppTypography.caption(color: AppColors.textSecondaryLight),
        padding: AppSpacing.horizontalMd.add(AppSpacing.verticalSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        side: BorderSide.none,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.backgroundLight,
        elevation: AppSpacing.elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        titleTextStyle: AppTypography.h3(color: AppColors.textPrimaryLight),
        contentTextStyle: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.backgroundLight,
        elevation: AppSpacing.elevationLg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.gray800Light,
        contentTextStyle: AppTypography.bodySmall(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: AppSpacing.elevationMd,
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.gray200Light,
        thickness: 1,
        space: 1,
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: AppSpacing.horizontalMd,
        minVerticalPadding: AppSpacing.sm,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        titleTextStyle: AppTypography.bodySmall(
          color: AppColors.textPrimaryLight,
          fontWeight: AppTypography.medium,
        ),
        subtitleTextStyle: AppTypography.caption(color: AppColors.textSecondaryLight),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: AppColors.textPrimaryLight,
        size: AppSpacing.iconLg,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
        linearTrackColor: AppColors.gray200Light,
        circularTrackColor: AppColors.gray200Light,
      ),
    );
  }

  // ==================== DARK THEME ====================
  
  static ThemeData darkTheme() {
    const brightness = Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryDark,
        onPrimary: AppColors.gray900Dark,
        primaryContainer: AppColors.primaryDarkSubtle,
        onPrimaryContainer: AppColors.primaryDark,
        
        secondary: AppColors.gray500Dark,
        onSecondary: AppColors.gray900Dark,
        secondaryContainer: AppColors.gray200Dark,
        onSecondaryContainer: AppColors.gray700Dark,
        
        tertiary: AppColors.tagPurple,
        onTertiary: Colors.white,
        
        error: AppColors.errorDark,
        onError: AppColors.gray900Dark,
        errorContainer: AppColors.errorDarkBg,
        onErrorContainer: AppColors.errorDark,
        
        background: AppColors.backgroundDark,
        onBackground: AppColors.textPrimaryDark,
        
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceVariant: AppColors.gray100Dark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        
        outline: AppColors.gray400Dark,
        outlineVariant: AppColors.gray300Dark,
        
        shadow: Colors.black.withOpacity(0.3),
        scrim: Colors.black.withOpacity(0.7),
      ),
      
      // Typography
      textTheme: AppTypography.getTextTheme(brightness, AppColors.textPrimaryDark),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundDark,
      
      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTypography.h3(
          color: AppColors.textPrimaryDark,
          fontWeight: AppTypography.semiBold,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimaryDark,
          size: AppSpacing.iconLg,
        ),
      ),
      
      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          side: BorderSide(
            color: AppColors.gray300Dark,
            width: 1,
          ),
        ),
        color: AppColors.cardDark,
        margin: EdgeInsets.zero,
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.gray900Dark,
          disabledBackgroundColor: AppColors.gray300Dark,
          disabledForegroundColor: AppColors.textDisabledDark,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: AppSpacing.horizontalLg.add(AppSpacing.verticalMd),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: AppTypography.label(fontWeight: AppTypography.semiBold),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: AppSpacing.horizontalMd.add(AppSpacing.verticalSm),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: AppTypography.label(fontWeight: AppTypography.medium),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: BorderSide(color: AppColors.gray400Dark, width: 1),
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: AppSpacing.horizontalLg.add(AppSpacing.verticalMd),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: AppTypography.label(fontWeight: AppTypography.medium),
        ),
      ),
      
      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: EdgeInsets.all(AppSpacing.sm),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.gray900Dark,
        elevation: AppSpacing.elevationMd,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray100Dark,
        contentPadding: AppSpacing.horizontalMd.add(AppSpacing.verticalMd),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: AppColors.gray400Dark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: AppColors.gray400Dark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: AppColors.errorDark, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: AppColors.errorDark, width: 2),
        ),
        labelStyle: AppTypography.label(color: AppColors.textSecondaryDark),
        hintStyle: AppTypography.bodySmall(color: AppColors.textDisabledDark),
        helperStyle: AppTypography.caption(color: AppColors.textSecondaryDark),
        errorStyle: AppTypography.caption(color: AppColors.errorDark),
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray200Dark,
        selectedColor: AppColors.primaryDarkSubtle,
        disabledColor: AppColors.gray300Dark,
        labelStyle: AppTypography.label(color: AppColors.textPrimaryDark),
        secondaryLabelStyle: AppTypography.caption(color: AppColors.textSecondaryDark),
        padding: AppSpacing.horizontalMd.add(AppSpacing.verticalSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        side: BorderSide.none,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: AppSpacing.elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        titleTextStyle: AppTypography.h3(color: AppColors.textPrimaryDark),
        contentTextStyle: AppTypography.bodySmall(color: AppColors.textSecondaryDark),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: AppSpacing.elevationLg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.gray200Dark,
        contentTextStyle: AppTypography.bodySmall(color: AppColors.textPrimaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: AppSpacing.elevationMd,
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.gray300Dark,
        thickness: 1,
        space: 1,
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: AppSpacing.horizontalMd,
        minVerticalPadding: AppSpacing.sm,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        titleTextStyle: AppTypography.bodySmall(
          color: AppColors.textPrimaryDark,
          fontWeight: AppTypography.medium,
        ),
        subtitleTextStyle: AppTypography.caption(color: AppColors.textSecondaryDark),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: AppColors.textPrimaryDark,
        size: AppSpacing.iconLg,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primaryDark,
        linearTrackColor: AppColors.gray300Dark,
        circularTrackColor: AppColors.gray300Dark,
      ),
    );
  }
}
