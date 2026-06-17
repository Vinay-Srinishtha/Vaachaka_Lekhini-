import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/remote_config/remote_config.dart';
import '../../../core/remote_config/remote_config_keys.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../programs/domain/program.dart';
import '../../settings/domain/settings_repository.dart';
import '../../../l10n/l10n.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider).value;
    final programsAsync = ref.watch(programsForActiveProfileProvider);
    final programs = programsAsync.value ?? const <Program>[];
    final activePrograms = programs
        .where((program) => !program.isCompleted)
        .toList();
    final recent = activePrograms.isEmpty ? null : activePrograms.first;

    final greeting = (profile == null || profile.name.trim().isEmpty)
        ? context.l10n.welcomeGreeting
        : context.l10n.welcomeGreetingUser(profile.name.trim());
    final subline = activePrograms.isEmpty
        ? context.l10n.homeSublineEmpty
        : context.l10n.homeSublineActive(activePrograms.length);
    final points = ref.watch(rewardTotalProvider).value ?? 0;

    return SafeArea(
      top: false,
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final tight = height < 680;
          final compact = height < 740;
          final side = tight ? KvlSpacing.md : KvlSpacing.lg;
          final gap = tight
              ? KvlSpacing.xs
              : (compact ? KvlSpacing.sm : KvlSpacing.md);
          final headerGap = tight
              ? KvlSpacing.sm
              : (compact ? KvlSpacing.md : KvlSpacing.xl);
          final actionHeight = tight ? 46.0 : (compact ? 50.0 : 54.0);
          final cameraGap = MediaQuery.viewPaddingOf(
            context,
          ).top.clamp(44.0, 56.0);
          final topInset = cameraGap + (tight ? KvlSpacing.xs : KvlSpacing.sm);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              side,
              topInset,
              side,
              tight ? KvlSpacing.sm : KvlSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeHeader(
                  greeting: greeting,
                  subline: subline,
                  initial: profile?.initials ?? '?',
                  compact: compact,
                  onProfileTap: () => context.push(KvlRoute.profile),
                  milestoneCompleted: programs.where((p) => p.isGoalReached).length,
                  milestoneTotal: programs.length,
                ),
                SizedBox(height: headerGap),
                _RewardPointsTile(points: points, compact: compact),
                if (recent != null) ...[
                  SizedBox(height: gap),
                  _DailyReminder(program: recent, compact: compact),
                ],
                SizedBox(height: gap),
                Expanded(
                  child: _HeroQuote(compact: compact, tight: tight),
                ),
                SizedBox(height: gap),
                _HomeActionButton(
                  label: recent == null
                      ? context.l10n.quickStartPractice
                      : context.l10n.continuePractice,
                  icon: Icons.play_circle_outline_rounded,
                  primary: true,
                  height: actionHeight,
                  onPressed: () {
                    if (recent != null) {
                      context.push('${KvlRoute.practice}/${recent.id}');
                    } else {
                      context.push(KvlRoute.quickStart);
                    }
                  },
                ),
                SizedBox(height: gap),
                _HomeActionButton(
                  label: programs.isEmpty
                      ? context.l10n.browseMantras
                      : context.l10n.selectFromPrograms,
                  height: actionHeight,
                  onPressed: () => context.go(
                    programs.isEmpty
                        ? KvlRoute.mantraSelection
                        : KvlRoute.programs,
                  ),
                ),
                SizedBox(height: gap),
                _HomeActionButton(
                  label: context.l10n.createNewProgram,
                  height: actionHeight,
                  onPressed: () => context.push(KvlRoute.mantraSelection),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.subline,
    required this.initial,
    required this.compact,
    required this.onProfileTap,
    required this.milestoneCompleted,
    required this.milestoneTotal,
  });

  final String greeting;
  final String subline;
  final String initial;
  final bool compact;
  final VoidCallback onProfileTap;
  final int milestoneCompleted;
  final int milestoneTotal;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 46.0 : 52.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    greeting,
                    maxLines: 1,
                    style: KvlText.title(compact ? 20 : 22),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subline,
                    maxLines: 1,
                    style: KvlText.caption(
                      compact ? 13.5 : 15,
                    ).copyWith(color: KvlColors.inkSoft),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: KvlSpacing.md),
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(28),
          child: MilestoneRing(
            completed: milestoneCompleted,
            total: milestoneTotal,
            strokeWidth: 2.5,
            gap: 2.5,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFB572), KvlColors.primary],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: KvlText.ui(
                  20,
                  FontWeight.w700,
                ).copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardPointsTile extends StatelessWidget {
  const _RewardPointsTile({required this.points, required this.compact});
  final int points;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => GoRouter.of(context).go(KvlRoute.store),
      borderRadius: KvlRadius.brLG,
      child: Container(
        padding: EdgeInsets.all(compact ? KvlSpacing.sm : KvlSpacing.md),
        decoration: BoxDecoration(
          color: KvlColors.surfaceAlt,
          borderRadius: KvlRadius.brLG,
          border: Border.all(color: KvlColors.rule),
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 36 : 44,
              height: compact ? 36 : 44,
              decoration: const BoxDecoration(
                color: KvlColors.primaryGhost,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.workspace_premium_outlined,
                color: KvlColors.primary,
                size: 25,
              ),
            ),
            const SizedBox(width: KvlSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.rewardPoints,
                    style: KvlText.caption(
                      compact ? 10.5 : 12,
                    ).copyWith(color: KvlColors.inkSoft),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    IndianNumberFormat.format(points),
                    style: KvlText.ui(
                      compact ? 17 : 22,
                      FontWeight.w700,
                    ).copyWith(color: KvlColors.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(width: KvlSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KvlSpacing.md,
                vertical: KvlSpacing.xs,
              ),
              decoration: BoxDecoration(
                borderRadius: KvlRadius.brPill,
                border: Border.all(color: KvlColors.primary, width: 1.4),
                color: KvlColors.surface,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.storeButton,
                    style: KvlText.caption(12.5).copyWith(
                      color: KvlColors.primaryDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: KvlSpacing.xs),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: KvlColors.primaryDeep,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyReminder extends ConsumerWidget {
  const _DailyReminder({required this.program, required this.compact});
  final Program program;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mantra = ref.watch(mantraByIdProvider(program.mantraId));
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    return KvlCard(
      variant: KvlCardVariant.warm,
      border: Border.all(color: KvlColors.primarySoft),
      padding: EdgeInsets.all(compact ? KvlSpacing.sm : KvlSpacing.md),
      onTap: () => context.go(KvlRoute.practice),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: KvlRadius.brMD,
            child: Image.asset(
              'assets/mantras/rama_quote_banner.png',
              width: compact ? 50 : 64,
              height: compact ? 50 : 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: KvlSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.dailyPractice,
                  style: KvlText.caption(11.5).copyWith(
                    color: KvlColors.primaryDeep,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: KvlSpacing.xs),
                Text(
                  mantra?.name.displayForLanguage(settings.mantraLanguageCode) ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KvlText.ui(
                    compact ? 14.5 : 17,
                    FontWeight.w700,
                  ).copyWith(color: KvlColors.inkSoft),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.continueGoal(program.targetDays),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KvlText.caption(13).copyWith(color: KvlColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: KvlSpacing.sm),
          Container(
            width: compact ? 44 : 52,
            height: compact ? 44 : 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: KvlColors.primaryGradient,
              boxShadow: KvlShadows.primaryGlow,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroQuote extends ConsumerWidget {
  const _HeroQuote({required this.compact, required this.tight});

  final bool compact;
  final bool tight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(remoteConfigProvider).value ?? RemoteConfig.empty;
    final quote = cfg.stringFlag(RemoteConfigKeys.dailyQuoteTelugu, fallback: '');
    final attribution = cfg.stringFlag(RemoteConfigKeys.dailyQuoteAttribution, fallback: '');
    // Don't render the card if the DB has no quote configured yet.
    if (quote.isEmpty) return const SizedBox.shrink();
    return KvlCard(
      variant: KvlCardVariant.warm,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: KvlRadius.brLG,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/mantras/rama_quote_banner.png',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0x33000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? KvlSpacing.md : KvlSpacing.lg,
                tight ? KvlSpacing.xs : KvlSpacing.sm,
                compact ? KvlSpacing.md : KvlSpacing.lg,
                tight ? KvlSpacing.xs : KvlSpacing.sm,
              ),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: KvlSpacing.xl),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '"$quote"',
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: KvlText.mantraTelugu(
                                tight ? 14.5 : (compact ? 16 : 18),
                              ).copyWith(height: 1.35),
                            ),
                          ),
                        ),
                        if (attribution.isNotEmpty) ...[
                          SizedBox(height: tight ? KvlSpacing.xs : KvlSpacing.sm),
                          Text(
                            '— $attribution',
                            style: KvlText.muted(
                              tight ? 11.5 : 14,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      final shareText = attribution.isNotEmpty
                          ? '"$quote"\n— $attribution\n\nShared via Vachika Lekhini 🙏'
                          : '"$quote"\n\nShared via Vachika Lekhini 🙏';
                      SharePlus.instance.share(ShareParams(text: shareText));
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: KvlColors.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.share_outlined,
                        color: KvlColors.inkSoft,
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeActionButton extends StatefulWidget {
  const _HomeActionButton({
    required this.label,
    required this.onPressed,
    required this.height,
    this.icon,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final double height;
  final IconData? icon;
  final bool primary;

  @override
  State<_HomeActionButton> createState() => _HomeActionButtonState();
}

class _HomeActionButtonState extends State<_HomeActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.primary ? Colors.white : KvlColors.primaryDeep;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? .985 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.primary ? KvlColors.primary : KvlColors.surfaceAlt,
            gradient: widget.primary ? KvlColors.primaryGradient : null,
            borderRadius: KvlRadius.brLG,
            border: widget.primary
                ? null
                : Border.all(color: KvlColors.primary, width: 1.5),
            boxShadow: widget.primary ? KvlShadows.primaryGlow : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: 22),
                const SizedBox(width: KvlSpacing.sm),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    style: KvlText.ui(15, FontWeight.w600).copyWith(color: fg),
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
