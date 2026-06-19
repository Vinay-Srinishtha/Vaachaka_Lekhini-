import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/notifications/notification_scheduler.dart';
import '../core/remote_config/remote_config.dart';
import '../core/remote_config/remote_config_keys.dart';
import '../core/navigation/back_navigation.dart';
import '../core/theme/theme.dart';
import '../core/utils/indian_number_format.dart';
import '../core/widgets/kvl_profile_avatar.dart';
import '../features/profiles/domain/profile.dart';
import '../core/widgets/widgets.dart';
import '../features/auth/presentation/create_account_screen.dart';
import '../features/auth/presentation/otp_login_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/community/domain/friend.dart';
import '../features/community/presentation/community_screen.dart';
import '../features/community/presentation/invite_friends_screen.dart';
import '../features/enrolment/handwriting/presentation/handwriting_submit_screen.dart';
import '../features/enrolment/handwriting/presentation/write_on_screen_screen.dart';
import '../features/enrolment/voice/presentation/voice_training_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/mantras/presentation/mantra_by_need_screen.dart';
import '../features/mantras/presentation/mantra_details_screen.dart';
import '../features/mantras/presentation/mantra_selection_screen.dart';
import '../features/mantras/presentation/quick_start_screen.dart';
import '../features/practice/presentation/counter_screen.dart';
import '../features/practice/presentation/practice_screen.dart';
import '../features/profiles/presentation/add_family_screen.dart';
import '../features/profiles/presentation/profile_edit_screen.dart';
import '../features/profiles/presentation/profile_select_screen.dart';
import '../features/settings/presentation/info_screen.dart';
import '../features/settings/presentation/profile_screen.dart';
import '../features/programs/presentation/daily_progress_screen.dart';
import '../features/programs/presentation/programs_screen.dart';
import '../features/programs/presentation/set_program_target_screen.dart';
import '../features/global_sadhana/presentation/global_sadhana_detail_screen.dart';
import '../features/rewards/presentation/reward_history_screen.dart';
import '../features/rewards/presentation/store_screen.dart';
import '../l10n/l10n.dart';
import 'providers.dart';

/// Route names. Path params are appended on the call site:
/// `'${KvlRoute.mantraDetails}/$id'`.
abstract final class KvlRoute {
  // Shell tabs
  static const home = '/';
  static const programs = '/programs';
  static const practice = '/practice';
  static const community = '/community';
  static const store = '/store';

  // Auth flow (Phase 1)
  static const welcome = '/welcome';
  static const profileSelect = '/profile-select';
  static const createAccount = '/create-account';
  static const otpLogin = '/otp-login';

  // Mantra & enrolment (Phase 2)
  static const quickStart = '/quick-start';
  static const mantraSelection = '/mantra-selection';
  static const mantraByNeed = '/mantra-by-need';
  static const mantraDetails = '/mantra-details'; // + /:id
  static const voiceTraining = '/voice-training'; // + /:mantraId
  static const handwritingSubmit = '/handwriting-submit'; // + /:mantraId
  static const handwritingWrite = '/handwriting-write'; // + /:mantraId

  // Later phases — reserved.
  static const setTargetWritings = '/set-target-writings';
  static const dailyProgress = '/daily-progress';
  static const profile = '/profile';
  static const profileEdit = '/profile-edit';
  static const addFamily = '/add-family';
  static const rewardHistory = '/reward-history';
  static const inviteFriends = '/invite-friends';
  static const globalSadhana = '/global-sadhana'; // + /:id

