import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';

import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/friend.dart';
import '../../mantras/domain/mantra.dart';
import '../../../l10n/l10n.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  LeaderboardSort _sort = LeaderboardSort.streak;
  String? _mantraId;

  @override
  Widget build(BuildContext context) {
    final filter = LeaderboardFilter(sort: _sort, mantraId: _mantraId);
    final leaderboardAsync = ref.watch(leaderboardProvider(filter));
    final list = leaderboardAsync.value ?? const <Friend>[];
    final mantras = ref.watch(mantraCatalogProvider).value ?? const <Mantra>[];
    final hasError = leaderboardAsync.hasError && list.isEmpty;

    return _Body(
      list: list,
      sort: _sort,
      mantras: mantras,
      selectedMantraId: _mantraId,
      onSortChanged: (s) => setState(() => _sort = s),
      onMantraChanged: (id) => setState(() => _mantraId = id),
      loading: leaderboardAsync.isLoading && list.isEmpty,
      hasError: hasError,
      onRetry: () => ref.invalidate(leaderboardProvider(filter)),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.list,
    required this.sort,
    required this.mantras,
    required this.selectedMantraId,
    required this.onSortChanged,
    required this.onMantraChanged,
    this.loading = false,
    this.hasError = false,
    this.onRetry,
  });
  final List<Friend> list;
  final LeaderboardSort sort;
  final List<Mantra> mantras;
  final String? selectedMantraId;
  final ValueChanged<LeaderboardSort> onSortChanged;
  final ValueChanged<String?> onMantraChanged;
  final bool loading;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top.clamp(36.0, 48.0);

    // One entry per account: keep only the first (highest-ranked) self row.
    bool selfSeen = false;
    final deduped = list.where((f) {
      if (!f.isSelf) return true;
      if (selfSeen) return false;
      selfSeen = true;
      return true;
    }).toList();

    final podium = deduped.take(3).toList();
    final selfInPodium = podium.any((f) => f.isSelf);
    final rest = deduped.skip(3).where((f) => !selfInPodium || !f.isSelf).toList();

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      onRefresh: onRetry != null ? () async => onRetry!() : () async {},
      color: KvlColors.primary,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        KvlSpacing.lg,
        topInset + 68,
        KvlSpacing.lg,
        bottomInset + 104,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SortToggle(sort: sort, onChanged: onSortChanged),
          if (mantras.isNotEmpty) ...[
            const SizedBox(height: KvlSpacing.sm),
            _MantraFilter(
              mantras: mantras,
              selectedId: selectedMantraId,
              onChanged: onMantraChanged,
            ),
          ],
          const SizedBox(height: KvlSpacing.md),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (hasError)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.cloud_off_rounded, size: 48, color: KvlColors.primarySoft),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load rankings',
                    style: KvlText.ui(15, FontWeight.w600).copyWith(color: KvlColors.inkSoft),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: KvlText.caption(12).copyWith(color: KvlColors.muted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(backgroundColor: KvlColors.primary),
                  ),
                ],
              ),
            )
          else if (deduped.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.leaderboard_outlined, size: 48, color: KvlColors.primarySoft),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.noRankingsYet,
                    style: KvlText.ui(15, FontWeight.w600).copyWith(color: KvlColors.inkSoft),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.noRankingsSubtitle,
                    textAlign: TextAlign.center,
                    style: KvlText.caption(12).copyWith(color: KvlColors.muted),
                  ),
                ],
              ),
            )
          else ...[
            _Podium(top3: podium, sort: sort),
            const SizedBox(height: KvlSpacing.sm),
            for (int i = 0; i < rest.length; i++) ...[
              _RankRow(
                rank: i + 4,
                friend: rest[i],
                sort: sort,
                highlight: rest[i].isSelf,
              ),
              if (i < rest.length - 1)
                const SizedBox(height: KvlSpacing.xs),
            ],
          ],
        ],
      ),
    ),   // SingleChildScrollView
    );   // RefreshIndicator
  }
}


