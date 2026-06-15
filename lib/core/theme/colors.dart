import 'package:flutter/material.dart';

/// VaachakaLekhini color tokens — single source of truth.
/// Mirrors tokens defined in `docs/MOCKUPS.html` so design and code stay in sync.
abstract final class KvlColors {
  // Surfaces
  static const bg = Color(0xFFFBF3E2);
  static const bgDeep = Color(0xFFF5EAC9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFFF8EA);
  static const surfaceWarm = Color(0xFFFDF1D9);

  // Ink
  static const ink = Color(0xFF2A1F14);
  static const inkSoft = Color(0xFF5A4A3A);
  static const muted = Color(0xFF9A8A78);

  // Primary (saffron)
  static const primary = Color(0xFFE8893B);
  static const primaryDeep = Color(0xFFC97328);
  static const primarySoft = Color(0xFFFDE2C5);
  static const primaryGhost = Color(0xFFFEF1E0);

  // Accent (teal — "Finish Session")
  static const accent = Color(0xFF1F6F6B);
  static const accentSoft = Color(0xFFC5E0DD);

  // Semantic
  static const success = Color(0xFF2E8B57);
  static const successSoft = Color(0xFFCDE9D8);
  static const gold = Color(0xFFD4A300);
  static const danger = Color(0xFFE53935);

  // Borders / rules
  static const border = Color(0xFFEAD8B8);
  static const rule = Color(0xFFF0DFBE);

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEE9A4F), Color(0xFFE8893B)],
  );
  static const welcomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF4A056), Color(0xFFE8893B), Color(0xFFC97328)],
  );
  static const tealGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A8580), Color(0xFF1F6F6B)],
  );
}
