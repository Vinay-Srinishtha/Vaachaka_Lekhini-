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
  LeaderboardSort _sort = LeaderboardSort.totalChants;
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

// ─── Body ────────────────────────────────────────────────────────────────────

class _Body extends StatefulWidget {
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
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _scrollController = ScrollController();
  final _selfKey = GlobalKey();
  bool _scrolledToSelf = false;

  @override
  void didUpdateWidget(_Body old) {
    super.didUpdateWidget(old);
    // Reset scroll-to-self when the filter/sort changes so the next data load
    // re-triggers the scroll.
    if (old.sort != widget.sort || old.selectedMantraId != widget.selectedMantraId) {
      _scrolledToSelf = false;
    }
    if (!_scrolledToSelf && widget.list != old.list && widget.list.isNotEmpty) {
      _scheduleScrollToSelf();
    }
  }

  void _scheduleScrollToSelf() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _selfKey.currentContext;
      if (ctx == null) return;
      _scrolledToSelf = true;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5, // center the self row vertically
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top.clamp(36.0, 48.0);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    bool selfSeen = false;
    final deduped = widget.list.where((f) {
      if (!f.isSelf) return true;
      if (selfSeen) return false;
      selfSeen = true;
      return true;
    }).toList();

    final podium = deduped.take(3).toList();
    final selfInPodium = podium.any((f) => f.isSelf);
    final rest = deduped.skip(3).where((f) => !selfInPodium || !f.isSelf).toList();

    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.hasError) {
      return _ErrorView(onRetry: widget.onRetry);
    }

    if (deduped.isEmpty) {
      return _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: widget.onRetry != null ? () async => widget.onRetry!() : () async {},
      color: KvlColors.primary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Scrollable header: sort toggle + mantra filter ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                KvlSpacing.lg,
                topInset + 68,
                KvlSpacing.lg,
                KvlSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SortToggle(sort: widget.sort, onChanged: widget.onSortChanged),
                  if (widget.mantras.length > 1) ...[
                    const SizedBox(height: KvlSpacing.sm),
                    _MantraFilter(
                      mantras: widget.mantras,
                      selectedId: widget.selectedMantraId,
                      onChanged: widget.onMantraChanged,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Pinned podium — always visible ──
          SliverPersistentHeader(
            pinned: true,
            delegate: _PodiumHeader(top3: podium, sort: widget.sort),
          ),

          // ── Rank rows: 4th place onward ──
          if (rest.isEmpty)
            const SliverToBoxAdapter(child: SizedBox.shrink())
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                KvlSpacing.lg,
                KvlSpacing.sm,
                KvlSpacing.lg,
                bottomInset + 104,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final friend = rest[i];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i < rest.length - 1 ? KvlSpacing.xs : 0,
                      ),
                      child: _RankRow(
                        key: friend.isSelf ? _selfKey : null,
                        rank: i + 4,
                        friend: friend,
                        sort: widget.sort,
                        highlight: friend.isSelf,
                      ),
                    );
                  },
                  childCount: rest.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Pinned podium header ─────────────────────────────────────────────────────

class _PodiumHeader extends SliverPersistentHeaderDelegate {
  const _PodiumHeader({required this.top3, required this.sort});
  final List<Friend> top3;
  final LeaderboardSort sort;

  static const double _height = 168.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.lg),
      child: _Podium(top3: top3, sort: sort),
    );
  }

  @override
  bool shouldRebuild(_PodiumHeader old) => old.top3 != top3 || old.sort != sort;
}

// ─── Sort toggle ─────────────────────────────────────────────────────────────

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
            label: context.l10n.totalChantsSort,
            selected: sort == LeaderboardSort.totalChants,
            onTap: () => onChanged(LeaderboardSort.totalChants),
          ),
          _Pill(
            label: context.l10n.streakChallenge,
            selected: sort == LeaderboardSort.streak,
            onTap: () => onChanged(LeaderboardSort.streak),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});
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
            style: KvlText.ui(12, FontWeight.w600)
                .copyWith(color: selected ? Colors.white : KvlColors.inkSoft),
          ),
        ),
      ),
    );
  }
}

// ─── Podium ───────────────────────────────────────────────────────────────────

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
    final isSelf = friend.isSelf;
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
            border: Border.all(
              color: isSelf ? KvlColors.primary : border,
              width: isSelf ? 3.5 : 3,
            ),
            gradient: LinearGradient(
              colors: isSelf
                  ? [KvlColors.primary, KvlColors.primaryDeep]
                  : [
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
            isSelf ? 'You' : friend.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KvlText.caption(10.5).copyWith(
              fontWeight: FontWeight.w600,
              color: isSelf ? KvlColors.primaryDeep : null,
            ),
          ),
        ),
        Text(
          metric,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: KvlText.muted(10),
        ),
      ],
    );
  }
}

// ─── Mantra filter ────────────────────────────────────────────────────────────

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
  const _FilterChip({required this.label, required this.selected, required this.onTap});
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

// ─── Rank row ─────────────────────────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  const _RankRow({
    super.key,
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
  Widget build(BuildContext context) {
    final metric = sort == LeaderboardSort.streak
        ? context.l10n.streakDaysCount(friend.longestStreak)
        : IndianNumberFormat.compact(friend.totalChants);
    return KvlCard(
      variant: highlight ? KvlCardVariant.soft : KvlCardVariant.plain,
      border: highlight
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
              '$rank',
              style: KvlText.ui(13, FontWeight.w700).copyWith(
                color: highlight ? KvlColors.primaryDeep : KvlColors.inkSoft,
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
              friend.initials,
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
                  highlight ? context.l10n.youLabel : friend.name,
                  style: KvlText.ui(12, FontWeight.w600),
                ),
                Text(
                  sort == LeaderboardSort.streak
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
                friend.streakActive ? '$metric 🔥' : metric,
                style: KvlText.ui(12, FontWeight.w600),
              ),
              if (sort == LeaderboardSort.streak &&
                  friend.currentStreak > 0 &&
                  friend.currentStreak != friend.longestStreak)
                Text(
                  context.l10n.streakDaysCount(friend.currentStreak),
                  style: KvlText.muted(9).copyWith(color: KvlColors.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty / error states ─────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
    );
  }
}
