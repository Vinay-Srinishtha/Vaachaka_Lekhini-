import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/navigation/back_navigation.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/program.dart';
import '../domain/session.dart';
import '../../settings/domain/settings_repository.dart';

class DailyProgressScreen extends ConsumerStatefulWidget {
  const DailyProgressScreen({super.key, required this.programId});
  final String programId;

  @override
  ConsumerState<DailyProgressScreen> createState() =>
      _DailyProgressScreenState();
}

class _DailyProgressScreenState extends ConsumerState<DailyProgressScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  Future<Program?> _loadProgram() =>
      ref.read(programRepositoryProvider).getById(widget.programId);

  Future<Map<DateTime, int>> _loadCounts() {
    final first = DateTime(_month.year, _month.month);
    final last = DateTime(
      _month.year,
      _month.month + 1,
    ).subtract(const Duration(days: 1));
    return ref
        .read(programRepositoryProvider)
        .sessionCountsByDay(programId: widget.programId, from: first, to: last);
  }

  Future<DailySummary> _loadSummary() => ref
      .read(programRepositoryProvider)
      .dailySummary(widget.programId, _selected);

  void _shiftMonth(int by) {
    setState(() {
      _month = DateTime(_month.year, _month.month + by);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Program?>(
      future: _loadProgram(),
      builder: (_, snap) {
        final program = snap.data;
        final settings =
            ref.watch(settingsProvider).value ?? KvlSettings.fallback;
        final profile = ref.watch(activeProfileProvider).value;
        final mantraName = program == null
            ? ''
            : ref
                      .watch(mantraByIdProvider(program.mantraId))
                      ?.name
                      .displayForLanguage(settings.languageCode) ??
                  '';
        final title = mantraName.isEmpty
            ? 'Daily Progress'
            : '$mantraName Mantra';

        return Scaffold(
          backgroundColor: KvlColors.bg,
          body: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                KvlSpacing.lg,
                KvlSpacing.sm,
                KvlSpacing.lg,
                KvlSpacing.md,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final compact = height < 720;
                  final tight = height < 650;
                  final headerHeight = tight ? 64.0 : 76.0;
                  final gap = tight ? KvlSpacing.xs : KvlSpacing.sm;
                  final calendarHeight =
                      (height *
                              (tight
                                  ? .42
                                  : compact
                                  ? .45
                                  : .48))
                          .clamp(248.0, 356.0);
                  final summaryPadding = EdgeInsets.all(
                    tight ? KvlSpacing.md : KvlSpacing.lg,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: headerHeight,
                        child: _ProgressHeader(
                          title: title,
                          initial: profile?.initials ?? '?',
                          onBack: () => context.popOrGo(KvlRoute.practice),
                        ),
                      ),
                      SizedBox(height: gap),
                      SizedBox(
                        height: calendarHeight,
                        child: FutureBuilder<Map<DateTime, int>>(
                          future: _loadCounts(),
                          builder: (_, snap) {
                            final counts = snap.data ?? const <DateTime, int>{};
                            return LayoutBuilder(
                              builder: (context, calConstraints) {
                                final monthHeaderHeight = tight ? 44.0 : 52.0;
                                final gridHeight =
                                    calConstraints.maxHeight -
                                    monthHeaderHeight -
                                    KvlSpacing.sm;
                                return Column(
                                  children: [
                                    SizedBox(
                                      height: monthHeaderHeight,
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
                                        selected: _selected,
                                        countsByDay: counts,
                                        rowHeight: gridHeight / 7,
                                        compact: compact,
                                        onTapDay: (d) =>
                                            setState(() => _selected = d),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: tight ? KvlSpacing.sm : KvlSpacing.md),
                      FutureBuilder<DailySummary>(
                        future: _loadSummary(),
                        builder: (_, snap) {
                          final s = snap.data;
                          return KvlCard(
                            variant: KvlCardVariant.warm,
                            padding: summaryPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Recitations on ${DateFormat.yMMMd().format(_selected)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: KvlText.ui(
                                    tight ? 11.5 : 12.5,
                                    FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  height: tight ? KvlSpacing.xs : KvlSpacing.sm,
                                ),
                                _Row(
                                  label: 'Daily Target',
                                  value: s == null
                                      ? '—'
                                      : '${IndianNumberFormat.format(s.dailyTarget)} chants',
                                  compact: tight,
                                ),
                                SizedBox(height: tight ? 2 : 4),
                                _Row(
                                  label: 'Actual Achieved',
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
                                  label: 'Handwriting Used',
                                  value: s == null
                                      ? '—'
                                      : (s.usedHandwriting ? 'Yes' : 'No'),
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
                      KvlButton(
                        label: 'Dedicate this program',
                        onPressed: () {},
                      ),
                      SizedBox(height: tight ? KvlSpacing.sm : KvlSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: KvlButton(
                              variant: KvlButtonVariant.secondary,
                              label: 'Edit Goal',
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: KvlSpacing.md),
                          Expanded(
                            child: KvlButton(
                              variant: KvlButtonVariant.ghost,
                              label: 'Share Program',
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ],
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
    required this.initial,
    required this.onBack,
  });

  final String title;
  final String initial;
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
              'Daily Progress',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KvlText.caption(11).copyWith(color: KvlColors.muted),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 48,
            height: 48,
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
                18,
                FontWeight.w700,
              ).copyWith(color: Colors.white),
            ),
          ),
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
    required this.selected,
    required this.countsByDay,
    required this.rowHeight,
    required this.compact,
    required this.onTapDay,
  });

  final DateTime month;
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
              final isSelected = isInMonth && day == selected;
              final hasActivity = isInMonth && (countsByDay[day] ?? 0) > 0;
              final dateSize = compact ? 38.0 : 44.0;
              final dotSize = compact ? 5.5 : 6.5;
              return Expanded(
                child: GestureDetector(
                  onTap: isInMonth ? () => onTapDay(day) : null,
                  behavior: isInMonth
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
