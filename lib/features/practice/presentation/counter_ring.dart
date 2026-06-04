import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/indian_number_format.dart';

/// Big mantra counter — animated ring + current/target readout.
/// The ring fill tweens smoothly whenever [progress] changes.
class CounterRing extends StatelessWidget {
  const CounterRing({
    super.key,
    required this.current,
    required this.target,
    required this.subtitle,
    this.size = 180,
  });

  final int current;
  final int target;
  final String subtitle;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progress = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeOutCubic,
            builder: (_, p, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(size: Size(size, size), painter: _RingPainter(progress: p)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (c, a) =>
                            FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
                        child: Text(
                          IndianNumberFormat.format(current),
                          key: ValueKey(current),
                          style: KvlText.bigNumber(26),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('/ ${IndianNumberFormat.format(target)}', style: KvlText.muted(10)),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: KvlText.muted(10.5)),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final bg = Paint()
      ..color = KvlColors.primarySoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..shader = const LinearGradient(colors: [KvlColors.primary, KvlColors.primaryDeep])
          .createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
