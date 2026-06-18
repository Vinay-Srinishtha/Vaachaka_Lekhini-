import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Thin arc ring drawn around a child widget.
/// Use [MilestoneRing] for integer completed/total, or
/// [MilestoneRing.fraction] for a direct 0.0–1.0 value.
class MilestoneRing extends StatelessWidget {
  const MilestoneRing({
    super.key,
    required this.completed,
    required this.total,
    required this.child,
    this.strokeWidth = 2.5,
    this.gap = 3.0,
  }) : _fraction = null;

  const MilestoneRing.fraction({
    super.key,
    required double fraction,
    required this.child,
    this.strokeWidth = 2.5,
    this.gap = 3.0,
  })  : completed = 0,
        total = 0,
        _fraction = fraction;

  final int completed;
  final int total;
  final double? _fraction;
  final Widget child;
  final double strokeWidth;
  /// Extra space between the ring and the child.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final progress = _fraction != null
        ? _fraction.clamp(0.0, 1.0)
        : (total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0);

    final inset = -(strokeWidth + gap);

    // clipBehavior: Clip.none lets the ring paint slightly *outside* the child
    // via the negative Positioned offsets — negative Padding is illegal
    // (RenderPadding asserts non-negative) and throws on every screen.
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        Positioned(
          left: inset,
          top: inset,
          right: inset,
          bottom: inset,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                strokeWidth: strokeWidth,
                trackColor: KvlColors.primary.withValues(alpha: 0.15),
                fillColor: KvlColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.fillColor,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Full track (faint)
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, trackPaint);

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}
