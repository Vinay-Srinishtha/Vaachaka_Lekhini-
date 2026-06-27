import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/navigation/back_navigation.dart';
import '../../../core/sharing/share_cache.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/program.dart';
import '../domain/program_repository.dart';
import '../domain/session.dart';
import '../../settings/domain/settings_repository.dart';
import '../../settings/presentation/profile_screen.dart';
import '../../../l10n/l10n.dart';

class DailyProgressScreen extends ConsumerStatefulWidget {
  const DailyProgressScreen({super.key, required this.programId});
  final String programId;

  @override
  ConsumerState<DailyProgressScreen> createState() =>
      _DailyProgressScreenState();
}

class _DailyProgressScreenState extends ConsumerState<DailyProgressScreen> {
  final _today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  late Future<Program?> _programFuture;
  late Future<Map<DateTime, int>> _countsFuture;
  late Future<DailySummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(programRepositoryProvider);
    _programFuture = repo.getById(widget.programId);
    _countsFuture = _buildCountsFuture();
    _summaryFuture = _buildSummaryFuture();
  }

  Future<Map<DateTime, int>> _buildCountsFuture() {
    final first = DateTime(_month.year, _month.month);
    final last = DateTime(_month.year, _month.month + 1)
        .subtract(const Duration(days: 1));
    return ref
        .read(programRepositoryProvider)
        .sessionCountsByDay(programId: widget.programId, from: first, to: last);
  }

  Future<DailySummary> _buildSummaryFuture() => ref
      .read(programRepositoryProvider)
      .dailySummary(widget.programId, _selected);

  void _shiftMonth(int by) {
    setState(() {
      _month = DateTime(_month.year, _month.month + by);
      _countsFuture = _buildCountsFuture();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionCompletedProvider); // rebuilds when a session finishes
    return FutureBuilder<Program?>(
      future: _programFuture,
      builder: (_, snap) {
        final program = snap.data;
        final settings =
            ref.watch(settingsProvider).value ?? KvlSettings.fallback;
        final mantra = program == null ? null : ref.watch(mantraByIdProvider(program.mantraId));
        final mantraName = mantra?.name.displayForLanguage(settings.languageCode) ?? '';
        final appDownloadLink = ref.watch(appSettingsProvider).value?.effectiveAppLink;
        final title = mantraName.isEmpty
            ? context.l10n.dailyProgressTitle
            : '$mantraName Mantra';

        final goalReached = program != null &&
            program.totalProgress >= program.targetWritings;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF8EE),
                  Color(0xFFFFF0D6),
                  Color(0xFFFFE8C8),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final compact = height < 720;
                  final tight = height < 650;
                  final gap = tight ? KvlSpacing.xs : KvlSpacing.sm;
                  final calendarHeight =
                      (height * (tight ? .40 : compact ? .43 : .46))
                          .clamp(240.0, 340.0);

                  final bottomPad = MediaQuery.paddingOf(context).bottom + 16;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(KvlSpacing.lg, KvlSpacing.sm, KvlSpacing.lg, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Premium mantra title card ──────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: KvlSpacing.md, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFBF5000), Color(0xFFE07020)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE07020)
                                    .withValues(alpha: .28),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Text('🕉',
                                  style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      context.l10n.dailyProgressTitle,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: .75),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (program != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: .20),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: .35)),
                                  ),
                                  child: Text(
                                    '${program.totalProgress} chants',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        SizedBox(height: gap),

                        // ── Calendar card ──────────────────────────────────
                        Container(
                          height: calendarHeight,
                          padding: const EdgeInsets.all(KvlSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFE07020)
                                    .withValues(alpha: .15)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFBF5000)
                                    .withValues(alpha: .08),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: FutureBuilder<Map<DateTime, int>>(
                            future: _countsFuture,
                            builder: (_, snap) {
                              final counts =
                                  snap.data ?? const <DateTime, int>{};
                              final monthHeaderH = tight ? 40.0 : 48.0;
                              final gridH = calendarHeight -
                                  KvlSpacing.md * 2 -
                                  monthHeaderH -
                                  KvlSpacing.sm;
                              return Column(
                                children: [
                                  SizedBox(
                                    height: monthHeaderH,
                                    child: _CalHeader(
                                      month: _month,
                                      compact: compact,
                                      onPrev: () => _shiftMonth(-1),
                                      onNext: () => _shiftMonth(1),
                                    ),
                                  ),
                                  const SizedBox(height: KvlSpacing.sm),
                                  Expanded(
                                    child: _CalGrid(
                                      month: _month,
                                      today: _today,
                                      selected: _selected,
                                      countsByDay: counts,
                                      rowHeight: gridH / 7,
                                      compact: compact,
                                      onTapDay: (d) => setState(() {
                                        _selected = d;
                                        _summaryFuture =
                                            _buildSummaryFuture();
                                      }),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        SizedBox(height: tight ? KvlSpacing.sm : KvlSpacing.md),

                        // ── Daily stats card ───────────────────────────────
                        FutureBuilder<DailySummary>(
                          future: _summaryFuture,
                          builder: (_, snap) {
                            final s = snap.data;
                            return Container(
                              padding: EdgeInsets.all(
                                  tight ? KvlSpacing.md : KvlSpacing.lg),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFF3E0),
                                    Color(0xFFFFE0B2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: const Color(0xFFE07020)
                                        .withValues(alpha: .20)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFBF5000)
                                        .withValues(alpha: .08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 13,
                                        color: Color(0xFFBF5000)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        context.l10n.recitationsOnDate(
                                            DateFormat.yMMMd()
                                                .format(_selected)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: KvlText.ui(
                                          tight ? 11.5 : 12.5,
                                          FontWeight.w700,
                                        ).copyWith(
                                            color: const Color(0xFF7B2D00)),
                                      ),
                                    ),
                                  ]),
                                  SizedBox(
                                      height:
                                          tight ? KvlSpacing.xs : KvlSpacing.sm),
                                  _Row(
                                    label: context.l10n.dailyTarget,
                                    value: s == null
                                        ? '—'
                                        : '${IndianNumberFormat.format(s.dailyTarget)} chants',
                                    compact: tight,
                                  ),
                                  SizedBox(height: tight ? 2 : 4),
                                  _Row(
                                    label: context.l10n.actualAchieved,
                                    value: s == null
                                        ? '—'
                                        : '${IndianNumberFormat.format(s.actualAchieved)} chants',
                                    highlight: (s?.metTarget ?? false)
                                        ? KvlColors.success
                                        : null,
                                    compact: tight,
                                  ),
                                  SizedBox(height: tight ? 2 : 4),
                                  _Row(
                                    label: context.l10n.handwritingUsed,
                                    value: s == null
                                        ? '—'
                                        : (s.usedHandwriting
                                            ? context.l10n.handwritingUsedYes
                                            : context.l10n.handwritingUsedNo),
                                    highlight: s?.usedHandwriting == true
                                        ? KvlColors.success
                                        : null,
                                    compact: tight,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const Spacer(),

                        // ── Primary CTA ────────────────────────────────────
                        if (goalReached)
                          _GradientButton(
                            label: '✓  Goal Achieved',
                            colors: const [Color(0xFF16A34A), Color(0xFF15803D)],
                            enabled: false,
                            onTap: null,
                          )
                        else
                          _GradientButton(
                            label: '▶  ${context.l10n.startPractice}',
                            colors: const [
                              Color(0xFF00897B),
                              Color(0xFF00695C),
                            ],
                            onTap: () =>
                                context.push(KvlRoute.mantraSelection),
                          ),

                        SizedBox(height: tight ? KvlSpacing.sm : KvlSpacing.md),

                        // ── Secondary row ──────────────────────────────────
                        Row(
                          children: [
                            if (program?.isCompleted != true) ...[
                              Expanded(
                                child: _GradientButton(
                                  label: context.l10n.dedicateProgram,
                                  colors: const [
                                    Color(0xFFFF9A3E),
                                    Color(0xFFE07020),
                                  ],
                                  onTap: () => DedicateSheet.show(
                                    context,
                                    programId: widget.programId,
                                    mantraName: mantraName,
                                  ),
                                ),
                              ),
                              const SizedBox(width: KvlSpacing.sm),
                            ],
                            Expanded(
                              child: _OutlineButton(
                                label: context.l10n.shareProgram,
                                icon: Icons.share_rounded,
                                onTap: () => _ShareSheet.show(
                                  context,
                                  mantraName: mantraName,
                                  programId: widget.programId,
                                  progress: program?.totalProgress ?? 0,
                                  shareText: mantra?.shareText,
                                  shareImageUrl: mantra?.shareImageUrl,
                                  appDownloadLink: appDownloadLink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: bottomPad),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            color: KvlColors.ink,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: KvlText.ui(15, FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              context.l10n.dailyProgressTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KvlText.caption(11).copyWith(color: KvlColors.muted),
            ),
          ],
        ),
      ],
    );
  }
}

class _CalHeader extends StatelessWidget {
  const _CalHeader({
    required this.month,
    required this.compact,
    required this.onPrev,
    required this.onNext,
  });
  final DateTime month;
  final bool compact;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: KvlColors.primaryDeep,
          ),
          iconSize: compact ? 26 : 30,
        ),
        Text(
          DateFormat.yMMMM().format(month),
          style: KvlText.ui(compact ? 18 : 22, FontWeight.w500),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(
            Icons.chevron_right_rounded,
            color: KvlColors.primaryDeep,
          ),
          iconSize: compact ? 26 : 30,
        ),
      ],
    );
  }
}

class _CalGrid extends StatelessWidget {
  const _CalGrid({
    required this.month,
    required this.today,
    required this.selected,
    required this.countsByDay,
    required this.rowHeight,
    required this.compact,
    required this.onTapDay,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final Map<DateTime, int> countsByDay;
  final double rowHeight;
  final bool compact;
  final ValueChanged<DateTime> onTapDay;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final firstWeekday = first.weekday % 7; // Sunday-first
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final daysInPrevMonth = DateTime(month.year, month.month, 0).day;

    return Column(
      children: [
        Row(
          children: const [
            _Head('S'),
            _Head('M'),
            _Head('T'),
            _Head('W'),
            _Head('T'),
            _Head('F'),
            _Head('S'),
          ],
        ),
        SizedBox(height: compact ? KvlSpacing.xs : KvlSpacing.sm),
        for (var row = 0; row < 6; row++)
          Row(
            children: List.generate(7, (col) {
              final dayIndex = row * 7 + col - firstWeekday + 1;
              final isInMonth = dayIndex >= 1 && dayIndex <= daysInMonth;
              final displayDay = dayIndex < 1
                  ? daysInPrevMonth + dayIndex
                  : dayIndex > daysInMonth
                  ? dayIndex - daysInMonth
                  : dayIndex;
              final day = isInMonth
                  ? DateTime(month.year, month.month, displayDay)
                  : dayIndex < 1
                  ? DateTime(month.year, month.month - 1, displayDay)
                  : DateTime(month.year, month.month + 1, displayDay);
              final isFuture = isInMonth && day.isAfter(today);
              final isSelected = isInMonth && day == selected;
              final hasActivity = isInMonth && (countsByDay[day] ?? 0) > 0;
              final dateSize = compact ? 38.0 : 44.0;
              final dotSize = compact ? 5.5 : 6.5;
              return Expanded(
                child: GestureDetector(
                  onTap: (isInMonth && !isFuture) ? () => onTapDay(day) : null,
                  behavior: (isInMonth && !isFuture)
                      ? HitTestBehavior.opaque
                      : HitTestBehavior.deferToChild,
                  child: SizedBox(
                    height: rowHeight,
                    child: Center(
                      child: SizedBox(
                        width: dateSize,
                        height: dateSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            if (isSelected)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    color: KvlColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            Text(
                              '$displayDay',
                              style: TextStyle(
                                fontSize: compact ? 16 : 18,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white
                                    : isFuture
                                    ? KvlColors.muted.withValues(alpha: .4)
                                    : isInMonth
                                    ? KvlColors.ink
                                    : KvlColors.muted,
                              ),
                            ),
                            if (hasActivity)
                              Positioned(
                                top: compact ? 1 : 2,
                                right: compact ? 3 : 4,
                                child: Container(
                                  width: dotSize,
                                  height: dotSize,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : KvlColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.letter);
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 15,
            color: KvlColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.highlight,
    this.compact = false,
  });
  final String label;
  final String value;
  final Color? highlight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KvlText.caption(
              compact ? 10.5 : 11.5,
            ).copyWith(color: KvlColors.inkSoft),
          ),
        ),
        const SizedBox(width: KvlSpacing.sm),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: KvlText.ui(
              compact ? 11 : 12,
              FontWeight.w600,
            ).copyWith(color: highlight ?? KvlColors.ink),
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.colors,
    required this.onTap,
    this.enabled = true,
  });
  final String label;
  final List<Color> colors;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.55,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: .30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFE07020).withValues(alpha: .40)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: const Color(0xFFBF5000)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFBF5000),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareSheet {
  static void show(
    BuildContext context, {
    required String mantraName,
    required String programId,
    required int progress,
    String? shareText,
    String? shareImageUrl,
    String? appDownloadLink,
  }) {
    final appLink = appDownloadLink ?? '';
    final String message;
    if (shareText != null && shareText.isNotEmpty) {
      message = shareText
          .replaceAll('{mantra_name}', mantraName)
          .replaceAll('{chant_count}', IndianNumberFormat.format(progress))
          .replaceAll('{app_link}', appLink);
    } else {
      message = 'I am chanting the $mantraName mantra 🙏\n'
          'I have completed ${IndianNumberFormat.format(progress)} chants so far.\n'
          'Join me on Vachika Lekhini!'
          '${appLink.isNotEmpty ? '\n$appLink' : ''}';
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheetContent(message: message, shareImageUrl: shareImageUrl),
    );
  }
}

class _ShareSheetContent extends StatefulWidget {
  const _ShareSheetContent({required this.message, this.shareImageUrl});
  final String message;
  final String? shareImageUrl;

  @override
  State<_ShareSheetContent> createState() => _ShareSheetContentState();
}

class _ShareSheetContentState extends State<_ShareSheetContent> {
  String? _cachedImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.shareImageUrl != null && widget.shareImageUrl!.isNotEmpty) {
      cachedShareImagePath(widget.shareImageUrl!).then((p) {
        if (mounted) setState(() => _cachedImagePath = p);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KvlColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KvlColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Share via', style: KvlText.ui(16, FontWeight.w700)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ShareOption(
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                icon: Icons.chat_rounded,
                onTap: () async {
                  Navigator.pop(context);
                  if (_cachedImagePath != null) {
                    final ext = _cachedImagePath!.endsWith('.png') ? 'png' : 'jpg';
                    await SharePlus.instance.share(ShareParams(
                      text: widget.message,
                      files: [XFile(_cachedImagePath!, mimeType: 'image/$ext')],
                    ));
                  } else if (widget.shareImageUrl != null && widget.shareImageUrl!.isNotEmpty) {
                    await _shareWithImage(message: widget.message, imageUrl: widget.shareImageUrl!);
                  } else {
                    final appUri = Uri(
                      scheme: 'whatsapp',
                      host: 'send',
                      queryParameters: {'text': widget.message},
                    );
                    if (await canLaunchUrl(appUri)) {
                      await launchUrl(appUri, mode: LaunchMode.externalApplication);
                    } else {
                      final webUri = Uri.parse(
                        'https://wa.me/?text=${Uri.encodeComponent(widget.message)}',
                      );
                      await launchUrl(webUri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
              ),
              _ShareOption(
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                icon: Icons.facebook_rounded,
                onTap: () async {
                  Navigator.pop(context);
                  final appUri = Uri.parse(
                    'fb://share?quote=${Uri.encodeComponent(widget.message)}',
                  );
                  if (await canLaunchUrl(appUri)) {
                    await launchUrl(appUri, mode: LaunchMode.externalApplication);
                  } else {
                    await SharePlus.instance.share(ShareParams(text: widget.message));
                  }
                },
              ),
              _ShareOption(
                label: 'Instagram',
                color: const Color(0xFFE1306C),
                icon: Icons.camera_alt_rounded,
                onTap: () async {
                  Navigator.pop(context);
                  if (_cachedImagePath != null) {
                    final ext = _cachedImagePath!.endsWith('.png') ? 'png' : 'jpg';
                    await SharePlus.instance.share(ShareParams(
                      text: widget.message,
                      files: [XFile(_cachedImagePath!, mimeType: 'image/$ext')],
                    ));
                  } else if (widget.shareImageUrl != null && widget.shareImageUrl!.isNotEmpty) {
                    await _shareWithImage(message: widget.message, imageUrl: widget.shareImageUrl!);
                  } else {
                    await SharePlus.instance.share(ShareParams(text: widget.message));
                  }
                },
              ),
              _ShareOption(
                label: 'More',
                color: KvlColors.inkSoft,
                icon: Icons.more_horiz_rounded,
                onTap: () async {
                  if (_cachedImagePath != null) {
                    final ext = _cachedImagePath!.endsWith('.png') ? 'png' : 'jpg';
                    await SharePlus.instance.share(ShareParams(
                      text: widget.message,
                      files: [XFile(_cachedImagePath!, mimeType: 'image/$ext')],
                    ));
                  } else if (widget.shareImageUrl != null && widget.shareImageUrl!.isNotEmpty) {
                    await _shareWithImage(message: widget.message, imageUrl: widget.shareImageUrl!);
                  } else {
                    await SharePlus.instance.share(ShareParams(text: widget.message));
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Downloads [imageUrl] to a temp file and shares it together with [message].
/// Falls back to text-only share if the download fails.
/// Guard flag prevents double-taps from firing multiple share sheets.
bool _shareWithImageInProgress = false;

Future<void> _shareWithImage({
  required String message,
  required String imageUrl,
}) async {
  if (_shareWithImageInProgress) return;
  _shareWithImageInProgress = true;
  try {
    final tmpDir = await getTemporaryDirectory();
    final ext = imageUrl.contains('.png') ? 'png' : 'jpg';
    final file = File('${tmpDir.path}/program_share.$ext');
    await Dio().download(imageUrl, file.path);
    await SharePlus.instance.share(ShareParams(
      text: message,
      files: [XFile(file.path, mimeType: 'image/$ext')],
    ));
  } catch (_) {
    await SharePlus.instance.share(ShareParams(text: message));
  } finally {
    _shareWithImageInProgress = false;
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: .3), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: KvlText.caption(11).copyWith(color: KvlColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dedicate Program bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class DedicateSheet extends StatefulWidget {
  const DedicateSheet({
    super.key,
    required this.programId,
    required this.mantraName,
  });

  final String programId;
  final String mantraName;

  static Future<void> show(
    BuildContext context, {
    required String programId,
    required String mantraName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DedicateSheet(
        programId: programId,
        mantraName: mantraName,
      ),
    );
  }

  @override
  State<DedicateSheet> createState() => _DedicateSheetState();
}

class _DedicateSheetState extends State<DedicateSheet> {
  static String _prefKey(String programId) => 'dedication_$programId';

  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final raw = prefs.getString(_prefKey(widget.programId));
    if (raw != null && raw.contains('||')) {
      final parts = raw.split('||');
      _nameCtrl.text = parts[0];
      _noteCtrl.text = parts.length > 1 ? parts[1] : '';
      _phoneCtrl.text = parts.length > 2 ? parts[2] : '';
      _saved = true;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final phone = _phoneCtrl.text.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey(widget.programId),
      '$name||${_noteCtrl.text.trim()}||$phone',
    );
    if (!mounted) return;
    setState(() => _saved = true);
    Navigator.of(context).pop();

    // If a phone number was linked, open the SMS app pre-filled so the user
    // can send the dedication message with one tap.
    if (phone.isNotEmpty) {
      await _sendSms(phone, name);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dedicated to $name 🙏'),
            duration: const Duration(milliseconds: 1800),
            behavior: SnackBarBehavior.floating,
            backgroundColor: KvlColors.success,
          ),
        );
      }
    }
  }

  Future<void> _sendSms(String phone, String name) async {
    final mantra = widget.mantraName.isNotEmpty ? widget.mantraName : 'this mantra';
    final message =
        '🙏 Namaste $name,\n\n'
        'I have dedicated my $mantra Sadhana practice to you.\n'
        'May this offering bring blessings, peace, and happiness to your life. 🕉\n\n'
        '— Sent from Vachika Lekhini';
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey(widget.programId));
    _nameCtrl.clear();
    _noteCtrl.clear();
    _phoneCtrl.clear();
    if (mounted) setState(() => _saved = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      // Outer padding moves the sheet body above the keyboard.
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
      decoration: const BoxDecoration(
        color: KvlColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(
        KvlSpacing.lg, KvlSpacing.lg, KvlSpacing.lg, KvlSpacing.lg,
      ),
      child: _loading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: KvlSpacing.md),
                    decoration: BoxDecoration(
                      color: KvlColors.muted.withValues(alpha: .35),
                      borderRadius: KvlRadius.brPill,
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    const Text('🙏', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: KvlSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.dedicateSheetTitle,
                            style: KvlText.ui(17, FontWeight.w700),
                          ),
                          Text(
                            widget.mantraName.isEmpty
                                ? context.l10n.dedicateOfferPractice
                                : context.l10n.dedicateOfferNamedPractice(widget.mantraName),
                            style: KvlText.caption(12)
                                .copyWith(color: KvlColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KvlSpacing.lg),

                // Dedicated to name
                Text(
                  context.l10n.dedicatedTo,
                  style: KvlText.ui(13, FontWeight.w600),
                ),
                const SizedBox(height: KvlSpacing.xs),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: context.l10n.dedicatedToHint,
                    hintStyle: KvlText.caption(13)
                        .copyWith(color: KvlColors.muted),
                    filled: true,
                    fillColor: KvlColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: KvlRadius.brMD,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: KvlSpacing.md,
                      vertical: KvlSpacing.sm,
                    ),
                  ),
                  style: KvlText.ui(14, FontWeight.w500),
                ),
                const SizedBox(height: KvlSpacing.md),

                // Phone number — links a contact so SMS is sent on save
                Text(
                  'Send blessing to (phone number)',
                  style: KvlText.ui(13, FontWeight.w600),
                ),
                const SizedBox(height: KvlSpacing.xs),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'e.g. +91 98765 43210',
                    hintStyle: KvlText.caption(13)
                        .copyWith(color: KvlColors.muted),
                    filled: true,
                    fillColor: KvlColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: KvlRadius.brMD,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: KvlSpacing.md,
                      vertical: KvlSpacing.sm,
                    ),
                    prefixIcon: const Icon(
                      Icons.message_rounded,
                      size: 18,
                      color: KvlColors.primary,
                    ),
                    suffixText: 'Optional',
                    suffixStyle: KvlText.caption(11)
                        .copyWith(color: KvlColors.muted),
                  ),
                  style: KvlText.ui(14, FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'A blessing SMS will be sent to this number when you save.',
                  style: KvlText.caption(11).copyWith(color: KvlColors.muted),
                ),
                const SizedBox(height: KvlSpacing.md),

                // Intention / note
                Text(
                  context.l10n.intention,
                  style: KvlText.ui(13, FontWeight.w600),
                ),
                const SizedBox(height: KvlSpacing.xs),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: context.l10n.intentionHint,
                    hintStyle: KvlText.caption(13)
                        .copyWith(color: KvlColors.muted),
                    filled: true,
                    fillColor: KvlColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: KvlRadius.brMD,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: KvlSpacing.md,
                      vertical: KvlSpacing.sm,
                    ),
                  ),
                  style: KvlText.ui(13, FontWeight.w400),
                ),

                if (_saved) ...[
                  const SizedBox(height: KvlSpacing.sm),
                  InkWell(
                    onTap: _clear,
                    borderRadius: KvlRadius.brMD,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        context.l10n.removeDedication,
                        textAlign: TextAlign.center,
                        style: KvlText.caption(12).copyWith(
                          color: KvlColors.danger,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: KvlSpacing.lg),
                KvlButton(
                  label: _saved ? context.l10n.updateDedication : context.l10n.saveDedication,
                  onPressed: _save,
                ),
              ],
            ),
          ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Edit Goal bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditGoalSheet extends StatefulWidget {
  const _EditGoalSheet({
    required this.program,
    required this.repository,
  });

  final Program program;
  final ProgramRepository repository;

  static Future<void> show(
    BuildContext context, {
    required WidgetRef ref,
    required Program program,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditGoalSheet(
        program: program,
        repository: ref.read(programRepositoryProvider),
      ),
    );
  }

  @override
  State<_EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends State<_EditGoalSheet> {
  late final TextEditingController _writingsCtrl;
  late final TextEditingController _daysCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _writingsCtrl = TextEditingController(text: widget.program.targetWritings.toString());
    _daysCtrl = TextEditingController(text: widget.program.targetDays.toString());
  }

  @override
  void dispose() {
    _writingsCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final tw = int.tryParse(_writingsCtrl.text.trim());
    final td = int.tryParse(_daysCtrl.text.trim());
    if (tw == null || tw <= 0) {
      setState(() => _error = 'Enter a valid target count (e.g. 1008).');
      return;
    }
    if (td == null || td <= 0) {
      setState(() => _error = 'Enter a valid number of days (e.g. 30).');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.repository.update(widget.program.copyWith(targetWritings: tw, targetDays: td));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Could not save. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: KvlColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(KvlSpacing.xxl, KvlSpacing.lg, KvlSpacing.xxl, KvlSpacing.xxl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: KvlSpacing.lg),
                  decoration: BoxDecoration(
                    color: KvlColors.muted.withValues(alpha: .35),
                    borderRadius: KvlRadius.brPill,
                  ),
                ),
              ),
              Text(context.l10n.editGoal, style: KvlText.ui(18, FontWeight.w700)),
              const SizedBox(height: KvlSpacing.xs),
              Text('Update your recitation target and number of days.',
                  style: KvlText.caption(12).copyWith(color: KvlColors.muted)),
              const SizedBox(height: KvlSpacing.xxl),
              Text('Target recitations', style: KvlText.ui(13, FontWeight.w600)),
              const SizedBox(height: KvlSpacing.xs),
              TextField(
                controller: _writingsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 1008',
                  hintStyle: KvlText.caption(13).copyWith(color: KvlColors.muted),
                  filled: true, fillColor: KvlColors.surface, suffixText: 'counts',
                  border: OutlineInputBorder(borderRadius: KvlRadius.brMD, borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: KvlSpacing.lg, vertical: KvlSpacing.sm),
                ),
                style: KvlText.ui(15, FontWeight.w600),
              ),
              const SizedBox(height: KvlSpacing.lg),
              Text('Target days', style: KvlText.ui(13, FontWeight.w600)),
              const SizedBox(height: KvlSpacing.xs),
              TextField(
                controller: _daysCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 30',
                  hintStyle: KvlText.caption(13).copyWith(color: KvlColors.muted),
                  filled: true, fillColor: KvlColors.surface, suffixText: 'days',
                  border: OutlineInputBorder(borderRadius: KvlRadius.brMD, borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: KvlSpacing.lg, vertical: KvlSpacing.sm),
                ),
                style: KvlText.ui(15, FontWeight.w600),
              ),
              if (_error != null) ...[
                const SizedBox(height: KvlSpacing.sm),
                Text(_error!, style: KvlText.caption(11.5).copyWith(color: KvlColors.danger)),
              ],
              const SizedBox(height: KvlSpacing.xxl),
              KvlButton(label: _saving ? 'Saving…' : 'Save Goal', onPressed: _saving ? null : _save),
            ],
          ),
        ),
      ),
    );
  }
}
