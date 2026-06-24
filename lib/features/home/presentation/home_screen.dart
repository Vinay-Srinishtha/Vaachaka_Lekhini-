import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/kvl_profile_avatar.dart';
import '../../../core/widgets/widgets.dart';
import '../../global_sadhana/domain/global_sadhana.dart';
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
    final todayTotal = ref.watch(todayChantTotalProvider).value ?? 0;
    final greeting = (profile == null || profile.name.trim().isEmpty)
        ? context.l10n.welcomeGreeting
        : context.l10n.welcomeGreetingUser(profile.name.trim());
    final subline = isLoadingPrograms
        ? context.l10n.homeSublineEmpty
        : (activePrograms.isEmpty && todayTotal == 0)
            ? context.l10n.homeSublineEmpty
            : 'Today you chanted ${IndianNumberFormat.format(todayTotal)} times';
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

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              // Keep content at least screen-tall so it never looks half-empty.
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
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
                    // Bulletin — truly edge-to-edge.
                    Builder(
                      builder: (ctx) {
                        final w = MediaQuery.of(ctx).size.width;
                        return SizedBox(
                          height: 34,
                          child: OverflowBox(
                            minWidth: w,
                            maxWidth: w,
                            minHeight: 34,
                            maxHeight: 34,
                            alignment: Alignment.center,
                            child: _Bulletin(
                              text: ref.watch(appSettingsProvider).value?.bulletinText ??
                                  _kDefaultBulletinText,
                            ),
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
                          : _ProgramCarousel(
                              key: const ValueKey('carousel'),
                              programs: activePrograms,
                              compact: compact,
                            ),
                    ),
                    SizedBox(height: gap),
                    _GlobalSadhanaSection(compact: compact),
                    SizedBox(height: gap),
                    AspectRatio(
                      aspectRatio: 4 / 5,
                      child: _HeroQuote(compact: compact, tight: tight),
                    ),
                  ],
                ),
              ),
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
// Bulletin — edge-to-edge orange scrolling ticker
// ─────────────────────────────────────────────────────────────────────────────

/// Fallback banner text when the admin hasn't set a custom message and stats
/// mode isn't active.
const _kDefaultBulletinText =
    '  🕉  Join Global Sadhanas   •   Chant Together, Grow Together   •   🙏  Thousands Practicing Now   •   Start Your Journey Today   •   ✨  Join Global Sadhanas   •   Chant Together, Grow Together   •   ';

class _Bulletin extends StatefulWidget {
  const _Bulletin({required this.text});
  final String text;

  @override
  State<_Bulletin> createState() => _BulletinState();
}

