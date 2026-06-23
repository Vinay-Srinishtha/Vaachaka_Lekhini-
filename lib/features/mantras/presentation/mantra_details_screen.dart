import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../settings/domain/settings_repository.dart';
import '../../../l10n/l10n.dart';
import '../domain/mantra.dart';

class MantraDetailsScreen extends ConsumerStatefulWidget {
  const MantraDetailsScreen({super.key, required this.mantraId});
  final String mantraId;

  @override
  ConsumerState<MantraDetailsScreen> createState() => _MantraDetailsScreenState();
}

class _MantraDetailsScreenState extends ConsumerState<MantraDetailsScreen> {
  bool _starting = false;

  /// Checks what enrolment exists for this mantra and routes to the first
  /// missing step. If everything is already enrolled, goes straight to
  /// set-target so the user can create the program without re-collecting samples.
  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final profile = ref.read(activeProfileProvider).value;
      if (profile == null || !mounted) return;

      // Check voice enrolment — handwriting is set up separately via practice tab.
      final voiceEnrolment = await ref
          .read(voiceEnrolmentRepositoryProvider)
          .get(profile.id, widget.mantraId);
      // Already-trained counts only if it was trained in the CURRENTLY-selected
      // mantra script. If the user switched script, send them to (re)train.
      final currentScript =
          ref.read(settingsProvider).value?.mantraLanguageCode ?? 'hi';
      final hasVoice = voiceEnrolment != null &&
          voiceEnrolment.isComplete &&
          // Empty = legacy/unknown trained script → accept for any current
          // script (don't force already-trained users to retrain).
          (voiceEnrolment.trainedLanguageCode.isEmpty ||
              voiceEnrolment.trainedLanguageCode == currentScript);

      if (!mounted) return;

      if (hasVoice) {
        // Voice already registered — skip enrolment and the goal screen, and
        // go straight to chanting. The target (if any) is set on Finish.
        final program = await ref
            .read(programRepositoryProvider)
            .createOpen(memberId: profile.id, mantraId: widget.mantraId);
        if (!mounted) return;
        context.go('${KvlRoute.practice}/${program.id}');
      } else {
        context.push('${KvlRoute.voiceTraining}/${widget.mantraId}');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mantra = ref.watch(mantraByIdProvider(widget.mantraId));
    if (mantra == null) {
      return KvlScaffold(
        title: context.l10n.mantraNotFoundTitle,
        body: Center(child: Text(context.l10n.mantraNotFound, style: KvlText.body())),
      );
    }
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final script = mantra.name.scriptForLanguage(settings.languageCode);
    final name = mantra.name.displayForLanguage(settings.languageCode);
    return KvlScaffold(
      title: '$name Mantra Details',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.sm),
          MantraText(name, script: script, size: 32),
          const SizedBox(height: KvlSpacing.md),
          _DeityHero(mantra: mantra),
          const SizedBox(height: KvlSpacing.md),
          Text(
            mantra.description,
            style: KvlText.body(12).copyWith(height: 1.55, color: KvlColors.inkSoft),
          ),
          const SizedBox(height: KvlSpacing.md),
          _PronunciationCard(
            mantra: mantra,
            languageCode: settings.languageCode,
          ),
          const SizedBox(height: KvlSpacing.md),
          KvlButton(
            label: _starting
                ? 'Loading…'
                : context.l10n.startPracticeWithMantra(name),
            onPressed: _starting ? null : _start,
          ),
        ],
      ),
    );
  }
}


class _DeityHero extends StatelessWidget {
  const _DeityHero({required this.mantra});
  final Mantra mantra;

  @override
  Widget build(BuildContext context) {
    final imageUrl = mantra.imageUrl;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: KvlRadius.brLG,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A2B1A), Color(0xFF7A4422)],
          ),
        ),
        child: Center(
          child: Text(
            'ॐ',
            style: KvlText.mantraDevanagari(110)
                .copyWith(color: Colors.white.withValues(alpha: .4)),
          ),
        ),
      );
}

class _PronunciationCard extends StatefulWidget {
  const _PronunciationCard({required this.mantra, required this.languageCode});
  final Mantra mantra;
  final String languageCode;

  @override
  State<_PronunciationCard> createState() => _PronunciationCardState();
}

