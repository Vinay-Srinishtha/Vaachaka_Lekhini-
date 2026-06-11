import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/friend.dart';
import '../../../l10n/l10n.dart';
import '../domain/leaderboard_repository.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  LeaderboardSort _sort = LeaderboardSort.streak;

  @override
  Widget build(BuildContext context) {
    // Real leaderboard from /api/v1/leaderboard — no mock friends.
    final leaderboardAsync = ref.watch(leaderboardProvider(_sort));
    final list = leaderboardAsync.value ?? const <Friend>[];
    return _Body(
      list: list,
      sort: _sort,
      onSortChanged: (s) => setState(() => _sort = s),
      loading: leaderboardAsync.isLoading,
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.list,
    required this.sort,
    required this.onSortChanged,
    this.loading = false,
  });
  final List<Friend> list;
  final LeaderboardSort sort;
  final ValueChanged<LeaderboardSort> onSortChanged;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top.clamp(36.0, 48.0);

    // Loading state — only show spinner on true first load (no cached data yet).
    if (loading && list.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          KvlSpacing.lg,
          topInset + 84,
          KvlSpacing.lg,
          KvlSpacing.lg,
        ),
        child: Column(
          children: [
            _InviteBanner(),
            const SizedBox(height: KvlSpacing.xl),
            const CircularProgressIndicator(),
          ],
        ),
      );
    }

    // Empty state — no community members yet
    if (!loading && list.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          KvlSpacing.lg,
          topInset + 84,
          KvlSpacing.lg,
          KvlSpacing.lg,
        ),
        child: Column(
          children: [
            _InviteBanner(),
            const SizedBox(height: KvlSpacing.xl),
            const Icon(Icons.group_off_outlined, size: 48, color: KvlColors.muted),
            const SizedBox(height: KvlSpacing.md),
            Text(
              'No one here yet',
              style: KvlText.title(16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KvlSpacing.xs),
            Text(
              'Invite friends to see the leaderboard',
              style: KvlText.muted(13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KvlSpacing.lg),
            KvlButton(
              label: context.l10n.inviteFriendsButton,
              icon: Icons.person_add_alt_1_outlined,
              onPressed: () => context.push(KvlRoute.inviteFriends),
            ),
          ],
        ),
      );
    }

    final podium = list.take(3).toList();
    final rest = list.skip(3).toList();
    final topInset2 = topInset; // alias for use inside ListView builder

    return ListView(
      padding: EdgeInsets.fromLTRB(
        KvlSpacing.lg,
        topInset2 + 84,
        KvlSpacing.lg,
        KvlSpacing.lg,
      ),
      children: [
        _InviteBanner(),
        const SizedBox(height: KvlSpacing.md),
        _SortToggle(sort: sort, onChanged: onSortChanged),
        const SizedBox(height: KvlSpacing.lg),
        _Podium(top3: podium, sort: sort),
        const SizedBox(height: KvlSpacing.md),
        for (var i = 0; i < rest.length; i++) ...[
          _RankRow(
            rank: i + 4,
            friend: rest[i],
            sort: sort,
            highlight: rest[i].isSelf,
          ),
          const SizedBox(height: KvlSpacing.sm),
        ],
        const SizedBox(height: KvlSpacing.md),
        KvlButton(
          label: context.l10n.sendEncouragement,
          icon: Icons.favorite_rounded,
          onPressed: () {},
        ),
        const SizedBox(height: KvlSpacing.sm),
        KvlButton(
          variant: KvlButtonVariant.secondary,
          label: context.l10n.viewGroupStats,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _InviteBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KvlCard(
      variant: KvlCardVariant.soft,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [KvlColors.primarySoft, KvlColors.primaryGhost],
      ),
      child: Column(
        children: [
          Text(
            context.l10n.communityInviteBanner(LeaderboardRepository.maxCircle),
            textAlign: TextAlign.center,
            style: KvlText.ui(12.5, FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.communityInviteSubline,
            textAlign: TextAlign.center,
            style: KvlText.caption(11),
          ),
          const SizedBox(height: KvlSpacing.sm),
          KvlButton(
            size: KvlButtonSize.tiny,
            expand: false,
            label: context.l10n.inviteFriendsButton,
            icon: Icons.person_add_alt_1_rounded,
            onPressed: () => context.push(KvlRoute.inviteFriends),
          ),
        ],
      ),
    );
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
        ? '${friend.streakDays} Days'
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

class _RankRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final metric = sort == LeaderboardSort.streak
        ? '${friend.streakDays} Days'
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
                  sort == LeaderboardSort.streak ? context.l10n.streakLabel : context.l10n.totalChantsSort,
                  style: KvlText.muted(10),
                ),
              ],
            ),
          ),
          Text(metric, style: KvlText.ui(12, FontWeight.w600)),
        ],
      ),
    );
  }
}
