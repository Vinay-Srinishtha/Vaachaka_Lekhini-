import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/remote_config/remote_config.dart';
import '../../../core/remote_config/remote_config_keys.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../programs/domain/session.dart';
import '../application/practice_controller.dart';
import 'counter_ring.dart';

class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key, required this.programId});
  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(practiceControllerProvider(programId));
    return stateAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => KvlScaffold(title: 'Practice', body: Center(child: Text('$e'))),
      data: (state) => _Body(programId: programId, state: state),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.programId, required this.state});
  final String programId;
  final PracticeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mantra = ref.watch(mantraByIdProvider(state.program.mantraId));
    final mantraLabel = mantra?.name.devanagari ?? state.program.mantraId;
    final mantraRoman = mantra?.name.roman ?? '';
    final controller = ref.read(practiceControllerProvider(programId).notifier);

    return KvlScaffold(
      title: DateFormat('EEEE, d MMM').format(DateTime.now()),
      subtitle: 'Day ${state.program.daysElapsed}',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.sm),
          _StatStrip(state: state),
          const SizedBox(height: KvlSpacing.md),

          Center(
            child: GestureDetector(
              onTap: state.isRunning && state.modality == SessionModality.manual
                  ? () {
                      HapticFeedback.lightImpact();
                      controller.tap();
                    }
                  : null,
              child: CounterRing(
                current: state.program.totalProgress + state.sessionCount,
                target: state.program.targetWritings,
                subtitle: '$mantraLabel · $mantraRoman',
              ),
            ),
          ),

          if (state.modality == SessionModality.manual && state.isRunning)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: Text('Tap the ring to count', style: KvlText.muted(10.5)),
              ),
            ),

          const SizedBox(height: KvlSpacing.md),
          () {
            final cfg = ref.watch(remoteConfigProvider).value ?? RemoteConfig.empty;
            final voiceEnabled = cfg.boolFlag(RemoteConfigKeys.voiceCounting, fallback: true);
            // If voice was active but the flag flipped to off, coerce back to manual
            // on the next frame — we don't want a "voice selected" UI with no voice pill.
            if (!voiceEnabled && state.modality == SessionModality.voice && !state.isRunning) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.setModality(SessionModality.manual);
              });
            }
            return _ModalitySelector(
              value: state.modality,
              enabled: !state.isRunning,
              voiceEnabled: voiceEnabled,
              onChanged: controller.setModality,
            );
          }(),
          const SizedBox(height: KvlSpacing.sm),

          // Primary action depends on session state.
          if (state.activeSessionId == null)
            KvlButton(
              label: 'START',
              icon: Icons.play_arrow_rounded,
              onPressed: () => controller.start(mantra: mantra),
            )
          else ...[
            KvlButton(
              label: state.isRunning ? 'PAUSE' : 'RESUME',
              icon: state.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              variant: state.isRunning ? KvlButtonVariant.secondary : KvlButtonVariant.primary,
              onPressed: state.isRunning ? controller.pause : () => controller.start(mantra: mantra),
            ),
            const SizedBox(height: KvlSpacing.sm),
            KvlButton(
              variant: KvlButtonVariant.teal,
              label: 'Finish Session',
              icon: Icons.check_rounded,
              onPressed: () async {
                final saved = state.sessionCount;
                await controller.finish();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Session saved · +${IndianNumberFormat.format(saved)} chants'),
                    backgroundColor: KvlColors.accent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                if (context.canPop()) context.pop();
              },
            ),
          ],

          if (state.errorMessage != null) ...[
            const SizedBox(height: KvlSpacing.sm),
            _MicErrorCard(
              message: state.errorMessage!,
              showOpenSettings: state.micPermanentlyDenied,
              onOpenSettings: controller.openSystemSettings,
              onSwitchManual: () {
                controller.setModality(SessionModality.manual);
                controller.clearError();
              },
              onDismiss: controller.clearError,
            ),
          ],

          const SizedBox(height: KvlSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Progress",
                style: KvlText.ui(10.5, FontWeight.w600).copyWith(color: KvlColors.inkSoft),
              ),
              Text(
                '${IndianNumberFormat.format(state.todaysTotal)} / ${IndianNumberFormat.format(state.program.dailyTarget)}',
                style: KvlText.caption(10.5).copyWith(color: KvlColors.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: KvlRadius.brPill,
            child: LinearProgressIndicator(
              value: state.program.dailyTarget == 0
                  ? 0
                  : (state.todaysTotal / state.program.dailyTarget).clamp(0, 1).toDouble(),
              minHeight: 6,
              backgroundColor: KvlColors.primarySoft,
              valueColor: const AlwaysStoppedAnimation(KvlColors.accent),
            ),
          ),
          const SizedBox(height: KvlSpacing.md),
          const Divider(color: KvlColors.rule, height: 1),
          const SizedBox(height: KvlSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Foot(label: 'Change Mantra', icon: Icons.music_note_rounded, onTap: () => context.go('/programs')),
              _Foot(label: 'Session Stats', icon: Icons.bar_chart_rounded, onTap: () => context.push('/daily-progress/$programId')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.state});
  final PracticeState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(icon: Icons.local_fire_department_rounded, value: '${state.streak}', label: 'Streak')),
        const SizedBox(width: 6),
        Expanded(
          child: _Stat(
            icon: Icons.calendar_today_rounded,
            value: IndianNumberFormat.format(state.todaysTotal),
            label: 'Today',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _Stat(
            icon: Icons.gps_fixed_rounded,
            value: IndianNumberFormat.compact(state.program.dailyTarget),
            label: 'Daily target',
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.sm, vertical: KvlSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: KvlColors.primarySoft, borderRadius: KvlRadius.brSM),
            alignment: Alignment.center,
            child: Icon(icon, color: KvlColors.primaryDeep, size: 12),
          ),
          const SizedBox(height: 4),
          Text(value, style: KvlText.ui(13, FontWeight.w700)),
          Text(label, style: KvlText.muted(9.5)),
        ],
      ),
    );
  }
}

