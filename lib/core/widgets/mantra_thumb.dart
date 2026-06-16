import 'package:flutter/material.dart';

import '../theme/typography.dart';

/// Circular thumbnail for a mantra. Gradient is derived deterministically
/// from the glyph's first code-unit so each mantra is consistently
/// coloured without needing an explicit palette field.
class MantraThumb extends StatelessWidget {
  const MantraThumb({super.key, required this.glyph, this.size = 42});

  final String glyph;
  final double size;

  static const _gradients = <List<Color>>[
    [Color(0xFFF4A056), Color(0xFFC97328)], // saffron
    [Color(0xFF9C7BC8), Color(0xFF6B4E9B)], // violet
    [Color(0xFF5BA0E0), Color(0xFF2E6BAA)], // sky blue
    [Color(0xFF6A8FCC), Color(0xFF344E8A)], // indigo
    [Color(0xFFE06A9C), Color(0xFFAA3070)], // rose
    [Color(0xFF5BBF8A), Color(0xFF2E8A5E)], // teal
  ];

  @override
  Widget build(BuildContext context) {
    final idx = glyph.isEmpty ? 0 : glyph.codeUnitAt(0) % _gradients.length;
    final colors = _gradients[idx];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
}
