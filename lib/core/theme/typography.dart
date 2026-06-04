import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Typography is multi-script. Lexend for Latin / UI / numbers,
/// Tiro Devanagari Hindi for elegant mantra display in Devanagari,
/// Tiro Telugu / Tiro Kannada for those scripts.
/// Use [KvlText.mantra] etc. to pick a script-aware style.
abstract final class KvlText {
  static TextStyle ui([double size = 14, FontWeight w = FontWeight.w400]) =>
      GoogleFonts.lexend(fontSize: size, fontWeight: w, color: KvlColors.ink, height: 1.4);

  static TextStyle title([double size = 18, FontWeight w = FontWeight.w600]) =>
      GoogleFonts.lexend(fontSize: size, fontWeight: w, color: KvlColors.ink, height: 1.25, letterSpacing: -0.01);

  static TextStyle body([double size = 13]) =>
      GoogleFonts.lexend(fontSize: size, fontWeight: FontWeight.w400, color: KvlColors.ink, height: 1.5);

  static TextStyle caption([double size = 11]) =>
      GoogleFonts.lexend(fontSize: size, fontWeight: FontWeight.w400, color: KvlColors.inkSoft, height: 1.4);

  static TextStyle muted([double size = 10.5]) =>
      GoogleFonts.lexend(fontSize: size, fontWeight: FontWeight.w400, color: KvlColors.muted, height: 1.4);

  /// Mantra display — Devanagari elegant serif.
  static TextStyle mantraDevanagari([double size = 26]) =>
      GoogleFonts.tiroDevanagariHindi(fontSize: size, fontWeight: FontWeight.w400, color: KvlColors.ink, height: 1.3);

  /// Mantra body — Devanagari sans for descriptions.
  static TextStyle bodyDevanagari([double size = 13]) =>
      GoogleFonts.notoSansDevanagari(fontSize: size, fontWeight: FontWeight.w400, color: KvlColors.ink, height: 1.5);

  static TextStyle mantraTelugu([double size = 24]) =>
      GoogleFonts.tiroTelugu(fontSize: size, fontWeight: FontWeight.w400, color: KvlColors.ink, height: 1.4);

  static TextStyle bodyTelugu([double size = 13]) =>
      GoogleFonts.notoSansTelugu(fontSize: size, fontWeight: FontWeight.w400, color: KvlColors.ink, height: 1.5);

  static TextStyle mantraKannada([double size = 24]) =>
      GoogleFonts.tiroKannada(fontSize: size, fontWeight: FontWeight.w400, color: KvlColors.ink, height: 1.4);

  static TextStyle bodyKannada([double size = 13]) =>
      GoogleFonts.notoSansKannada(fontSize: size, fontWeight: FontWeight.w400, color: KvlColors.ink, height: 1.5);

  /// Big number readout (Indian-style comma grouping; pair with [IndianNumberFormat]).
  static TextStyle bigNumber([double size = 26]) =>
      GoogleFonts.lexend(fontSize: size, fontWeight: FontWeight.w700, color: KvlColors.ink, height: 1, letterSpacing: -0.02);
}

/// Convenience widget that renders a mantra in the right script font based on
/// a script hint. Falls back to Devanagari display.
class MantraText extends StatelessWidget {
  const MantraText(this.text, {super.key, this.script = MantraScript.devanagari, this.size = 26, this.color});

  final String text;
  final MantraScript script;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = switch (script) {
      MantraScript.devanagari => KvlText.mantraDevanagari(size),
      MantraScript.telugu => KvlText.mantraTelugu(size),
      MantraScript.kannada => KvlText.mantraKannada(size),
    };
    return Text(text, style: color == null ? style : style.copyWith(color: color), textAlign: TextAlign.center);
  }
}

enum MantraScript { devanagari, telugu, kannada }