class _BulletinState extends State<_Bulletin>
    with SingleTickerProviderStateMixin {
  // Pad with spacing so the loop has a gap between repetitions.
  String get _text => '   ${widget.text.trim()}   •   ';

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
    // Use the mantra language (the script the user chants in) so the quote
    // appears in the same language as the mantra — not the UI language.
    // Falls back through: settings.mantraLanguageCode → profile.mantraLanguage → UI lang.
    final settings = ref.watch(settingsProvider).value;
    final quoteLanguage = settings?.mantraLanguageCode
        ?? profile?.mantraLanguage
        ?? settings?.languageCode;
    // Daily quote: deterministic for today, targeted to user's primary mantra.
    final chosen = ref.watch(dailyQuoteProvider);
    if (chosen == null) return const SizedBox.shrink();

    final quoteText = chosen.textFor(quoteLanguage) ?? '';
    final attribution = chosen.sourceFor(quoteLanguage) ?? '';
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
                    onTap: () => _shareQuote(
                      context,
                      quoteText: quoteText,
                      attribution: attribution,
                      imageUrl: chosen.imageUrl,
                      appLink: appSettings?.effectiveAppLink ?? '',
                      template: appSettings?.shareQuoteText,
                    ),
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
// Quote share helper — downloads image to a temp file then shares as XFile
// ─────────────────────────────────────────────────────────────────────────────

// Guard against double-taps: share_plus is async (image download can take
// seconds) so without this every tap during the wait fires another share sheet.
bool _shareInProgress = false;

Future<void> _shareQuote(
  BuildContext context, {
  required String quoteText,
  required String attribution,
  required String? imageUrl,
  required String appLink,
  required String? template,
}) async {
  if (_shareInProgress) return;
  _shareInProgress = true;
  try {
  String shareText;
  if (template != null && template.isNotEmpty) {
    shareText = template
        .replaceAll('{quote}', quoteText)
        .replaceAll('{attribution}', attribution)
        .replaceAll('{app_link}', appLink);
  } else {
    shareText = attribution.isNotEmpty
        ? '"$quoteText"\n— $attribution'
        : '"$quoteText"';
    shareText += '\n\nShared via Vachika Lekhini 🙏';
    if (appLink.isNotEmpty) shareText += '\n$appLink';
  }

  if (imageUrl == null || imageUrl.isEmpty) {
    await SharePlus.instance.share(ShareParams(text: shareText));
  } else {
    try {
      final tmpDir = await getTemporaryDirectory();
      final ext = imageUrl.contains('.png') ? 'png' : 'jpg';
      final rawFile = File('${tmpDir.path}/quote_share_raw.$ext');
      await Dio().download(imageUrl, rawFile.path);

      // Burn the app link onto the image so it's visible on every platform.
      final stamped = await _stampLinkOnImage(
        rawFile.readAsBytesSync(),
        appLink,
      );
      final outFile = File('${tmpDir.path}/quote_share.png');
      await outFile.writeAsBytes(stamped);

      // Copy full caption to clipboard — Instagram/Facebook ignore text in share sheet.
      await Clipboard.setData(ClipboardData(text: shareText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Caption copied — paste it in Instagram/Facebook.'),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await SharePlus.instance.share(ShareParams(
        files: [XFile(outFile.path, mimeType: 'image/png')],
      ));
    } catch (_) {
      await SharePlus.instance.share(ShareParams(text: shareText));
    }
  }
  } finally {
    _shareInProgress = false;
  }
}

// Draws a semi-transparent pill at the bottom of the image containing the URL
// so it's visible on every platform. Viewers can tap/long-press to open it.
Future<Uint8List> _stampLinkOnImage(Uint8List imageBytes, String url) async {
  final codec = await ui.instantiateImageCodec(imageBytes);
  final frame = await codec.getNextFrame();
  final src = frame.image;

  final w = src.width.toDouble();
  final h = src.height.toDouble();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Draw original image
  canvas.drawImage(src, Offset.zero, Paint());

  // Pill dimensions
  const pillH = 48.0;
  const hPad = 20.0;
  const vPad = 14.0;
  final pillW = w - hPad * 2;
  final pillY = h - pillH - vPad;

  // Semi-transparent dark pill background
  final pillPaint = Paint()..color = const Color(0xCC000000);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(hPad, pillY, pillW, pillH),
      const Radius.circular(24),
    ),
    pillPaint,
  );

  // URL text centred in pill
  final textPainter = TextPainter(
    text: TextSpan(
      text: url,
      style: const TextStyle(
        color: Color(0xFF90CAF9), // light-blue — looks like a link
        fontSize: 18,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
        decorationColor: Color(0xFF90CAF9),
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: pillW - 24);

  textPainter.paint(
    canvas,
    Offset(
      hPad + (pillW - textPainter.width) / 2,
      pillY + (pillH - textPainter.height) / 2,
    ),
  );

  final picture = recorder.endRecording();
  final img = await picture.toImage(src.width, src.height);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

// ─────────────────────────────────────────────────────────────────────────────
// Global Sadhana section — card below the hero quote
// ─────────────────────────────────────────────────────────────────────────────

class _GlobalSadhanaSection extends ConsumerWidget {
  const _GlobalSadhanaSection({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sadhanas = ref.watch(activeGlobalSadhanaProvider).value ?? [];
    if (sadhanas.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? KvlSpacing.xs : KvlSpacing.sm),
      child: sadhanas.length == 1
          ? _GlobalSadhanaCard(sadhana: sadhanas.first, compact: compact)
          : _GlobalSadhanaCarousel(sadhanas: sadhanas, compact: compact),
    );
  }
}

/// Auto-advancing carousel shown when more than one active global sadhana
/// exists. Cycles to the next card every 5 seconds; manual swipes reset the
/// timer so the user isn't yanked away mid-look.
class _GlobalSadhanaCarousel extends StatefulWidget {
  const _GlobalSadhanaCarousel({required this.sadhanas, required this.compact});
  final List<GlobalSadhana> sadhanas;
  final bool compact;

  @override
  State<_GlobalSadhanaCarousel> createState() => _GlobalSadhanaCarouselState();
}

class _GlobalSadhanaCarouselState extends State<_GlobalSadhanaCarousel> {
  late final PageController _ctrl;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_ctrl.hasClients) return;
      final count = widget.sadhanas.length;
      if (count <= 1) return;
      final next = (_page + 1) % count;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final hasAnyImage = widget.sadhanas
        .any((s) => s.imageUrl != null && s.imageUrl!.isNotEmpty);
    // PageView needs a bounded height; size for the tallest card layout so
    // neither image nor text-only cards overflow.
    final height = hasAnyImage
        ? (compact ? 210.0 : 240.0)
        : (compact ? 140.0 : 158.0);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: NotificationListener<ScrollNotification>(
            // Any drag the user starts resets the 5s clock.
            onNotification: (n) {
              if (n is UserScrollNotification) _startAutoScroll();
              return false;
            },
            child: PageView.builder(
              controller: _ctrl,
              itemCount: widget.sadhanas.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _GlobalSadhanaCard(
                sadhana: widget.sadhanas[i],
                compact: compact,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.sadhanas.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? _GlobalSadhanaCard.accent
                    : _GlobalSadhanaCard.accent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _GlobalSadhanaCard extends StatelessWidget {
  const _GlobalSadhanaCard({required this.sadhana, required this.compact});
  final GlobalSadhana sadhana;
  final bool compact;

  static const accent = Color(0xFFE8650A);
  static const _accent = accent;

  @override
  Widget build(BuildContext context) {
    final hasImage = sadhana.imageUrl != null && sadhana.imageUrl!.isNotEmpty;

    return GestureDetector(
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
                AspectRatio(
                  aspectRatio: 16 / 9,
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
      );
  }
}
