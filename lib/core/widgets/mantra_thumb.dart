import 'package:flutter/material.dart';

import '../theme/typography.dart';

/// Small circular thumbnail used for mantras in lists / cards.
/// Renders a coloured gradient with a single character in Devanagari.
class MantraThumb extends StatelessWidget {
  const MantraThumb({
    super.key,
    required this.glyph,
    this.size = 42,
    this.palette = MantraThumbPalette.saffron,
  });

  final String glyph;
  final double size;
  final MantraThumbPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradient(palette),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        glyph,
        style: KvlText.mantraDevanagari(size * 0.42).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Color> _gradient(MantraThumbPalette p) => switch (p) {
        MantraThumbPalette.saffron => const [Color(0xFFF4A056), Color(0xFFC97328)],
        MantraThumbPalette.shiva => const [Color(0xFF9C7BC8), Color(0xFF6B4E9B)],
        MantraThumbPalette.vishnu => const [Color(0xFF5BA0E0), Color(0xFF2E6BAA)],
        MantraThumbPalette.krishna => const [Color(0xFF6A8FCC), Color(0xFF344E8A)],
        MantraThumbPalette.matre => const [Color(0xFFE06A9C), Color(0xFFAA3070)],
      };
}

enum MantraThumbPalette { saffron, shiva, vishnu, krishna, matre }
