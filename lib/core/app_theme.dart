import 'package:flutter/material.dart';

import '../widgets/line_icons.dart';

abstract final class AppColors {
  static const green = Color(0xFF138447),
      darkGreen = Color(0xFF0B6937),
      softGreen = Color(0xFFE9F5ED),
      ink = Color(0xFF17211B),
      muted = Color(0xFF6F7772),
      border = Color(0xFFE8ECE9),
      background = Color(0xFFF3F5F4),
      yellow = Color(0xFFF5CC37),
      danger = Color(0xFFD74343);
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.green,
    primary: AppColors.green,
    surface: Colors.white,
    error: AppColors.danger,
  ),
  scaffoldBackgroundColor: Colors.white,
  fontFamily: 'Inter',
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: AppColors.ink, fontSize: 14),
    bodySmall: TextStyle(color: AppColors.muted, fontSize: 12),
    titleLarge: TextStyle(
      color: AppColors.ink,
      fontSize: 22,
      fontWeight: FontWeight.w700,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.ink,
    centerTitle: true,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Inter',
      color: AppColors.ink,
      fontSize: 17,
      fontWeight: FontWeight.w700,
    ),
  ),
  actionIconTheme: ActionIconThemeData(
    backButtonIconBuilder: (_) => const LineIcon(LineIcons.back),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.background,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 46),
      foregroundColor: AppColors.green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    ),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.border),
);
String money(double amount) => 'S/ ${amount.toStringAsFixed(2)}';