  static const _authPaths = {welcome, profileSelect, createAccount, otpLogin};
  static bool isAuthRoute(String path) => _authPaths.contains(path);
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    initialLocation: KvlRoute.welcome,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider).value;
      final activeProfile = ref.read(activeProfileProvider).value;
      final loc = state.matchedLocation;
      final isAuth = KvlRoute.isAuthRoute(loc);

      if (session == null) return isAuth ? null : KvlRoute.welcome;
      if (activeProfile == null) {
        const allowed = {
          KvlRoute.profileSelect,
          KvlRoute.createAccount,
          KvlRoute.otpLogin,
        };
        return allowed.contains(loc) ? null : KvlRoute.profileSelect;
      }
      if (isAuth) return KvlRoute.home;
      return null;
    },
    routes: [
      GoRoute(path: KvlRoute.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: KvlRoute.profileSelect,
        builder: (_, _) => const ProfileSelectScreen(),
      ),
      GoRoute(
        path: KvlRoute.createAccount,
        builder: (_, _) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: KvlRoute.otpLogin,
        builder: (_, _) => const OtpLoginScreen(),
      ),

      // Mantra + enrolment — outside the shell so they get the back arrow chrome.
      GoRoute(
        path: KvlRoute.quickStart,
        builder: (_, _) => const QuickStartScreen(),
      ),
      GoRoute(
        path: KvlRoute.mantraSelection,
        builder: (_, _) => const MantraSelectionScreen(),
      ),
      GoRoute(
        path: KvlRoute.mantraByNeed,
        builder: (_, _) => const MantraByNeedScreen(),
      ),
      GoRoute(
        path: '${KvlRoute.mantraDetails}/:id',
        builder: (_, state) =>
            MantraDetailsScreen(mantraId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${KvlRoute.voiceTraining}/:mantraId',
        builder: (_, state) => VoiceTrainingScreen(
          mantraId: state.pathParameters['mantraId']!,
          isRetrain: state.uri.queryParameters['retrain'] == '1',
        ),
      ),
      GoRoute(
        path: '${KvlRoute.handwritingSubmit}/:mantraId',
        builder: (_, state) => HandwritingSubmitScreen(
          mantraId: state.pathParameters['mantraId']!,
          isRetrain: state.uri.queryParameters['retrain'] == '1',
        ),
      ),
      GoRoute(
        path: '${KvlRoute.handwritingWrite}/:mantraId',
        builder: (_, state) => WriteOnScreenScreen(
          mantraId: state.pathParameters['mantraId']!,
          programId: state.uri.queryParameters['programId'],
          isRetrain: state.uri.queryParameters['retrain'] == '1',
        ),
      ),

      // Phase 3 — programs / targets / daily progress
      GoRoute(
        path: '${KvlRoute.setTargetWritings}/:mantraId',
        builder: (_, state) => SetProgramTargetScreen(
          mantraId: state.pathParameters['mantraId']!,
        ),
      ),
      GoRoute(
        path: '${KvlRoute.dailyProgress}/:programId',
        builder: (_, state) =>
            DailyProgressScreen(programId: state.pathParameters['programId']!),
      ),
      GoRoute(
        path: '${KvlRoute.practice}/:programId',
        builder: (_, state) =>
            CounterScreen(programId: state.pathParameters['programId']!),
      ),
      GoRoute(
        path: KvlRoute.inviteFriends,
        builder: (_, _) => const InviteFriendsScreen(),
      ),
      GoRoute(
        path: '${KvlRoute.globalSadhana}/:sadhanaId',
        builder: (_, state) => GlobalSadhanaDetailScreen(
          sadhanaId: state.pathParameters['sadhanaId']!,
        ),
      ),
      GoRoute(
        path: KvlRoute.rewardHistory,
        builder: (_, _) => const RewardHistoryScreen(),
      ),
      GoRoute(path: KvlRoute.profile, builder: (_, _) => const ProfileScreen()),
      GoRoute(path: KvlRoute.profileEdit, builder: (_, _) => const ProfileEditScreen()),
      GoRoute(
        path: KvlRoute.addFamily,
        builder: (_, _) => const AddFamilyScreen(),
      ),
      GoRoute(
        path: '/info/:topic',
        builder: (_, state) =>
            InfoScreen(topic: state.pathParameters['topic'] ?? 'about'),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ShellPage(shell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: KvlRoute.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: KvlRoute.programs,
                builder: (_, _) => const ProgramsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: KvlRoute.practice,
                builder: (_, _) => const PracticeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: KvlRoute.community,
                builder: (_, _) => const CommunityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: KvlRoute.store,
                builder: (_, _) => const StoreScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(sessionProvider, (_, _) => notifyListeners());
    ref.listen(activeProfileProvider, (_, _) => notifyListeners());
  }
}

class _ShellPage extends ConsumerStatefulWidget {
  const _ShellPage({required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<_ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends ConsumerState<_ShellPage> {
  StatefulNavigationShell get shell => widget.shell;

  /// Tab indices in [kvlNavItems] for the feature-flag-gated tabs.
  static const _communityTab = 3;
  static const _storeTab = 4;

  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(redeemedItemIdsProvider);
      ref.read(leaderboardProvider(const LeaderboardFilter(sort: LeaderboardSort.streak)));
      ref.read(leaderboardProvider(const LeaderboardFilter(sort: LeaderboardSort.totalChants)));
      _checkLaunchNotification();
    });
    notificationTapRoute.addListener(_onNotificationTap);
  }

  @override
  void dispose() {
    notificationTapRoute.removeListener(_onNotificationTap);
    super.dispose();
  }

  void _onNotificationTap() {
    final route = notificationTapRoute.value;
    if (route == null || !mounted) return;
    notificationTapRoute.value = null;
    context.go(route);
  }

  Future<void> _checkLaunchNotification() async {
    final route = await NotificationScheduler.checkLaunchNotification();
    if (route != null && mounted) context.go(route);
  }

  List<String> _buildTitles(BuildContext context) => [
    context.l10n.navHome,
    context.l10n.navPrograms,
    context.l10n.navPractice,
    context.l10n.navCommunity,
    context.l10n.navStore,
  ];

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider).value;
    final initial = profile?.initials ?? '?';
    final cfg = ref.watch(remoteConfigProvider).value ?? RemoteConfig.empty;
    final isCommunity = shell.currentIndex == _communityTab;
    final isStore = shell.currentIndex == _storeTab;
    final hidden = <int>{
      if (!cfg.boolFlag(RemoteConfigKeys.communityTab, fallback: true))
        _communityTab,
      if (!cfg.boolFlag(RemoteConfigKeys.storeTab, fallback: true)) _storeTab,
    };
    final usesCustomHeader = shell.currentIndex == 0 || shell.currentIndex == 2;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (shell.currentIndex != 0) {
          shell.goBranch(0);
          return;
        }
        if (context.canPop()) {
          context.pop();
          return;
        }
        // Double-back to exit: first press shows a hint, second press exits.
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(context.l10n.pressBackAgainToExit),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
      },
      child: Scaffold(
        backgroundColor: KvlColors.bg,
        extendBodyBehindAppBar: true,
        appBar: usesCustomHeader
            ? null
            : KvlTopBar(
                title: _buildTitles(context)[shell.currentIndex],
                showBack: shell.currentIndex == 1 || isCommunity,
                onBack: shell.currentIndex == 1
                    ? () => context.popOrGo(KvlRoute.home)
                    : isCommunity
                    ? () => shell.goBranch(0)
                    : null,
                topGapColor: isCommunity || isStore ? Colors.black : null,
                leading: isStore
                    ? _RewardHistoryChipConnected(
                        onTap: () => context.push(KvlRoute.rewardHistory),
                      )
                    : null,
                trailing: _AvatarChip(
                  initial: initial,
                  profileId: profile?.id ?? '',
                  onTap: () => context.push(KvlRoute.profile),
                ),
              ),
        body: shell,
        bottomNavigationBar: KvlBottomNav(
          currentIndex: shell.currentIndex,
          onTap: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          hiddenIndices: hidden,
        ),
      ),
    );
  }
}

