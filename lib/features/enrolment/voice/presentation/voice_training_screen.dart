import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../data/voice_enrolment_service.dart';
import '../domain/voice_enrolment.dart';

class VoiceTrainingScreen extends ConsumerStatefulWidget {
  const VoiceTrainingScreen({super.key, required this.mantraId});
  final String mantraId;

  @override
  ConsumerState<VoiceTrainingScreen> createState() => _VoiceTrainingScreenState();
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
    await ref.read(voiceEnrolmentRepositoryProvider).save(VoiceEnrolment(
          profileId: profile.id,
          mantraId: widget.mantraId,
          samples: _count,
          trainedAt: DateTime.now(),
        ));
    if (!mounted) return;
    context.go('${KvlRoute.handwritingSubmit}/${widget.mantraId}');
  }

  Future<void> _skipToManual() async {
    await _service.stop();
    if (!mounted) return;
    context.go('${KvlRoute.handwritingSubmit}/${widget.mantraId}');
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
    final mantraText = mantra?.name.devanagari ?? '…';
    final mantraRoman = mantra?.name.roman ?? '';

    return KvlScaffold(
      title: '',
      trailing: const SizedBox(width: 36),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.lg),
          Center(child: _MicBubble(recording: _recording)),
          const SizedBox(height: KvlSpacing.xl),
          Text('Train Your Voice', textAlign: TextAlign.center, style: KvlText.title(20)),
          const SizedBox(height: 6),
          Text(
            'Let me learn your unique chanting pattern for accurate counting.',
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
                    style: KvlText.ui(12.5, FontWeight.w600),
                    children: [
                      const TextSpan(text: 'Say '),
                      TextSpan(
                        text: mantraText,
                        style: KvlText.mantraDevanagari(14).copyWith(color: KvlColors.primaryDeep),
                      ),
                      TextSpan(text: '  ·  "$mantraRoman" eleven times clearly'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text('Speak naturally at your normal pace and volume', style: KvlText.caption(11)),
              ],
            ),
          ),
          const SizedBox(height: KvlSpacing.md),
          _Waveform(active: _recording),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _recording ? '● Recording  ·  $_count / $_target' : 'Tap Start to begin',
              style: KvlText.caption(11.5).copyWith(
                color: _recording ? KvlColors.primaryDeep : KvlColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: KvlText.caption(11.5).copyWith(color: KvlColors.danger)),
          ],
          const SizedBox(height: KvlSpacing.lg),
          KvlButton(
            label: _recording ? 'Stop' : 'Start Recording',
            onPressed: _recording ? _stop : _start,
          ),
          const SizedBox(height: KvlSpacing.sm),
          KvlButton(
            variant: KvlButtonVariant.secondary,
            label: 'Skip & Use Manual Counter',
            onPressed: _skipToManual,
          ),
        ],
      ),
    );
  }
}

class _MicBubble extends StatefulWidget {
  const _MicBubble({required this.recording});
  final bool recording;

  @override
  State<_MicBubble> createState() => _MicBubbleState();
}

class _MicBubbleState extends State<_MicBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final outer = widget.recording ? 24 + t * 12 : 0.0;
        final middle = widget.recording ? 12 + t * 4 : 0.0;
        return Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [const Color(0xFFFFB572), KvlColors.primary]),
            boxShadow: [
              BoxShadow(color: KvlColors.primary.withValues(alpha: .16), blurRadius: 0, spreadRadius: middle),
              BoxShadow(color: KvlColors.primary.withValues(alpha: .08), blurRadius: 0, spreadRadius: outer),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 56),
        );
      },
    );
  }
}

class _Waveform extends StatefulWidget {
  const _Waveform({required this.active});
  final bool active;

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          const bars = 11;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < bars; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    width: 3,
                    height: widget.active ? _h(i, _ctrl.value) : 6,
                    decoration: BoxDecoration(
                      color: KvlColors.primary,
                      borderRadius: KvlRadius.brSM,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Symmetric "breathing" amplitude with phase offsets per bar.
  double _h(int i, double t) {
    final mid = (11 - 1) / 2;
    final dist = (i - mid).abs();
    final phase = (t + dist * 0.08) % 1.0;
    final amp = (math.sin(phase * math.pi * 2) + 1) / 2;
    return 6 + amp * 22;
  }
}
