import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/kvl_profile_avatar.dart';
import '../../../core/widgets/widgets.dart';
import '../../profiles/domain/profile.dart';
import '../../programs/domain/program.dart';
import '../../settings/domain/settings_repository.dart';
import '../../../l10n/l10n.dart';
import '../domain/quote.dart';

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
    final todayTotal = ref.watch(todayChantTotalProvider).value ?? 0;
    final greeting = (profile == null || profile.name.trim().isEmpty)
        ? context.l10n.welcomeGreeting
        : context.l10n.welcomeGreetingUser(profile.name.trim());
    final subline = isLoadingPrograms
        ? context.l10n.homeSublineEmpty
        : todayTotal > 0
            ? 'Today you chanted ${IndianNumberFormat.format(todayTotal)} times'
            : activePrograms.isEmpty
                ? context.l10n.homeSublineEmpty
                : '${activePrograms.length} Sadhana${activePrograms.length == 1 ? '' : 's'} Active';
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
                        width: mq.size.width * 1.5,
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
                  // Always show the carousel — it includes the "Start a new
                  // Sadhana" card even when there are no active programs.
                  child: isLoadingPrograms
                      ? _ProgramCardShimmer(key: const ValueKey('shimmer'), compact: compact)
                      : _ProgramCarousel(
                          key: const ValueKey('carousel'),
                          programs: activePrograms,
                          compact: compact,
                        ),
                ),
                SizedBox(height: gap),
                Expanded(
                  child: _HeroQuote(compact: compact, tight: tight),
                ),
                SizedBox(height: gap),
                _GlobalSadhanaSection(compact: compact),
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

  @override
  void dispose() {
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
          builder: (_, child) => CustomPaint(
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
  const _ProgramCarousel({super.key, required this.programs, required this.compact});
  final List<Program> programs;
  final bool compact;

  @override
  State<_ProgramCarousel> createState() => _ProgramCarouselState();
}

class _ProgramCarouselState extends State<_ProgramCarousel> {
  late final PageController _ctrl;
  Timer? _autoTimer;
  int _page = 0;

  // Total logical items = active programs + 1 "add new" card at the end.
  int get _totalItems => widget.programs.length + 1;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(initialPage: 0);
    _page = 0;
    _startTimer();
  }

  @override
  void didUpdateWidget(_ProgramCarousel old) {
    super.didUpdateWidget(old);
    if (old.programs.length != widget.programs.length) {
      _startTimer();
    }
  }

  void _startTimer() {
    _autoTimer?.cancel();
    _autoTimer = null;
    if (_totalItems > 1) {
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
    // Dots: one per program + one for the "add" card.
    final dotCount = _totalItems;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: cardH,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i % _totalItems),
            itemBuilder: (ctx, i) {
              final idx = count > 0 ? i % _totalItems : _totalItems - 1;
              if (idx < count) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: _ProgramCard(program: widget.programs[idx], compact: widget.compact),
                );
              }
              // "Add new Sadhana" promo card.
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _NewSadhanaCard(compact: widget.compact),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dotCount, (i) {
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Start a new Sadhana" promo card — always last in the carousel
// ─────────────────────────────────────────────────────────────────────────────

class _NewSadhanaCard extends StatelessWidget {
  const _NewSadhanaCard({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 46.0 : 56.0;
    return GestureDetector(
      onTap: () => context.push(KvlRoute.mantraSelection),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3E8), Color(0xFFFFE4C8)],
          ),
          borderRadius: KvlRadius.brLG,
          border: Border.all(
            color: KvlColors.primary.withValues(alpha: 0.35),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: KvlColors.primary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: KvlSpacing.md,
          vertical: compact ? KvlSpacing.sm : 12,
        ),
        child: Row(
          children: [
            // Plus icon in a circle — matches the program ring style
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KvlColors.primary.withValues(alpha: 0.10),
                border: Border.all(
                  color: KvlColors.primary.withValues(alpha: 0.30),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                color: KvlColors.primary,
                size: iconSize * 0.46,
              ),
            ),
            const SizedBox(width: KvlSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start a new Sadhana',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 13.5 : 15,
                      fontWeight: FontWeight.w700,
                      color: KvlColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Choose a mantra & set your goal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      color: KvlColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: KvlSpacing.sm),
            Container(
              width: compact ? 32 : 38,
              height: compact ? 32 : 38,
              decoration: BoxDecoration(
                color: KvlColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: compact ? 15 : 17,
              ),
            ),
          ],
        ),
      ),
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
                            errorBuilder: (ctx, err, st) => _fallbackThumb(imgSize - 12),
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
                          (program.daysElapsed + 1).clamp(1, program.targetDays), program.targetDays),
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
  const _ProgramCardShimmer({super.key, required this.compact});
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
      builder: (_, snap) {
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
    final appSettings = ref.watch(appSettingsProvider).value;
    final profile = ref.watch(activeProfileProvider).value;
    final mantraLanguage = profile?.mantraLanguage;
    final quotes = ref.watch(quotesProvider).value ?? const [];

    // Pick the first displayable quote for this language; fall back to any.
    Quote? chosen;
    for (final q in quotes) {
      if ((q.textFor(mantraLanguage) ?? '').isNotEmpty) {
        chosen = q;
        break;
      }
    }
    if (chosen == null) return const SizedBox.shrink();

    final quoteText = chosen.textFor(mantraLanguage) ?? '';
    final attribution = chosen.sourceFor(mantraLanguage) ?? '';
    final hasImage = chosen.imageUrl != null && chosen.imageUrl!.isNotEmpty;

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
                  hasImage
                      ? CachedNetworkImage(
                          imageUrl: chosen.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Image.asset(
                            'assets/mantras/rama_quote_banner.png',
                            fit: BoxFit.cover,
                          ),
                          errorWidget: (ctx, url, err) => Image.asset(
                            'assets/mantras/rama_quote_banner.png',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
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
                              '"$quoteText"',
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
                            .replaceAll('{quote}', quoteText)
                            .replaceAll('{attribution}', attribution)
                            .replaceAll('{app_link}', appLink);
                      } else {
                        shareText = attribution.isNotEmpty
                            ? '"$quoteText"\n— $attribution\n\nShared via Vachika Lekhini 🙏'
                            : '"$quoteText"\n\nShared via Vachika Lekhini 🙏';
                        if (appLink.isNotEmpty) shareText += '\n$appLink';
                      }
                      SharePlus.instance.share(ShareParams(
                        text: shareText,
                        uri: chosen!.imageUrl != null
                            ? Uri.tryParse(chosen.imageUrl!)
                            : null,
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
// Global Sadhana section — card below the hero quote
// ─────────────────────────────────────────────────────────────────────────────

class _GlobalSadhanaSection extends ConsumerWidget {
  const _GlobalSadhanaSection({required this.compact});
  final bool compact;

  static const _accent = Color(0xFFE8650A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sadhanas = ref.watch(activeGlobalSadhanaProvider).value ?? [];
    if (sadhanas.isEmpty) return const SizedBox.shrink();

    final sadhana = sadhanas.first;
    final hasImage = sadhana.imageUrl != null && sadhana.imageUrl!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? KvlSpacing.xs : KvlSpacing.sm),
      child: GestureDetector(
        onTap: () => context.push('${KvlRoute.globalSadhana}/${sadhana.id}'),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E8),
            borderRadius: KvlRadius.brLG,
            border: Border.all(
              color: _accent.withValues(alpha: 0.30),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Banner image (if available) ─────────────────────────────
              if (hasImage)
                SizedBox(
                  height: compact ? 100 : 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: sadhana.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          color: _accent.withValues(alpha: 0.08),
                        ),
                        errorWidget: (ctx, url, err) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFF0D4), Color(0xFFFFDBA8)],
                            ),
                          ),
                          child: Icon(Icons.public_rounded,
                              color: _accent.withValues(alpha: 0.35), size: 40),
                        ),
                      ),
                      // Gradient scrim so text is legible on any image
                      Positioned(
                        left: 0, right: 0, bottom: 0,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Label over the image
                      Positioned(
                        left: compact ? 10 : 14,
                        bottom: compact ? 8 : 10,
                        right: compact ? 10 : 14,
                        child: Row(
                          children: [
                            Text(
                              '🕉  Global Sadhana',
                              style: KvlText.caption(compact ? 10 : 11).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: compact ? 26 : 30,
                              height: compact ? 26 : 30,
                              decoration: const BoxDecoration(
                                color: _accent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: compact ? 13 : 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Body (title + progress) ─────────────────────────────────
              Padding(
                padding: EdgeInsets.all(compact ? KvlSpacing.sm + 2 : KvlSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header row (only when no image banner)
                    if (!hasImage)
                      Row(
                        children: [
                          Container(
                            width: compact ? 36 : 40,
                            height: compact ? 36 : 40,
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.public_rounded,
                                color: _accent, size: compact ? 18 : 20),
                          ),
                          const SizedBox(width: KvlSpacing.sm),
                          Expanded(
                            child: Text(
                              '🕉  Global Sadhana',
                              style: KvlText.caption(compact ? 10 : 11).copyWith(
                                color: _accent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          Container(
                            width: compact ? 28 : 32,
                            height: compact ? 28 : 32,
                            decoration: const BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: compact ? 14 : 16),
                          ),
                        ],
                      ),
                    if (!hasImage) const SizedBox(height: KvlSpacing.xs),
                    Text(
                      sadhana.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: KvlText.ui(compact ? 13 : 14, FontWeight.w700)
                          .copyWith(color: KvlColors.ink),
                    ),
                    const SizedBox(height: KvlSpacing.sm),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: sadhana.progress,
                        minHeight: 6,
                        backgroundColor: _accent.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${IndianNumberFormat.format(sadhana.currentCount)} / ${IndianNumberFormat.format(sadhana.targetCount)}',
                          style: KvlText.caption(compact ? 10 : 11)
                              .copyWith(color: KvlColors.inkSoft),
                        ),
                        Text(
                          '${sadhana.participantCount} joined',
                          style: KvlText.caption(compact ? 10 : 11)
                              .copyWith(color: KvlColors.inkSoft),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
