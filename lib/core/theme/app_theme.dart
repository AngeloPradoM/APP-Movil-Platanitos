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
      highContrastMuted = Color(0xFF000000),
      highContrastBorder = Color(0xFF000000),
      highContrastGreen = Color(0xFF002E18),
      highContrastBackground = Color(0xFFFFFFFF),
      highContrastFocus = Color(0xFFFFD400);
}

ThemeData buildTheme({bool highContrast = false}) {
  final ink = highContrast ? AppColors.highContrastInk : AppColors.ink;
  final muted = highContrast ? AppColors.highContrastMuted : AppColors.muted;
  final border = highContrast ? AppColors.highContrastBorder : AppColors.border;
  final green = highContrast ? AppColors.highContrastGreen : AppColors.green;
  final background = highContrast
      ? AppColors.highContrastBackground
      : AppColors.background;
  final focusRing = highContrast
      ? AppColors.highContrastFocus
      : AppColors.darkGreen;
  final focusWidth = highContrast ? 4.0 : 3.0;

  BorderSide? focusedSide(Set<WidgetState> states) {
    if (!states.contains(WidgetState.focused)) return null;
    return BorderSide(color: focusRing, width: focusWidth);
  }

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
    ).copyWith(primary: green, onPrimary: Colors.white),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Inter',
    visualDensity: VisualDensity.standard,
    focusColor: focusRing.withValues(alpha: highContrast ? 0.55 : 0.28),
    hoverColor: green.withValues(alpha: 0.08),
    splashColor: green.withValues(alpha: 0.16),
    highlightColor: focusRing.withValues(alpha: highContrast ? 0.35 : 0.12),
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        color: ink,
        fontSize: highContrast ? 15 : 14,
        fontWeight: highContrast ? FontWeight.w600 : FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: muted,
        fontSize: highContrast ? 13 : 12,
        fontWeight: highContrast ? FontWeight.w600 : FontWeight.w400,
      ),
      titleLarge: TextStyle(
        color: ink,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: ink,
        fontSize: 16,
        fontWeight: FontWeight.w800,
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
        fontWeight: FontWeight.w800,
      ),
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (_) => const LineIcon(LineIcons.back),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        tapTargetSize: MaterialTapTargetSize.padded,
        foregroundColor: WidgetStatePropertyAll(ink),
        side: WidgetStateProperty.resolveWith(focusedSide),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return focusRing.withValues(alpha: highContrast ? 0.45 : 0.22);
          }
          return null;
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
        foregroundColor: WidgetStatePropertyAll(green),
        side: WidgetStateProperty.resolveWith(focusedSide),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return focusRing.withValues(alpha: highContrast ? 0.4 : 0.18);
          }
          return null;
        }),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: background,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border, width: highContrast ? 2 : 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border, width: highContrast ? 2 : 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focusRing, width: focusWidth),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
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
        side: BorderSide(color: border, width: highContrast ? 2 : 1),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: highContrast
            ? const BorderSide(color: Colors.black, width: 2)
            : BorderSide.none,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(8),
        border: highContrast
            ? Border.all(color: AppColors.highContrastFocus, width: 2)
            : null,
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        backgroundColor: WidgetStatePropertyAll(green),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w800),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: focusRing, width: focusWidth);
          }
          return highContrast
              ? const BorderSide(color: Colors.black, width: 2)
              : BorderSide.none;
        }),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return 6;
          return 0;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return focusRing.withValues(alpha: 0.35);
          }
          return null;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        foregroundColor: WidgetStatePropertyAll(green),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: focusRing, width: focusWidth);
          }
          return BorderSide(color: green, width: highContrast ? 2.5 : 1.5);
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return focusRing.withValues(alpha: highContrast ? 0.4 : 0.16);
          }
          return null;
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: ink,
      textColor: ink,
      selectedTileColor: focusRing.withValues(alpha: highContrast ? 0.45 : 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: highContrast
            ? const BorderSide(color: Colors.black, width: 1.5)
            : BorderSide.none,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return highContrast ? Colors.black : null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return green;
        return highContrast ? Colors.white : null;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return focusRing;
        if (states.contains(WidgetState.selected)) return green;
        return border;
      }),
      trackOutlineWidth: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return focusWidth;
        return highContrast ? 2.0 : 1.0;
      }),
    ),
    dividerTheme: DividerThemeData(
      color: border,
      thickness: highContrast ? 2 : 1,
    ),
  );
}

String money(double amount) => 'S/ ${amount.toStringAsFixed(2)}';
