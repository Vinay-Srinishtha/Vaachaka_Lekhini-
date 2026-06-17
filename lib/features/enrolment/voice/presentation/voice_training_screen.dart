import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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

class _VoiceTrainingScreenState extends ConsumerState<VoiceTrainingScreen>
    with TickerProviderStateMixin {
  final _service = VoiceEnrolmentService();
  StreamSubscription<VoiceTrainingEvent>? _sub;
  int _count = 0;
  bool _recording = false;
  String? _error;

  // Mic level ValueNotifier fed from the service's levels stream.
  final _micLevel = ValueNotifier<double>(0.0);
  StreamSubscription<double>? _levelSub;

  // Ripple pool — same pattern as counter_screen.dart.
  static const _poolSize = 4;
  late List<AnimationController> _pool;
  int _nextSlot = 0;
  DateTime? _lastCountTime;
  final List<double> _slotIntensity = List.filled(_poolSize, 0.5);

  static const int _target = 11;

  @override
  void initState() {
    super.initState();
    _sub = _service.events.listen(_onEvent);
    _pool = List.generate(
      _poolSize,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  void _onEvent(VoiceTrainingEvent e) {
    if (!mounted) return;
    final prev = _count;
    setState(() => _count = e.count);
    if (_count > prev) _fireRipple();
    if (mounted && _count >= _target && _recording) {
      _finishAndProceed();
    }
  }

  void _fireRipple() {
    final now = DateTime.now();
    double intensity = 0.5;
    if (_lastCountTime != null) {
      final ms = now.difference(_lastCountTime!).inMilliseconds;
      intensity = (1.0 - ((ms - 300) / 2700)).clamp(0.18, 0.82);
    }
    _lastCountTime = now;
    final slot = _nextSlot % _poolSize;
    _nextSlot++;
    _slotIntensity[slot] = intensity;
    _pool[slot].duration = Duration(milliseconds: (1900 - intensity * 450).round());
    _pool[slot].forward(from: 0);
  }

  Future<void> _start() async {
    final mantra = ref.read(mantraByIdProvider(widget.mantraId));
    if (mantra == null) {
      setState(() {
        _error = 'Mantra data is still loading — please wait a moment and try again.';
      });
      return;
    }
    setState(() { _recording = true; _error = null; });
    _levelSub = _service.levels.listen((l) => _micLevel.value = l);
    try {
      await _service.start(mantra, target: _target);
    } catch (e) {
      if (!mounted) return;
      setState(() { _recording = false; _error = '$e'; });
    }
  }

  Future<void> _stop() async {
    await _service.stop();
    _levelSub?.cancel();
    _micLevel.value = 0;
    if (!mounted) return;
    setState(() => _recording = false);
  }

  Future<void> _finishAndProceed() async {
    await _service.stop();
    _levelSub?.cancel();
    _micLevel.value = 0;
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null) return;
    await ref.read(voiceEnrolmentRepositoryProvider).save(
      VoiceEnrolment(
        profileId: profile.id,
        mantraId: widget.mantraId,
        samples: _count,
        trainedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    if (widget.isRetrain) {
      context.pop();
    } else {
      context.push('${KvlRoute.setTargetWritings}/${widget.mantraId}');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _levelSub?.cancel();
    _micLevel.dispose();
    for (final c in _pool) { c.dispose(); }
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(mantraCatalogProvider);
    if (!catalogAsync.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mantra = ref.watch(mantraByIdProvider(widget.mantraId));
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final script = mantra?.name.scriptForLanguage(settings.languageCode) ??
        settings.languageCode.mantraScriptForLanguage;
    final mantraText = mantra?.name.displayForLanguage(settings.languageCode) ??
        widget.mantraId;
    final imageUrl = mantra?.imageUrl;

    return KvlScaffold(
      title: '',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.md),

          // ── Mantra image card (premium) ────────────────────────────────
          if (imageUrl != null && imageUrl.isNotEmpty)
            _MantraImageCard(imageUrl: imageUrl, mantraText: mantraText, script: script),

          // ── Orb mic with ripples ───────────────────────────────────────
          SizedBox(
            height: 260,
            child: _OrbMic(
              recording: _recording,
              pool: _pool,
              slotIntensity: _slotIntensity,
              level: _micLevel,
              onTap: _recording ? _stop : _start,
            ),
          ),

          // ── Title ──────────────────────────────────────────────────────
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

          // ── Instruction card ───────────────────────────────────────────
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

          // ── Progress bar — only visible once recording starts ──────────
          if (_recording) ...[
            _TrainingProgress(count: _count, target: _target),
            const SizedBox(height: 8),
            Center(
              child: Text(
                context.l10n.recordingStatus(_count, _target),
                style: KvlText.caption(11.5).copyWith(
                  color: KvlColors.primaryDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            Center(
              child: Text(
                context.l10n.tapStartToBegin,
                style: KvlText.caption(11.5).copyWith(color: KvlColors.muted),
              ),
            ),
          ],

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

// ─────────────────────────────────────────────────────────────────────────────
// Premium mantra image card
// ─────────────────────────────────────────────────────────────────────────────

class _MantraImageCard extends StatelessWidget {
  const _MantraImageCard({
    required this.imageUrl,
    required this.mantraText,
    required this.script,
  });
  final String imageUrl;
  final String mantraText;
  final MantraScript script;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KvlSpacing.md),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: KvlRadius.brLG,
          boxShadow: [
            BoxShadow(
              color: KvlColors.primaryDeep.withValues(alpha: .18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: KvlRadius.brLG,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [KvlColors.primarySoft, KvlColors.primary.withValues(alpha: .4)],
                    ),
                  ),
                ),
              ),
              // Gradient scrim so the text is legible.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: .55),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: KvlSpacing.md,
                right: KvlSpacing.md,
                bottom: KvlSpacing.sm,
                child: Text(
                  mantraText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KvlText.mantraByScript(script, 22).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      const Shadow(
                        color: Colors.black45,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Orb mic with ripple pool (same look as counter_screen)
// ─────────────────────────────────────────────────────────────────────────────

class _OrbMic extends StatefulWidget {
  const _OrbMic({
    required this.recording,
    required this.pool,
    required this.slotIntensity,
    required this.level,
    required this.onTap,
  });
  final bool recording;
  final List<AnimationController> pool;
  final List<double> slotIntensity;
  final ValueListenable<double> level;
  final VoidCallback onTap;

  @override
  State<_OrbMic> createState() => _OrbMicState();
}

class _OrbMicState extends State<_OrbMic> {
  static const _poolSize = 4;
  static const _ringColors = [
    Color(0xFFD2691E), Color(0xFFC75D24), Color(0xFFB8521C),
    Color(0xFFCC6A2B), Color(0xFFA8481A), Color(0xFFBE5E20),
  ];

  @override
  Widget build(BuildContext context) {
    const orbDiam = 100.0;
    const micDiam = orbDiam * 1.4;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxDiam = constraints.biggest.longestSide * 3.2;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Ambient glow
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: orbDiam * 3.0,
              height: orbDiam * 3.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFC58A).withValues(alpha: widget.recording ? 0.26 : 0.10),
                    const Color(0xFFFF8C42).withValues(alpha: widget.recording ? 0.12 : 0.04),
                    KvlColors.primary.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // Ripple rings
            for (var i = 0; i < _poolSize; i++)
              AnimatedBuilder(
                animation: widget.pool[i],
                builder: (ctx, child) {
                  final raw = widget.pool[i].value;
                  if (raw == 0.0) return const SizedBox.shrink();
                  final t = Curves.easeOut.transform(raw);
                  final intensity = widget.slotIntensity[i];
                  final reach = micDiam + (maxDiam - micDiam) * intensity;
                  final diam = reach * t;
                  final opacity = ((1.0 - t) * 0.34 * intensity).clamp(0.0, 0.34);
                  final color = _ringColors[i % _ringColors.length];
                  return Container(
                    width: diam,
                    height: diam,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: 0.0),
                          color.withValues(alpha: opacity * 0.3),
                          color.withValues(alpha: opacity),
                        ],
                        stops: const [0.0, 0.60, 1.0],
                      ),
                    ),
                  );
                },
              ),

            // Reactive curved sound waves while recording
            if (widget.recording)
              IgnorePointer(
                child: SizedBox(
                  width: orbDiam * 2.7,
                  height: orbDiam * 1.7,
                  child: _VoiceWaves(level: widget.level),
                ),
              ),

            // Orb button
            GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: orbDiam,
                height: orbDiam,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFE0BE),
                      Color(0xFFFFC08A),
                      KvlColors.primary,
                      KvlColors.primaryDeep,
                      Color(0xFFB8521C),
                    ],
                    stops: [0.0, 0.22, 0.55, 0.85, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: KvlColors.primaryDeep.withValues(alpha: 0.30),
                      blurRadius: 32,
                      spreadRadius: 2,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: KvlColors.primary.withValues(alpha: 0.42),
                      blurRadius: 26,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.55),
                      blurRadius: 2,
                      spreadRadius: -2,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.recording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: orbDiam * 0.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reactive sound waves (copied from counter_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

class _VoiceWaves extends StatefulWidget {
  const _VoiceWaves({required this.level});
  final ValueListenable<double> level;

  @override
  State<_VoiceWaves> createState() => _VoiceWavesState();
}

class _VoiceWavesState extends State<_VoiceWaves> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) => ValueListenableBuilder<double>(
        valueListenable: widget.level,
        builder: (ctx2, lvl, child2) => CustomPaint(
          painter: _WavesPainter(phase: _ctrl.value, level: lvl),
        ),
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  const _WavesPainter({required this.phase, required this.level});
  final double phase;
  final double level;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final smoothed = level.clamp(0.0, 1.0);
    const arcCount = 3;
    final baseGap = size.width * 0.13;
    final baseRadius = size.width * 0.27;

    for (final side in [-1, 1]) {
      canvas.save();
      // Flip horizontally around the centre to draw both left and right waves.
      canvas.translate(cx, cy);
      canvas.scale(side.toDouble(), 1.0);
      canvas.translate(-cx, -cy);

      for (var i = 0; i < arcCount; i++) {
        final t = ((phase + i * 0.33) % 1.0);
        final opacity = (math.sin(t * math.pi) * (0.25 + smoothed * 0.45)).clamp(0.0, 0.9);
        final spread = smoothed * size.width * 0.04 * (i + 1);
        final radius = baseRadius + i * baseGap + spread;
        final paint = Paint()
          ..color = KvlColors.primary.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2.0 + smoothed * 1.5).clamp(1.5, 3.5)
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          -math.pi / 4,
          math.pi / 2,
          false,
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WavesPainter old) =>
      old.phase != phase || old.level != level;
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress bar
// ─────────────────────────────────────────────────────────────────────────────

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