class _SortToggle extends StatelessWidget {
  const _SortToggle({required this.sort, required this.onChanged});
  final LeaderboardSort sort;
  final ValueChanged<LeaderboardSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KvlColors.primaryGhost,
        borderRadius: KvlRadius.brSM,
      ),
      child: Row(
        children: [
          _Pill(
            label: context.l10n.streakChallenge,
            selected: sort == LeaderboardSort.streak,
            onTap: () => onChanged(LeaderboardSort.streak),
          ),
          _Pill(
            label: context.l10n.totalChantsSort,
            selected: sort == LeaderboardSort.totalChants,
            onTap: () => onChanged(LeaderboardSort.totalChants),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: KvlRadius.brMD,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? KvlColors.primary : Colors.transparent,
            borderRadius: KvlRadius.brMD,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: KvlText.ui(
              12,
              FontWeight.w600,
            ).copyWith(color: selected ? Colors.white : KvlColors.inkSoft),
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top3, required this.sort});
  final List<Friend> top3;
  final LeaderboardSort sort;

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();
    final first = top3[0];
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (second != null) _Pod(friend: second, place: 2, sort: sort),
        const SizedBox(width: 14),
        _Pod(friend: first, place: 1, sort: sort),
        const SizedBox(width: 14),
        if (third != null) _Pod(friend: third, place: 3, sort: sort),
      ],
    );
  }
}

class _Pod extends StatelessWidget {
  const _Pod({required this.friend, required this.place, required this.sort});
  final Friend friend;
  final int place;
  final LeaderboardSort sort;

  static const _borders = <int, Color>{
    1: KvlColors.gold,
    2: Color(0xFFC7C7C7),
    3: Color(0xFFCD7F32),
  };

  @override
  Widget build(BuildContext context) {
    final size = place == 1 ? 60.0 : 52.0;
    final border = _borders[place]!;
    final metric = sort == LeaderboardSort.streak
        ? context.l10n.streakDaysCount(friend.longestStreak)
        : IndianNumberFormat.compact(friend.totalChants);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (place == 1)
          const Text('👑', style: TextStyle(fontSize: 18))
        else
          const SizedBox(height: 18),
        Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 3),
            gradient: LinearGradient(
              colors: [
                KvlColors.primary.withValues(alpha: .9),
                KvlColors.primaryDeep,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            friend.initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: size / 3,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 72,
          child: Text(
            friend.name,
            textAlign: TextAlign.center,
            style: KvlText.caption(10.5).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(metric, style: KvlText.muted(10)),
      ],
    );
  }
}


class _MantraFilter extends StatelessWidget {
  const _MantraFilter({
    required this.mantras,
    required this.selectedId,
    required this.onChanged,
  });
  final List<Mantra> mantras;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: context.l10n.allFilter,
            selected: selectedId == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          for (final m in mantras) ...[
            _FilterChip(
              label: m.name.roman,
              selected: selectedId == m.id,
              onTap: () => onChanged(m.id),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? KvlColors.primary : KvlColors.primaryGhost,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? KvlColors.primary : KvlColors.primarySoft,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: KvlText.ui(12, FontWeight.w600).copyWith(
            color: selected ? Colors.white : KvlColors.primaryDeep,
          ),
        ),
      ),
    );
  }
}


class _RankRow extends StatefulWidget {
  const _RankRow({
    required this.rank,
    required this.friend,
    required this.sort,
    required this.highlight,
  });
  final int rank;
  final Friend friend;
  final LeaderboardSort sort;
  final bool highlight;

  @override
  State<_RankRow> createState() => _RankRowState();
}

class _RankRowState extends State<_RankRow> {
  @override
  Widget build(BuildContext context) {
    final metric = widget.sort == LeaderboardSort.streak
        ? context.l10n.streakDaysCount(widget.friend.longestStreak)
        : IndianNumberFormat.compact(widget.friend.totalChants);
    return KvlCard(
      variant: widget.highlight ? KvlCardVariant.soft : KvlCardVariant.plain,
      border: widget.highlight
          ? Border.all(color: KvlColors.primarySoft, width: 1.5)
          : null,
      padding: const EdgeInsets.symmetric(
        horizontal: KvlSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '${widget.rank}',
              style: KvlText.ui(13, FontWeight.w700).copyWith(
                color: widget.highlight ? KvlColors.primaryDeep : KvlColors.inkSoft,
              ),
            ),
          ),
          Container(
            width: 30,
            height: 30,
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
              widget.friend.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: KvlSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.highlight ? context.l10n.youLabel : widget.friend.name,
                  style: KvlText.ui(12, FontWeight.w600),
                ),
                Text(
                  widget.sort == LeaderboardSort.streak
                      ? context.l10n.longestStreakLabel
                      : context.l10n.totalChantsSort,
                  style: KvlText.muted(10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.friend.streakActive ? '$metric 🔥' : metric,
                style: KvlText.ui(12, FontWeight.w600),
              ),
              if (widget.sort == LeaderboardSort.streak &&
                  widget.friend.currentStreak > 0 &&
                  widget.friend.currentStreak != widget.friend.longestStreak)
                Text(
                  context.l10n.streakDaysCount(widget.friend.currentStreak),
                  style: KvlText.muted(9)
                      .copyWith(color: KvlColors.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
