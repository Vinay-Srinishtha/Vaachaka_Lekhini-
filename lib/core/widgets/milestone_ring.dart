import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Thin arc ring drawn around a child widget reflecting milestone progress.
/// [completed] / [total] drives the sweep. Only the child is interactive —
/// the ring itself is purely decorative (IgnorePointer).
class MilestoneRing extends StatelessWidget {
  const MilestoneRing({
    super.key,
    required this.completed,
    required this.total,
    required this.child,
    this.strokeWidth = 2.5,
    this.gap = 3.0,
  });

  final int completed;
  final int total;
  final Widget child;
  final double strokeWidth;
  /// Extra space between the ring and the child.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final progress = (total > 0) ? (completed / total).clamp(0.0, 1.0) : 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        // Ring painted outside the child — IgnorePointer so taps pass through.
        Positioned.fill(
          child: IgnorePointer(
            child: Padding(
              padding: EdgeInsets.all(-(strokeWidth + gap)),
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
