import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// KVL dark theme — warm dark surfaces with the same saffron/teal accents.
ThemeData buildKvlDarkTheme() {
  final base = FlexThemeData.dark(
    colors: const FlexSchemeColor(
      primary: KvlColors.primary,
      primaryContainer: Color(0xFF5A3510),
      secondary: KvlColors.accent,
      secondaryContainer: Color(0xFF0D3533),
      tertiary: KvlColors.gold,
      tertiaryContainer: Color(0xFF4A3800),
      appBarColor: Color(0xFF1C1510),
      error: KvlColors.danger,
    ),
    surface: const Color(0xFF1C1510),
    scaffoldBackground: const Color(0xFF140F0A),
    appBarStyle: FlexAppBarStyle.scaffoldBackground,
    appBarElevation: 0,
    tabBarStyle: FlexTabBarStyle.forBackground,
    fontFamily: GoogleFonts.lexend().fontFamily,
    subThemesData: const FlexSubThemesData(
      defaultRadius: 14,
      cardRadius: 16,
      inputDecoratorRadius: 12,
      elevatedButtonRadius: 14,
      filledButtonRadius: 14,
      outlinedButtonRadius: 14,
      textButtonRadius: 14,
      cardElevation: 0,
      bottomNavigationBarElevation: 0,
      bottomSheetRadius: 24,
      dialogRadius: 20,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorIsFilled: true,
      inputDecoratorFillColor: Color(0xFF2A1F14),
      inputDecoratorBackgroundAlpha: 255,
      thinBorderWidth: 1,
      thickBorderWidth: 1.5,
    ),
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: GoogleFonts.lexendTextTheme(base.textTheme).apply(
      bodyColor: const Color(0xFFF0E6D0),
      displayColor: const Color(0xFFF0E6D0),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFF0E6D0), size: 20),
  );
}

/// KVL light theme. Built on flex_color_scheme for consistent
/// component theming with Material 3 defaults overridden where needed
/// to match the warm cream / saffron / teal language in `docs/MOCKUPS.html`.
ThemeData buildKvlLightTheme() {
  final base = FlexThemeData.light(
    colors: const FlexSchemeColor(
      primary: KvlColors.primary,
      primaryContainer: KvlColors.primarySoft,
      secondary: KvlColors.accent,
      secondaryContainer: KvlColors.accentSoft,
      tertiary: KvlColors.gold,
      tertiaryContainer: Color(0xFFFBE9A8),
      appBarColor: KvlColors.bg,
      error: KvlColors.danger,
    ),
    surface: KvlColors.bg,
    scaffoldBackground: KvlColors.bg,
    appBarStyle: FlexAppBarStyle.scaffoldBackground,
    appBarElevation: 0,
    tabBarStyle: FlexTabBarStyle.forBackground,
    fontFamily: GoogleFonts.lexend().fontFamily,
    subThemesData: const FlexSubThemesData(
      defaultRadius: 14,
      cardRadius: 16,
      inputDecoratorRadius: 12,
      elevatedButtonRadius: 14,
      filledButtonRadius: 14,
      outlinedButtonRadius: 14,
      textButtonRadius: 14,
      cardElevation: 0,
      bottomNavigationBarElevation: 0,
      bottomSheetRadius: 24,
      dialogRadius: 20,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorIsFilled: true,
      inputDecoratorFillColor: KvlColors.surface,
      inputDecoratorBackgroundAlpha: 255,
      thinBorderWidth: 1,
      thickBorderWidth: 1.5,
    ),
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: GoogleFonts.lexendTextTheme(base.textTheme).apply(
      bodyColor: KvlColors.ink,
      displayColor: KvlColors.ink,
    ),
    iconTheme: const IconThemeData(color: KvlColors.ink, size: 20),
  );
}
