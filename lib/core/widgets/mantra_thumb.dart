import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/typography.dart';

/// Circular thumbnail for a mantra. Shows [imageUrl] when provided,
/// otherwise falls back to a deterministic gradient circle with the [glyph].
class MantraThumb extends StatelessWidget {
  const MantraThumb({super.key, required this.glyph, this.size = 42, this.imageUrl});

  final String glyph;
  final double size;
  final String? imageUrl;

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

    final glyphCircle = Container(
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

    if (imageUrl == null || imageUrl!.isEmpty) return glyphCircle;

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => glyphCircle,
        errorWidget: (_, _, _) => glyphCircle,
      ),
    );
  }
}
