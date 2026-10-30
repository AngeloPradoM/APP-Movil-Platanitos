import 'package:flutter/material.dart';

import '../../shared/widgets/line_icons.dart';

abstract final class AppColors {
  static const green = Color(0xFF138447),
      darkGreen = Color(0xFF0B6937),
      softGreen = Color(0xFFE9F5ED),
      ink = Color(0xFF17211B),
      /// Texto secundario con contraste ≥ 4.5:1 sobre blanco.
      muted = Color(0xFF4A524E),
      border = Color(0xFFC9D0CC),
      background = Color(0xFFF3F5F4),
      yellow = Color(0xFFF5CC37),
      danger = Color(0xFFB42318);

  static const highContrastInk = Color(0xFF000000),
      highContrastMuted = Color(0xFF1A1A1A),
      highContrastBorder = Color(0xFF000000),
      highContrastGreen = Color(0xFF005C2E),
      highContrastBackground = Color(0xFFFFFFFF);
}

ThemeData buildTheme({bool highContrast = false}) {
  final ink = highContrast ? AppColors.highContrastInk : AppColors.ink;
  final muted = highContrast ? AppColors.highContrastMuted : AppColors.muted;
  final border = highContrast ? AppColors.highContrastBorder : AppColors.border;
  final green = highContrast ? AppColors.highContrastGreen : AppColors.green;
  final background = highContrast
      ? AppColors.highContrastBackground
      : AppColors.background;
  final focusWidth = highContrast ? 3.0 : 2.2;

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      surface: Colors.white,
      error: AppColors.danger,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: border,
    ),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Inter',
    visualDensity: VisualDensity.standard,
    focusColor: highContrast ? const Color(0xFFFFF200) : AppColors.softGreen,
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: ink, fontSize: 14),
      bodySmall: TextStyle(color: muted, fontSize: 12),
      titleLarge: TextStyle(
        color: ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: ink,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: ink,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        color: ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (_) => const LineIcon(LineIcons.back),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: background,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: green, width: focusWidth),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.danger, width: focusWidth),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border, width: highContrast ? 1.5 : 1),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: green,
        side: BorderSide(color: green, width: highContrast ? 2 : 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return green;
        return border;
      }),
    ),
    dividerTheme: DividerThemeData(color: border),
  );
}

String money(double amount) => 'S/ ${amount.toStringAsFixed(2)}';