class _Foot extends StatelessWidget {
  const _Foot({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: KvlRadius.brSM,
      child: Padding(
        padding: const EdgeInsets.all(KvlSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: KvlColors.inkSoft),
            const SizedBox(width: 6),
            Text(label, style: KvlText.ui(11, FontWeight.w500).copyWith(color: KvlColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _MicErrorCard extends StatelessWidget {
  const _MicErrorCard({
    required this.message,
    required this.showOpenSettings,
    required this.onOpenSettings,
    required this.onSwitchManual,
    required this.onDismiss,
  });

  final String message;
  final bool showOpenSettings;
  final VoidCallback onOpenSettings;
  final VoidCallback onSwitchManual;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      variant: KvlCardVariant.warm,
      border: Border.all(color: KvlColors.primary.withValues(alpha: .4)),
      padding: const EdgeInsets.all(KvlSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_off_rounded, color: KvlColors.primaryDeep, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Microphone needed', style: KvlText.ui(13, FontWeight.w600))),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(message, style: KvlText.caption(12).copyWith(height: 1.4)),
          const SizedBox(height: KvlSpacing.sm),
          Row(
            children: [
              if (showOpenSettings)
                Expanded(child: KvlButton(label: 'Open Settings', onPressed: onOpenSettings))
              else
                Expanded(child: KvlButton(label: 'Try Voice Again', onPressed: onDismiss)),
              const SizedBox(width: 8),
              Expanded(
                child: KvlButton(
                  variant: KvlButtonVariant.secondary,
                  label: 'Use Manual',
                  onPressed: onSwitchManual,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModalitySelector extends StatelessWidget {
  const _ModalitySelector({
    required this.value,
    required this.enabled,
    required this.voiceEnabled,
    required this.onChanged,
  });
  final SessionModality value;
  final bool enabled;
  final bool voiceEnabled;
  final ValueChanged<SessionModality> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: KvlColors.primaryGhost, borderRadius: KvlRadius.brSM),
      child: Row(
        children: [
          _Pill(
            label: 'Manual',
            icon: Icons.touch_app_rounded,
            selected: value == SessionModality.manual,
            onTap: enabled ? () => onChanged(SessionModality.manual) : null,
          ),
          if (voiceEnabled)
            _Pill(
              label: 'Voice',
              icon: Icons.mic_rounded,
              selected: value == SessionModality.voice,
              onTap: enabled ? () => onChanged(SessionModality.voice) : null,
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, required this.selected, this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: KvlRadius.brSM,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? KvlColors.primary : Colors.transparent,
            borderRadius: KvlRadius.brSM,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: selected ? Colors.white : KvlColors.inkSoft),
              const SizedBox(width: 6),
              Text(label,
                  style: KvlText.ui(11, FontWeight.w600)
                      .copyWith(color: selected ? Colors.white : KvlColors.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}
