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

    // ── Fixed header height calculation ──────────────────────────────────────
    // topInset + appbar(68) + padding(md) + sortToggle(50) + gap(sm) +
    // [mantraFilter(36) + gap(sm)] + podium(168) + bottomGap(sm)
    final hasMantraFilter = widget.mantras.length > 1;
    final headerH = topInset +
        68 +
        KvlSpacing.md +
        50 +
        KvlSpacing.sm +
        (hasMantraFilter ? 36 + KvlSpacing.sm : 0) +
        168 +
        KvlSpacing.sm;

    return Stack(
      children: [
        // ── Scrollable rank list — fills the whole area ───────────────────
        Positioned.fill(
          child: RefreshIndicator(
            onRefresh: widget.onRetry != null
                ? () async => widget.onRetry!()
                : () async {},
            color: KvlColors.primary,
            displacement: headerH + 16,
            child: rest.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(top: headerH),
                    children: const [],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      KvlSpacing.lg,
                      headerH + KvlSpacing.sm,
                      KvlSpacing.lg,
                      bottomInset + 104,
                    ),
                    itemCount: rest.length,
                    itemBuilder: (context, i) {
                      final friend = rest[i];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              i < rest.length - 1 ? KvlSpacing.xs : 0,
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
                  ),
          ),
        ),

        // ── Fixed header — always on top, never scrolls ───────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              KvlSpacing.lg,
              topInset + 68,
              KvlSpacing.lg,
              KvlSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF8EE), Color(0xFFFFF4E8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8851A).withValues(alpha: .14),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SortToggle(
                    sort: widget.sort, onChanged: widget.onSortChanged),
                if (hasMantraFilter) ...[
                  const SizedBox(height: KvlSpacing.sm),
                  _MantraFilter(
                    mantras: widget.mantras,
                    selectedId: widget.selectedMantraId,
                    onChanged: widget.onMantraChanged,
                  ),
                ],
                const SizedBox(height: KvlSpacing.md),
                _Podium(top3: podium, sort: widget.sort),
                const SizedBox(height: KvlSpacing.xs),
              ],
            ),
          ),
        ),
      ],
    );
  }
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
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0E0), Color(0xFFFFE8CC)],
        ),
        borderRadius: KvlRadius.brSM,
        border: Border.all(color: const Color(0xFFE8C99A), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8851A).withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFFE8851A), Color(0xFFBF5000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: KvlRadius.brMD,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFBF5000).withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: KvlText.ui(12, FontWeight.w700)
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

  static const _medalColors = <int, List<Color>>{
    1: [Color(0xFFFFD700), Color(0xFFFFAA00), Color(0xFFCC8800)],
    2: [Color(0xFFE8E8E8), Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
    3: [Color(0xFFE8A060), Color(0xFFCD7F32), Color(0xFFA0522D)],
  };
  static const _medalGlow = <int, Color>{
    1: Color(0xFFFFD700),
    2: Color(0xFFBDBDBD),
    3: Color(0xFFCD7F32),
  };

  @override
  Widget build(BuildContext context) {
    final size = place == 1 ? 66.0 : 54.0;
    final medalColors = _medalColors[place]!;
    final glowColor = _medalGlow[place]!;
    final metric = sort == LeaderboardSort.streak
        ? context.l10n.streakDaysCount(friend.longestStreak)
        : IndianNumberFormat.compact(friend.totalChants);
    final isSelf = friend.isSelf;

    final avatarGradient = isSelf
        ? const LinearGradient(
            colors: [Color(0xFFFF9A3C), Color(0xFFBF5000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFF9A3C), Color(0xFFE8851A), Color(0xFFC05E00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (place == 1)
          const Text('👑', style: TextStyle(fontSize: 20))
        else
          const SizedBox(height: 20),
        // Glow ring behind avatar
        Container(
          width: size + 10,
          height: size + 10,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isSelf ? KvlColors.primary : glowColor)
                    .withValues(alpha: place == 1 ? 0.50 : 0.30),
                blurRadius: place == 1 ? 18 : 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isSelf
                    ? [KvlColors.primary, KvlColors.primaryDeep]
                    : medalColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(2.5),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: avatarGradient,
              ),
              alignment: Alignment.center,
              child: Text(
                friend.initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: size / 3.2,
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Medal badge for rank
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelf
                  ? [KvlColors.primary, KvlColors.primaryDeep]
                  : [medalColors[0], medalColors[2]],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '#$place',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 76,
          child: Text(
            isSelf ? 'You' : friend.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KvlText.caption(10.5).copyWith(
              fontWeight: FontWeight.w700,
              color: isSelf ? KvlColors.primaryDeep : KvlColors.ink,
            ),
          ),
        ),
        Text(
          metric,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: KvlText.muted(10).copyWith(fontWeight: FontWeight.w600),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: highlight
            ? const LinearGradient(
                colors: [Color(0xFFFFF4E8), Color(0xFFFFEDD5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: highlight ? null : Colors.white,
        border: highlight
            ? Border.all(color: const Color(0xFFE8851A).withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: const Color(0xFFF0E8DC), width: 1),
        boxShadow: [
          BoxShadow(
            color: highlight
                ? const Color(0xFFE8851A).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: highlight ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 26,
            child: Text(
              '$rank',
              style: KvlText.ui(13, FontWeight.w800).copyWith(
                color: highlight ? KvlColors.primaryDeep : KvlColors.inkSoft,
              ),
            ),
          ),
          // Avatar with gradient
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: highlight
                  ? const LinearGradient(
                      colors: [Color(0xFFFF9A3C), Color(0xFFBF5000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFFB572), Color(0xFFE8851A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: highlight
                  ? [
                      BoxShadow(
                        color: KvlColors.primary.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: Text(
              friend.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  highlight ? context.l10n.youLabel : friend.name,
                  style: KvlText.ui(12.5, FontWeight.w700).copyWith(
                    color: highlight ? KvlColors.primaryDeep : KvlColors.ink,
                  ),
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
                friend.streakActive ? '$metric 🙏' : metric,
                style: KvlText.ui(13, FontWeight.w800).copyWith(
                  color: highlight ? KvlColors.primaryDeep : KvlColors.ink,
                ),
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
