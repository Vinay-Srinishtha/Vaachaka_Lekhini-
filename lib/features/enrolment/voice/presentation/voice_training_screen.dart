import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../app/router.dart';
import '../../../../core/i18n/language_options.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../settings/domain/settings_repository.dart';
import '../../../../l10n/l10n.dart';
import '../data/voice_enrolment_service.dart';
import '../domain/voice_enrolment.dart';

class VoiceTrainingScreen extends ConsumerStatefulWidget {
  const VoiceTrainingScreen({
    super.key,
    required this.mantraId,
    this.isRetrain = false,
  });
  final String mantraId;
  final bool isRetrain;

  @override
  ConsumerState<VoiceTrainingScreen> createState() =>
      _VoiceTrainingScreenState();
}

class _VoiceTrainingScreenState extends ConsumerState<VoiceTrainingScreen> {
  final _service = VoiceEnrolmentService();
  StreamSubscription<VoiceTrainingEvent>? _sub;
  int _count = 0;
  bool _recording = false;
  String? _error;

  static const int _target = 11;

  @override
  void initState() {
    super.initState();
    _sub = _service.events.listen(_onEvent);
  }

  void _onEvent(VoiceTrainingEvent e) {
    if (!mounted) return;
    setState(() {
      _count = e.count;
    });
    // The service emits a "done" event at completion; close the loop.
    if (_count >= _target && _recording) {
      _finishAndProceed();
    }
  }

  Future<void> _start() async {
    final mantra = ref.read(mantraByIdProvider(widget.mantraId));
    if (mantra == null) return;
    setState(() {
      _recording = true;
      _error = null;
    });
    try {
      await _service.start(mantra, target: _target);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recording = false;
        _error = '$e';
      });
    }
  }

  Future<void> _stop() async {
    await _service.stop();
    if (!mounted) return;
    setState(() => _recording = false);
  }

  Future<void> _finishAndProceed() async {
    await _service.stop();
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null) return;
    await ref
        .read(voiceEnrolmentRepositoryProvider)
        .save(
          VoiceEnrolment(
            profileId: profile.id,
            mantraId: widget.mantraId,
            samples: _count,
            trainedAt: DateTime.now(),
          ),
        );
    if (!mounted) return;
    if (widget.isRetrain) {
      // Retraining from settings — go back to the profile screen, no handwriting step.
      context.pop();
    } else {
      context.push('${KvlRoute.handwritingSubmit}/${widget.mantraId}');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mantra = ref.watch(mantraByIdProvider(widget.mantraId));
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final script =
        mantra?.name.scriptForLanguage(settings.languageCode) ??
        settings.languageCode.mantraScriptForLanguage;
    final mantraText =
        mantra?.name.displayForLanguage(settings.languageCode) ?? '…';

    return KvlScaffold(
      title: '',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.lg),
          Center(child: _MicBubble(recording: _recording)),
          const SizedBox(height: KvlSpacing.xl),
          Text(
            context.l10n.trainYourVoice,
            textAlign: TextAlign.center,
            style: KvlText.title(20),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.learnChantingPattern,
            textAlign: TextAlign.center,
            style: KvlText.caption(11.5),
          ),
          const SizedBox(height: KvlSpacing.lg),
          KvlCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: KvlText.ui(16, FontWeight.w700),
                    children: [
                      TextSpan(text: context.l10n.sayMantraInstruction),
                      TextSpan(
                        text: mantraText,
                        style: KvlText.mantraByScript(script, 18).copyWith(
                          color: KvlColors.primaryDeep,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(text: context.l10n.sayMantraElevenTimes),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.speakNaturally,
                  style: KvlText.caption(13).copyWith(
                    color: KvlColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KvlSpacing.md),
          _TrainingProgress(count: _count, target: _target),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _recording
                  ? context.l10n.recordingStatus(_count, _target)
                  : context.l10n.tapStartToBegin,
              style: KvlText.caption(11.5).copyWith(
                color: _recording ? KvlColors.primaryDeep : KvlColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: KvlText.caption(11.5).copyWith(color: KvlColors.danger),
            ),
          ],
          const SizedBox(height: KvlSpacing.lg),
          KvlButton(
            label: _recording
                ? context.l10n.stopButton
                : context.l10n.startRecordingButton,
            onPressed: _recording ? _stop : _start,
          ),
        ],
      ),
    );
  }
}

/// Segmented 0–[target] progress bar for voice training. Each captured sample
/// fills one segment green; remaining segments stay red until recorded.
class _TrainingProgress extends StatelessWidget {
  const _TrainingProgress({required this.count, required this.target});
  final int count;
  final int target;

  static const _green = Color(0xFF16A34A);
  static const _red = Color(0xFFE5573E);

  @override
  Widget build(BuildContext context) {
    final done = count.clamp(0, target);
    return Row(
      children: [
        for (var i = 0; i < target; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              height: 8,
              decoration: BoxDecoration(
                color: i < done ? _green : _red.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MicBubble extends StatefulWidget {
  const _MicBubble({required this.recording});
  final bool recording;

  @override
  State<_MicBubble> createState() => _MicBubbleState();
}

class _MicBubbleState extends State<_MicBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.recording) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _MicBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recording == oldWidget.recording) return;
    if (widget.recording) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.recording ? 1 : 0),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (_, activity, child) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) {
            final t = Curves.easeInOutSine.transform(_ctrl.value);
            final middle = activity * (8 + t * 4);
            final outer = activity * (18 + t * 8);
            return Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFFFFB572), KvlColors.primary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: KvlColors.primary.withValues(alpha: .14 * activity),
                    blurRadius: 2,
                    spreadRadius: middle,
                  ),
                  BoxShadow(
                    color: KvlColors.primary.withValues(alpha: .07 * activity),
                    blurRadius: 4,
                    spreadRadius: outer,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 72,
                height: 72,
                child: CustomPaint(painter: _VoiceMicPainter()),
              ),
            );
          },
        );
      },
    );
  }
}

class _VoiceMicPainter extends CustomPainter {
  const _VoiceMicPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .055
      ..strokeCap = StrokeCap.round;

    // Capsule body
    final capsuleW = size.width * .44;
    final capsuleH = size.height * .52;
    final capsuleTop = size.height * .03;
    final capsuleRect = Rect.fromLTWH(
      cx - capsuleW / 2,
      capsuleTop,
      capsuleW,
      capsuleH,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(capsuleRect, Radius.circular(capsuleW / 2)),
      fill,
    );

    // Grille lines
    final grillePaint = Paint()
      ..color = KvlColors.primary.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .035
      ..strokeCap = StrokeCap.round;
    final grilleL = cx - capsuleW * .38;
    final grilleR = cx + capsuleW * .38;
    final grilleStartY = capsuleTop + capsuleH * .30;
    for (var i = 0; i < 3; i++) {
      final y = grilleStartY + i * capsuleH * .18;
      canvas.drawLine(Offset(grilleL, y), Offset(grilleR, y), grillePaint);
    }

    // Stand arc
    final arcCenterY = capsuleTop + capsuleH * .9;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, arcCenterY),
        width: size.width * .72,
        height: size.height * .38,
      ),
      0,
      3.14159,
      false,
      strokePaint,
    );

    // Stem + base
    final stemBot = size.height * .93;
    canvas.drawLine(
      Offset(cx, arcCenterY + size.height * .19),
      Offset(cx, stemBot),
      strokePaint,
    );
    canvas.drawLine(
      Offset(cx - size.width * .26, stemBot),
      Offset(cx + size.width * .26, stemBot),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