/// Isolated ConsumerWidget so only the chip rebuilds on reward balance changes,
/// not the entire shell scaffold.
class _RewardHistoryChipConnected extends ConsumerWidget {
  const _RewardHistoryChipConnected({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(rewardTotalProvider).value ?? 0;
    return _RewardHistoryChip(points: points, onTap: onTap);
  }
}

class _RewardHistoryChip extends StatelessWidget {
  const _RewardHistoryChip({required this.points, required this.onTap});
  final int points;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: KvlRadius.brSM,
      child: SizedBox(
        width: 92,
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 16, color: KvlColors.gold),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    IndianNumberFormat.format(points),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KvlText.ui(
                      12,
                      FontWeight.w700,
                    ).copyWith(color: KvlColors.ink),
                  ),
                ),
              ],
            ),
            Text(
              context.l10n.seeHistory,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KvlText.caption(9.5).copyWith(
                color: KvlColors.primaryDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _AvatarChip extends ConsumerWidget {
  const _AvatarChip({required this.initial, required this.onTap, required this.profileId});
  final String initial;
  final String profileId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider).value;
    final fraction = _profileCompletion(profile);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: MilestoneRing.fraction(
        fraction: fraction,
        strokeWidth: 2,
        gap: 0.5,
        child: KvlProfileAvatar(
          profileId: profileId,
          initials: initial,
          size: 36,
          textSize: 14,
          gradientSeed: profileId,
        ),
      ),
    );
  }
}
