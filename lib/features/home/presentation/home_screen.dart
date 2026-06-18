import 'dart:async';

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
import '../../../core/widgets/kvl_profile_avatar.dart';
import '../../../core/widgets/widgets.dart';
import '../../profiles/domain/profile.dart';
import '../../programs/domain/program.dart';
import '../../settings/domain/settings_repository.dart';
import '../../../l10n/l10n.dart';

double _profileCompletion(Profile? profile) {
  if (profile == null) return 0.0;
  int filled = 0;
  const total = 5;
  if (profile.name.trim().isNotEmpty) filled++;
  if (profile.gender != null) filled++;
  if (profile.birthYear != null) filled++;
  if (profile.motherTongue != null) filled++;
  if (profile.avatarSeed != null && profile.avatarSeed!.isNotEmpty) filled++;
  return filled / total;
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider).value;
    final programsAsync = ref.watch(programsForActiveProfileProvider);
    final programs = programsAsync.value ?? const <Program>[];
    final activePrograms = programs.where((p) => !p.isCompleted).toList();

    final isLoadingPrograms = programsAsync.isLoading && programsAsync.value == null;
    final greeting = (profile == null || profile.name.trim().isEmpty)
        ? context.l10n.welcomeGreeting
        : context.l10n.welcomeGreetingUser(profile.name.trim());
    final subline = isLoadingPrograms
        ? context.l10n.homeSublineEmpty
        : activePrograms.isEmpty
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
          const side = 10.0;
          final gap = tight
              ? KvlSpacing.xs
              : (compact ? KvlSpacing.sm : KvlSpacing.md);
          final headerGap = tight
              ? KvlSpacing.xs
              : (compact ? KvlSpacing.md : KvlSpacing.xl);
          final cameraGap = MediaQuery.viewPaddingOf(context).top.clamp(40.0, 52.0);
          final topInset = cameraGap + 4.0;

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
                  profileId: profile?.id ?? '',
                  compact: compact,
                  onProfileTap: () => context.push(KvlRoute.profile),
                  profileCompletion: _profileCompletion(profile),
                ),
                SizedBox(height: headerGap),
                _RewardPointsTile(points: points, compact: compact),
                SizedBox(height: gap),
                // Bulletin — truly edge-to-edge regardless of SafeArea insets.
                // We escape the column padding by measuring from MediaQuery so
                // even devices with horizontal view-padding fill perfectly.
                Builder(
                  builder: (ctx) {
                    final mq = MediaQuery.of(ctx);
                    final leftOffset = mq.viewPadding.left + side;
                    return Transform.translate(
                      offset: Offset(-leftOffset, 0),
                      child: SizedBox(
                        width: mq.size.width,
                        child: const _Bulletin(),
                      ),
                    );
                  },
                ),
                SizedBox(height: gap),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: isLoadingPrograms
                      ? _ProgramCardShimmer(key: const ValueKey('shimmer'), compact: compact)
                      : activePrograms.isNotEmpty
                          ? _ProgramCarousel(key: const ValueKey('carousel'), programs: activePrograms, compact: compact)
                          : const SizedBox.shrink(key: ValueKey('empty')),
                ),
                SizedBox(height: gap),
                Expanded(
                  child: _HeroQuote(compact: compact, tight: tight),
                ),
                SizedBox(height: gap),
                _SadhanaList(compact: compact),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.subline,
    required this.initial,
    required this.profileId,
    required this.compact,
    required this.onProfileTap,
    required this.profileCompletion,
  });

  final String greeting;
  final String subline;
  final String initial;
  final String profileId;
  final bool compact;
  final VoidCallback onProfileTap;
  final double profileCompletion;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 54.0 : 60.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
                    style: KvlText.caption(compact ? 13.5 : 15)
                        .copyWith(color: KvlColors.inkSoft),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: KvlSpacing.md),
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(34),
          child: MilestoneRing.fraction(
            fraction: profileCompletion,
            strokeWidth: 2.5,
            gap: 2.5,
            child: KvlProfileAvatar(
              profileId: profileId,
              initials: initial,
              size: size,
              textSize: 20,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reward points tile
// ─────────────────────────────────────────────────────────────────────────────

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
        padding: EdgeInsets.symmetric(
          horizontal: KvlSpacing.md,
          vertical: compact ? KvlSpacing.xs : KvlSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: KvlColors.surfaceAlt,
          borderRadius: KvlRadius.brLG,
          border: Border.all(color: KvlColors.rule),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_outlined,
                color: KvlColors.primary, size: 22),
            const SizedBox(width: KvlSpacing.sm),
            Text(context.l10n.rewardPoints,
                style: KvlText.caption(12).copyWith(color: KvlColors.inkSoft)),
            const SizedBox(width: KvlSpacing.xs),
            Text(
              IndianNumberFormat.format(points),
              style: KvlText.ui(14, FontWeight.w700).copyWith(color: KvlColors.ink),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: KvlSpacing.md, vertical: KvlSpacing.xs),
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
                  const Icon(Icons.arrow_forward_rounded,
                      color: KvlColors.primaryDeep, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bulletin — edge-to-edge orange scrolling ticker
// ─────────────────────────────────────────────────────────────────────────────

class _Bulletin extends StatefulWidget {
  const _Bulletin();

  @override
  State<_Bulletin> createState() => _BulletinState();
}

class _BulletinState extends State<_Bulletin>
    with SingleTickerProviderStateMixin {
  static const _text =
      '  🕉  Join Global Sadhanas   •   Chant Together, Grow Together   •   🙏  Thousands Practicing Now   •   Start Your Journey Today   •   ✨  Join Global Sadhanas   •   Chant Together, Grow Together   •   ';

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  )..repeat();

  Timer? _autoTimer;

  @override
  void dispose() {
    _autoTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8650A), Color(0xFFD4520A), Color(0xFFE8650A)],
        ),
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            size: Size.infinite,
            painter: _TickerPainter(
              text: _text,
              progress: _ctrl.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TickerPainter extends CustomPainter {
  _TickerPainter({
    required this.text,
    required this.progress,
    required this.style,
  });
  final String text;
  final double progress;
  final TextStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    final totalW = tp.width;
    final offset = -(progress * totalW);
    tp.paint(canvas, Offset(offset, (size.height - tp.height) / 2));
    tp.paint(canvas, Offset(offset + totalW, (size.height - tp.height) / 2));
  }

  @override
  bool shouldRepaint(_TickerPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Program carousel
// ─────────────────────────────────────────────────────────────────────────────

class _ProgramCarousel extends StatefulWidget {
  const _ProgramCarousel({required this.programs, required this.compact});
  final List<Program> programs;
  final bool compact;

  @override
  State<_ProgramCarousel> createState() => _ProgramCarouselState();
}

class _ProgramCarouselState extends State<_ProgramCarousel> {
  late final PageController _ctrl;
  Timer? _autoTimer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.programs.length * 500;
    _ctrl = PageController(initialPage: initial);
    _page = initial % widget.programs.length;
    if (widget.programs.length > 1) {
      _autoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!_ctrl.hasClients) return;
        _ctrl.nextPage(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.programs.length;
    final cardH = widget.compact ? 84.0 : 100.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: cardH,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i % count),
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: _ProgramCard(
                program: widget.programs[i % count],
                compact: widget.compact,
              ),
            ),
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? KvlColors.primary
                      : KvlColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _ProgramCard extends ConsumerWidget {
  const _ProgramCard({required this.program, required this.compact});
  final Program program;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mantra = ref.watch(mantraByIdProvider(program.mantraId));
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final imgUrl = mantra?.previewImageUrl ?? mantra?.imageUrl;
    final name = mantra?.name.displayForLanguage(settings.languageCode) ?? '';
    final imgSize = compact ? 56.0 : 68.0;
    final ringPct = (program.targetDays > 0)
        ? (program.daysElapsed / program.targetDays).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('${KvlRoute.practice}/${program.id}'),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8F0), Color(0xFFFFEDD8)],
          ),
          borderRadius: KvlRadius.brLG,
          border: Border.all(color: KvlColors.primarySoft, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: KvlColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: KvlSpacing.md,
          vertical: compact ? KvlSpacing.sm : 12,
        ),
        child: Row(
          children: [
            SizedBox(
              width: imgSize,
              height: imgSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: ringPct,
                      strokeWidth: 3.5,
                      backgroundColor: KvlColors.primary.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(KvlColors.primary),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(imgSize / 2 - 6),
                    child: imgUrl != null
                        ? Image.network(
                            imgUrl,
                            width: imgSize - 12,
                            height: imgSize - 12,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _a, _b) => _fallbackThumb(imgSize - 12),
                          )
                        : _fallbackThumb(imgSize - 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: KvlSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name.isEmpty ? context.l10n.dailyPractice : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KvlText.ui(compact ? 15.5 : 17, FontWeight.w800)
                        .copyWith(color: KvlColors.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.l10n.continueSadhana,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KvlText.caption(compact ? 12 : 13)
                        .copyWith(color: KvlColors.primaryDeep),
                  ),
                  if (program.targetDays > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.programDayOf(
                          program.daysElapsed + 1, program.targetDays),
                      maxLines: 1,
                      style: KvlText.caption(compact ? 10.5 : 11.5)
                          .copyWith(color: KvlColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: KvlSpacing.sm),
            Container(
              width: compact ? 36 : 42,
              height: compact ? 36 : 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: KvlColors.primaryGradient,
                boxShadow: KvlShadows.primaryGlow,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackThumb(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: KvlColors.primarySoft,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.self_improvement_rounded,
            color: KvlColors.primary, size: size * 0.5),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Program card shimmer — shown while programs are loading
// ─────────────────────────────────────────────────────────────────────────────

class _ProgramCardShimmer extends StatefulWidget {
  const _ProgramCardShimmer({required this.compact});
  final bool compact;

  @override
  State<_ProgramCardShimmer> createState() => _ProgramCardShimmerState();
}

class _ProgramCardShimmerState extends State<_ProgramCardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.compact ? 84.0 : 100.0;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.04 + _anim.value * 0.06;
        return Container(
          height: h,
          decoration: BoxDecoration(
            color: KvlColors.primary.withValues(alpha: opacity),
            borderRadius: KvlRadius.brLG,
            border: Border.all(color: KvlColors.primarySoft, width: 1.2),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: KvlSpacing.md,
            vertical: widget.compact ? KvlSpacing.sm : 12,
          ),
          child: Row(
            children: [
              Container(
                width: widget.compact ? 56 : 68,
                height: widget.compact ? 56 : 68,
                decoration: BoxDecoration(
                  color: KvlColors.primary.withValues(alpha: opacity + 0.04),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: KvlSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: KvlColors.primary.withValues(alpha: opacity + 0.04),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 11,
                      width: 80,
                      decoration: BoxDecoration(
                        color: KvlColors.primary.withValues(alpha: opacity + 0.02),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero quote card
// ─────────────────────────────────────────────────────────────────────────────

class _HeroQuote extends ConsumerWidget {
  const _HeroQuote({required this.compact, required this.tight});
  final bool compact;
  final bool tight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(remoteConfigProvider).value ?? RemoteConfig.empty;
    final appSettings = ref.watch(appSettingsProvider).value;
    final quote =
        cfg.stringFlag(RemoteConfigKeys.dailyQuoteTelugu, fallback: '');
    final attribution =
        cfg.stringFlag(RemoteConfigKeys.dailyQuoteAttribution, fallback: '');
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
                          SizedBox(
                              height:
                                  tight ? KvlSpacing.xs : KvlSpacing.sm),
                          Text(
                            '— $attribution',
                            style: KvlText.muted(tight ? 11.5 : 14)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      final appLink = appSettings?.appDownloadLink ?? '';
                      String shareText;
                      final template = appSettings?.shareQuoteText;
                      if (template != null && template.isNotEmpty) {
                        shareText = template
                            .replaceAll('{quote}', quote)
                            .replaceAll('{attribution}', attribution)
                            .replaceAll('{app_link}', appLink);
                      } else {
                        shareText = attribution.isNotEmpty
                            ? '"$quote"\n— $attribution\n\nShared via Vachika Lekhini 🙏'
                            : '"$quote"\n\nShared via Vachika Lekhini 🙏';
                        if (appLink.isNotEmpty) shareText += '\n$appLink';
                      }
                      final imgUrl = appSettings?.shareQuoteImageUrl;
                      SharePlus.instance.share(ShareParams(
                        text: shareText,
                        uri: imgUrl != null && imgUrl.isNotEmpty ? Uri.tryParse(imgUrl) : null,
                      ));
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
                      child: const Icon(Icons.share_outlined,
                          color: KvlColors.inkSoft, size: 21),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sadhana list — auto-scrolling carousel of active program cards
// ─────────────────────────────────────────────────────────────────────────────

class _SadhanaList extends ConsumerStatefulWidget {
  const _SadhanaList({required this.compact});
  final bool compact;

  @override
  ConsumerState<_SadhanaList> createState() => _SadhanaListState();
}

class _SadhanaListState extends ConsumerState<_SadhanaList> {
  late final PageController _ctrl;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(initialPage: 500);
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_ctrl.hasClients) return;
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final programs = ref.watch(programsForActiveProfileProvider).value ?? [];
    final active = programs.where((p) => !p.isCompleted).toList();
    if (active.isEmpty) return const SizedBox.shrink();

    final cardH = widget.compact ? 84.0 : 100.0;
    return SizedBox(
      height: cardH,
      child: PageView.builder(
        controller: _ctrl,
        itemBuilder: (context, i) {
          final program = active[i % active.length];
          return _ProgramCard(program: program, compact: widget.compact);
        },
      ),
    );
  }
}