class _PronunciationCardState extends State<_PronunciationCard>
    with TickerProviderStateMixin {
  final _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  // While the user is dragging the seek thumb, freeze position updates so the
  // stream doesn't fight the gesture and the thumb stays under the finger.
  bool _dragging = false;
  double _dragValue = 0.0;

  // Waveform animation controller
  late final AnimationController _waveCtrl;

  // Fixed pseudo-random bar heights so they don't jump on rebuild
  static const int _barCount = 28;
  late final List<double> _barSeeds;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    _barSeeds = List.generate(_barCount, (_) => 0.25 + rng.nextDouble() * 0.75);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playerState = s);
      if (s == PlayerState.playing) {
        _waveCtrl.repeat();
      } else {
        _waveCtrl.stop();
      }
    });
    _player.onPositionChanged.listen((p) {
      if (mounted && !_dragging) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final asset = widget.mantra.pronunciationAsset;
    if (asset == null || asset.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pronunciation audio not available for this mantra yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else if (_playerState == PlayerState.paused) {
      await _player.resume();
    } else {
      await _player.play(UrlSource(asset));
    }
  }

  Future<void> _seek(double ratio) async {
    if (_duration == Duration.zero) return;
    await _player.seek(Duration(milliseconds: (ratio * _duration.inMilliseconds).round()));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.mantra.name.displayForLanguage(widget.languageCode);
    final hasAudio = widget.mantra.pronunciationAsset?.isNotEmpty ?? false;
    final isPlaying = _playerState == PlayerState.playing;
    final isActive = isPlaying || _playerState == PlayerState.paused;
    final progress = (_duration.inMilliseconds > 0)
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KvlRadius.brMD,
        boxShadow: [
          BoxShadow(
            color: isActive
                ? KvlColors.primary.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: isActive ? 16 : 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isActive
              ? KvlColors.primary.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: KvlRadius.brMD,
        child: InkWell(
          borderRadius: KvlRadius.brMD,
          onTap: hasAudio ? _toggle : null,
          child: Padding(
            padding: const EdgeInsets.all(KvlSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Top row: icon + title + play button ──
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: hasAudio
                            ? KvlColors.primaryGradient
                            : const LinearGradient(
                                colors: [KvlColors.muted, KvlColors.muted]),
                        borderRadius: KvlRadius.brSM,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.music_note_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: KvlSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.pronunciationGuide,
                              style: KvlText.ui(11.5, FontWeight.w600)),
                          Text(
                            hasAudio ? '$name Mantra' : 'Audio coming soon',
                            style: KvlText.muted(10.5),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: hasAudio ? KvlColors.primary : KvlColors.muted,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                // ── Expanded waveform + seek bar (only when active) ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: isActive
                      ? Padding(
                          padding: const EdgeInsets.only(top: KvlSpacing.md),
                          child: Column(
                            children: [
                              // Waveform bars
                              AnimatedBuilder(
                                animation: _waveCtrl,
                                builder: (context2, child2) {
                                  return SizedBox(
                                    height: 36,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: List.generate(_barCount, (i) {
                                        final barProgress = i / _barCount;
                                        final isPast = barProgress <= progress;

                                        // Phase-shifted sine for each bar
                                        final phase = _waveCtrl.value * 2 * math.pi;
                                        final offset = (i / _barCount) * 2 * math.pi;
                                        final wave = isPlaying
                                            ? (math.sin(phase + offset) * 0.5 + 0.5)
                                            : 0.0;
                                        final height = (_barSeeds[i] * 0.5 +
                                                wave * _barSeeds[i] * 0.5) *
                                            36;

                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 80),
                                          width: 2.5,
                                          height: height.clamp(3.0, 36.0),
                                          decoration: BoxDecoration(
                                            color: isPast
                                                ? KvlColors.primary
                                                : KvlColors.primary
                                                    .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        );
                                      }),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: KvlSpacing.xs),

                              // Seek slider
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 7),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 16),
                                  activeTrackColor: KvlColors.primary,
                                  inactiveTrackColor:
                                      KvlColors.primary.withValues(alpha: 0.15),
                                  thumbColor: KvlColors.primary,
                                  overlayColor:
                                      KvlColors.primary.withValues(alpha: 0.12),
                                ),
                                child: Slider(
                                  value: _dragging ? _dragValue : progress,
                                  onChangeStart: hasAudio
                                      ? (v) => setState(() {
                                            _dragging = true;
                                            _dragValue = v;
                                          })
                                      : null,
                                  onChanged: hasAudio
                                      ? (v) => setState(() => _dragValue = v)
                                      : null,
                                  onChangeEnd: hasAudio
                                      ? (v) {
                                          _seek(v);
                                          setState(() => _dragging = false);
                                        }
                                      : null,
                                ),
                              ),

                              // Time labels
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: KvlSpacing.xs),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_fmt(_position),
                                        style: KvlText.muted(9.5)),
                                    Text(_fmt(_duration),
                                        style: KvlText.muted(9.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
