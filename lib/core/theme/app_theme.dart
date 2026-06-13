import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

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

/// KVL dark theme — mirrors the light palette with dark surface colours.
ThemeData buildKvlDarkTheme() {
  final base = FlexThemeData.dark(
    colors: const FlexSchemeColor(
      primary: KvlColors.primary,
      primaryContainer: Color(0xFF3A2E60),
      secondary: KvlColors.accent,
      secondaryContainer: Color(0xFF1A3A3A),
      tertiary: KvlColors.gold,
      tertiaryContainer: Color(0xFF3D3010),
      appBarColor: Color(0xFF1C1B22),
      error: KvlColors.danger,
    ),
    surface: const Color(0xFF1C1B22),
    scaffoldBackground: const Color(0xFF13121A),
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
      inputDecoratorFillColor: Color(0xFF242330),
      inputDecoratorBackgroundAlpha: 255,
      thinBorderWidth: 1,
      thickBorderWidth: 1.5,
    ),
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: GoogleFonts.lexendTextTheme(base.textTheme),
    iconTheme: const IconThemeData(size: 20),
  );
}
