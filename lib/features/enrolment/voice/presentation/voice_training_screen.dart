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
// Premium orb mic — concentric halo rings + sonar ripple strokes
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

class _OrbMicState extends State<_OrbMic> with SingleTickerProviderStateMixin {
  static const _poolSize = 4;

  // Slow breathing halo for idle + active state
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orbDiam = 110.0;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final available = constraints.biggest.shortestSide;
        return Stack(
          alignment: Alignment.center,
          children: [
            // ── Sonar ripple rings (expand on each detected chant) ──
            for (var i = 0; i < _poolSize; i++)
              AnimatedBuilder(
                animation: widget.pool[i],
                builder: (ctx, child) {
                  final raw = widget.pool[i].value;
                  if (raw == 0.0) return const SizedBox.shrink();
                  final t = Curves.easeOutCubic.transform(raw);
                  final intensity = widget.slotIntensity[i];
                  final maxR = (available * 0.5) * (0.55 + intensity * 0.45);
                  final r = (orbDiam / 2) + (maxR - orbDiam / 2) * t;
                  final opacity = ((1.0 - t) * (0.55 + intensity * 0.35))
                      .clamp(0.0, 0.9);
                  final strokeW = (3.5 - t * 2.5).clamp(0.8, 3.5);
                  return CustomPaint(
                    size: Size(r * 2, r * 2),
                    painter: _RingPainter(
                      radius: r,
                      color: KvlColors.primary.withValues(alpha: opacity),
                      strokeWidth: strokeW,
                    ),
                  );
                },
              ),

            // ── Breathing halo layers (always visible) ──
            AnimatedBuilder(
              animation: _breath,
              builder: (ctx, child) {
                final b = Curves.easeInOut.transform(_breath.value);
                final isRec = widget.recording;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer halo
                    _Halo(
                      diam: orbDiam * (2.55 + b * (isRec ? 0.22 : 0.08)),
                      opacity: isRec ? (0.13 + b * 0.10) : (0.06 + b * 0.04),
                      strokeWidth: 1.2,
                    ),
                    // Mid halo
                    _Halo(
                      diam: orbDiam * (1.90 + b * (isRec ? 0.16 : 0.06)),
                      opacity: isRec ? (0.20 + b * 0.14) : (0.09 + b * 0.05),
                      strokeWidth: 1.5,
                    ),
                    // Inner halo
                    _Halo(
                      diam: orbDiam * (1.42 + b * (isRec ? 0.10 : 0.04)),
                      opacity: isRec ? (0.30 + b * 0.18) : (0.13 + b * 0.07),
                      strokeWidth: 2.0,
                    ),
                  ],
                );
              },
            ),

            // ── Ambient warm glow ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              width: orbDiam * 2.0,
              height: orbDiam * 2.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFA552)
                        .withValues(alpha: widget.recording ? 0.28 : 0.12),
                    const Color(0xFFE8782A)
                        .withValues(alpha: widget.recording ? 0.10 : 0.03),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // ── Reactive level bars (only while recording) ──
            if (widget.recording)
              IgnorePointer(
                child: SizedBox.fromSize(
                  size: Size(orbDiam * 2.6, orbDiam * 2.6),
                  child: _LevelRing(level: widget.level, orbDiam: orbDiam),
                ),
              ),

            // ── Premium orb button ──
            GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: orbDiam,
                height: orbDiam,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.3, -0.4),
                    radius: 1.0,
                    colors: [
                      Color(0xFFFFD49A),
                      Color(0xFFFF9A4A),
                      Color(0xFFD9622A),
                      Color(0xFFAA3E10),
                    ],
                    stops: [0.0, 0.38, 0.72, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB8521C).withValues(alpha: 0.55),
                      blurRadius: 40,
                      spreadRadius: 0,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: KvlColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: -2,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.60),
                      blurRadius: 1,
                      spreadRadius: 0,
                      offset: const Offset(-3, -4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.recording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: orbDiam * 0.44,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Single outlined circle halo
class _Halo extends StatelessWidget {
  const _Halo({
    required this.diam,
    required this.opacity,
    required this.strokeWidth,
  });
  final double diam;
  final double opacity;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(diam, diam),
      painter: _RingPainter(
        radius: diam / 2,
        color: KvlColors.primary.withValues(alpha: opacity),
        strokeWidth: strokeWidth,
      ),
    );
  }
}

// Lightweight CustomPainter for a single circle stroke
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.radius,
    required this.color,
    required this.strokeWidth,
  });
  final double radius;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.radius != radius || old.color != color || old.strokeWidth != strokeWidth;
}

// Reactive level ring — short radial bars pulsing around the orb while recording
class _LevelRing extends StatefulWidget {
  const _LevelRing({required this.level, required this.orbDiam});
  final ValueListenable<double> level;
  final double orbDiam;

  @override
  State<_LevelRing> createState() => _LevelRingState();
}

class _LevelRingState extends State<_LevelRing> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
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
          painter: _LevelRingPainter(
            phase: _ctrl.value,
            level: lvl.clamp(0.0, 1.0),
            orbRadius: widget.orbDiam / 2,
          ),
        ),
      ),
    );
  }
}

class _LevelRingPainter extends CustomPainter {
  const _LevelRingPainter({
    required this.phase,
    required this.level,
    required this.orbRadius,
  });
  final double phase;
  final double level;
  final double orbRadius;

  static const _barCount = 32;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const gap = 6.0;
    final innerR = orbRadius + gap;
    final barMaxLen = orbRadius * 0.36 + level * orbRadius * 0.22;

    for (var i = 0; i < _barCount; i++) {
      final angle = (i / _barCount) * 2 * math.pi;
      // Each bar gets a slightly different phase offset for a flowing look
      final waveOffset = (i / _barCount) * 2 * math.pi;
      final wave = (math.sin(phase * 2 * math.pi + waveOffset) * 0.5 + 0.5);
      final barLen = (barMaxLen * (0.25 + wave * 0.75)).clamp(2.0, barMaxLen);
      final opacity = (0.15 + level * 0.50 + wave * 0.20).clamp(0.0, 0.85);

      final x1 = cx + math.cos(angle) * innerR;
      final y1 = cy + math.sin(angle) * innerR;
      final x2 = cx + math.cos(angle) * (innerR + barLen);
      final y2 = cy + math.sin(angle) * (innerR + barLen);

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = KvlColors.primary.withValues(alpha: opacity)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelRingPainter old) =>
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
