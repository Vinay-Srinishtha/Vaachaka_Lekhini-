import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/kvl_profile_avatar.dart';
import '../../../l10n/l10n.dart';
import '../domain/profile.dart';

class ProfileSelectScreen extends ConsumerWidget {
  const ProfileSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final session = ref.watch(sessionProvider).value;
    final hasSession = session != null;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: KvlColors.welcomeGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KvlSpacing.xl,
              KvlSpacing.huge,
              KvlSpacing.xl,
              KvlSpacing.xl,
            ),
            child: Column(
              children: [
                Text(
                  context.l10n.whoIsPracticing,
                  style: KvlText.title(
                    20,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 44),
                Expanded(
                  child: profilesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        '$e',
                        style: KvlText.body().copyWith(color: Colors.white),
                      ),
                    ),
                    data: (profiles) => _ProfileGrid(
                      profiles: profiles,
                      cap: ref.watch(profileCapProvider),
                      onTapProfile: (p) async {
                        await ref
                            .read(profileRepositoryProvider)
                            .setActive(p.id);
                        if (context.mounted) context.go(KvlRoute.home);
                      },
                      onTapAddMember: () =>
                          _showAddDialog(context, ref, session?.userId),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (hasSession)
                  _link(
                    context,
                    context.l10n.manageProfiles,
                    () => context.go(KvlRoute.addFamily),
                  ),
                _link(
                  context,
                  context.l10n.loginWithAnotherNumber,
                  () => context.go(KvlRoute.otpLogin),
                ),
                _link(
                  context,
                  context.l10n.createNewAccount,
                  () => context.go(KvlRoute.createAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _link(BuildContext context, String label, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          onTap: onTap,
          child: Text(
            label,
            style: KvlText.caption(12).copyWith(
              color: Colors.white.withValues(alpha: .94),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );

  Future<void> _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    String? userId,
  ) async {
    if (userId == null) {
      context.go(KvlRoute.createAccount);
      return;
    }
    final result = await showDialog<({String name, FamilyRelation relation})>(
      context: context,
      builder: (ctx) => const _AddProfileDialog(),
    );
    if (result == null) return;
    final repo = ref.read(profileRepositoryProvider);
    final created = await repo.create(
      userId: userId,
      name: result.name,
      relation: result.relation,
    );
    await repo.setActive(created.id);
    if (context.mounted) context.go(KvlRoute.home);
  }
}

class _ProfileGrid extends StatelessWidget {
  const _ProfileGrid({
    required this.profiles,
    required this.cap,
    required this.onTapProfile,
    required this.onTapAddMember,
  });
  final List<Profile> profiles;
  final int cap;
  final ValueChanged<Profile> onTapProfile;
  final VoidCallback onTapAddMember;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 520;
        final avatarSize = compact ? 104.0 : 122.0;
        return GridView.count(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: compact ? 26 : 40,
          mainAxisSpacing: compact ? 28 : 44,
          childAspectRatio: compact ? .86 : .82,
          children: [
            for (final p in profiles)
              _ProfileTile(
                profile: p,
                avatarSize: avatarSize,
                compact: compact,
                onTap: () => onTapProfile(p),
              ),
            if (profiles.length < cap)
              _AddMemberTile(
                avatarSize: avatarSize,
                compact: compact,
                onTap: onTapAddMember,
              ),
          ],
        );
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.avatarSize,
    required this.compact,
    required this.onTap,
  });
  final Profile profile;
  final double avatarSize;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KvlProfileAvatar(
            profileId: profile.id,
            initials: profile.initials,
            size: avatarSize,
            textSize: compact ? 34 : 40,
            gradientSeed: profile.avatarSeed ?? profile.id,
            border: Border.all(
              color: Colors.white.withValues(alpha: .38),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .22),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          SizedBox(
            width: avatarSize + 26,
            child: Text(
              profile.displayLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: KvlText.ui(
                compact ? 15 : 17,
                FontWeight.w500,
              ).copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

}

class _AddMemberTile extends StatelessWidget {
  const _AddMemberTile({
    required this.avatarSize,
    required this.compact,
    required this.onTap,
  });
  final double avatarSize;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .04),
              border: Border.all(
                color: Colors.white.withValues(alpha: .45),
                width: 1.4,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.add_rounded,
              color: Colors.white.withValues(alpha: .78),
              size: compact ? 42 : 50,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            context.l10n.addMemberTile,
            style: KvlText.ui(
              compact ? 15 : 17,
              FontWeight.w500,
            ).copyWith(color: Colors.white.withValues(alpha: .72)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AddProfileDialog extends StatefulWidget {
  const _AddProfileDialog();

  @override
  State<_AddProfileDialog> createState() => _AddProfileDialogState();
}

class _AddProfileDialogState extends State<_AddProfileDialog> {
  final _name = TextEditingController();
  FamilyRelation _relation = FamilyRelation.other;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KvlColors.bg,
      title: Text('Add Family Member', style: KvlText.title(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: KvlSpacing.md),
          DropdownButtonFormField<FamilyRelation>(
            initialValue: _relation,
            decoration: const InputDecoration(labelText: 'Relationship'),
            items: [
              for (final r in FamilyRelation.values)
                DropdownMenuItem(value: r, child: Text(r.label)),
            ],
            onChanged: (v) =>
                setState(() => _relation = v ?? FamilyRelation.other),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.of(context).pop((name: _name.text, relation: _relation));
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
