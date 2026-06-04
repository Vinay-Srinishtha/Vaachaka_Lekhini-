import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/program.dart';
import '../domain/session.dart';

class DailyProgressScreen extends ConsumerStatefulWidget {
  const DailyProgressScreen({super.key, required this.programId});
  final String programId;

  @override
  ConsumerState<DailyProgressScreen> createState() => _DailyProgressScreenState();
}

class _DailyProgressScreenState extends ConsumerState<DailyProgressScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  Future<Program?> _loadProgram() => ref.read(programRepositoryProvider).getById(widget.programId);

  Future<Map<DateTime, int>> _loadCounts() {
    final first = DateTime(_month.year, _month.month);
    final last = DateTime(_month.year, _month.month + 1).subtract(const Duration(days: 1));
    return ref.read(programRepositoryProvider).sessionCountsByDay(
          programId: widget.programId,
          from: first,
          to: last,
        );
  }

  Future<DailySummary> _loadSummary() =>
      ref.read(programRepositoryProvider).dailySummary(widget.programId, _selected);

  void _shiftMonth(int by) {
    setState(() {
      _month = DateTime(_month.year, _month.month + by);
    });
  }

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: 'Daily Progress',
      scrollable: true,
      body: FutureBuilder<Program?>(
        future: _loadProgram(),
        builder: (_, snap) {
          final program = snap.data;
          final mantraName =
              program == null ? '' : ref.watch(mantraByIdProvider(program.mantraId))?.name.roman ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (mantraName.isNotEmpty)
                Center(
                  child: Text('$mantraName Mantra · Day ${program?.daysElapsed ?? 0}',
                      style: KvlText.caption(11.5)),
                ),
              const SizedBox(height: KvlSpacing.md),
              KvlCard(
                child: FutureBuilder<Map<DateTime, int>>(
                  future: _loadCounts(),
                  builder: (_, snap) {
                    final counts = snap.data ?? const <DateTime, int>{};
                    return Column(
                      children: [
                        _CalHeader(
                          month: _month,
                          onPrev: () => _shiftMonth(-1),
                          onNext: () => _shiftMonth(1),
                        ),
                        const SizedBox(height: 8),
                        _CalGrid(
                          month: _month,
                          selected: _selected,
                          countsByDay: counts,
                          onTapDay: (d) => setState(() => _selected = d),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: KvlSpacing.lg),
              FutureBuilder<DailySummary>(
                future: _loadSummary(),
                builder: (_, snap) {
                  final s = snap.data;
                  return KvlCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Recitations on ${DateFormat.yMMMd().format(_selected)}',
                          style: KvlText.ui(12.5, FontWeight.w600),
                        ),
                        const SizedBox(height: KvlSpacing.sm),
                        _Row(
                          label: 'Daily Target',
                          value: s == null ? '—' : '${IndianNumberFormat.format(s.dailyTarget)} chants',
                        ),
                        const SizedBox(height: 4),
                        _Row(
                          label: 'Actual Achieved',
                          value: s == null ? '—' : '${IndianNumberFormat.format(s.actualAchieved)} chants',
                          highlight: (s?.metTarget ?? false) ? KvlColors.success : null,
                        ),
                        const SizedBox(height: 4),
                        _Row(
                          label: 'Handwriting Used',
                          value: s == null ? '—' : (s.usedHandwriting ? 'Yes' : 'No'),
                          highlight: s?.usedHandwriting == true ? KvlColors.success : null,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: KvlSpacing.lg),
              KvlButton(label: 'Dedicate this program', onPressed: () {}),
              const SizedBox(height: KvlSpacing.sm),
              Row(
                children: [
                  Expanded(child: KvlButton(variant: KvlButtonVariant.secondary, label: 'Edit Goal', onPressed: () {})),
                  const SizedBox(width: 8),
                  Expanded(child: KvlButton(variant: KvlButtonVariant.ghost, label: 'Share Program', onPressed: () {})),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CalHeader extends StatelessWidget {
  const _CalHeader({required this.month, required this.onPrev, required this.onNext});
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left_rounded, color: KvlColors.primaryDeep)),
        Text(DateFormat.yMMMM().format(month), style: KvlText.ui(13, FontWeight.w600)),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded, color: KvlColors.primaryDeep)),
      ],
    );
  }
}

class _CalGrid extends StatelessWidget {
  const _CalGrid({
    required this.month,
    required this.selected,
    required this.countsByDay,
    required this.onTapDay,
  });

  final DateTime month;
  final DateTime selected;
  final Map<DateTime, int> countsByDay;
  final ValueChanged<DateTime> onTapDay;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final firstWeekday = first.weekday % 7; // Sunday-first
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return Column(
      children: [
        Row(
          children: const [
            _Head('S'), _Head('M'), _Head('T'), _Head('W'), _Head('T'), _Head('F'), _Head('S'),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < 6; row++)
          Row(
            children: List.generate(7, (col) {
              final dayIndex = row * 7 + col - firstWeekday + 1;
              if (dayIndex < 1 || dayIndex > daysInMonth) {
                return const Expanded(child: SizedBox(height: 36));
              }
              final day = DateTime(month.year, month.month, dayIndex);
              final isSelected = day == selected;
              final hasActivity = (countsByDay[day] ?? 0) > 0;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTapDay(day),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 36,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? KvlColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$dayIndex',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected ? Colors.white : KvlColors.ink,
                          ),
                        ),
                        if (hasActivity)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : KvlColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
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
        child: Text(letter, style: const TextStyle(fontSize: 10, color: KvlColors.muted, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.highlight});
  final String label;
  final String value;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft)),
        Text(
          value,
          style: KvlText.ui(12, FontWeight.w600).copyWith(color: highlight ?? KvlColors.ink),
        ),
      ],
    );
  }
}
