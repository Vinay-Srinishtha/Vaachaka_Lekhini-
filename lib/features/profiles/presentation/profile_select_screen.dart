import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [KvlColors.primary, KvlColors.primaryDeep],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(KvlSpacing.xl, KvlSpacing.huge, KvlSpacing.xl, KvlSpacing.xl),
            child: Column(
              children: [
                Text(
                  'Who is Practicing?',
                  style: KvlText.title(18).copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: KvlSpacing.xxl),
                Expanded(
                  child: profilesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                    error: (e, _) => Center(child: Text('$e', style: KvlText.body().copyWith(color: Colors.white))),
                    data: (profiles) => _ProfileGrid(
                      profiles: profiles,
                      cap: ref.watch(profileCapProvider),
                      onTapProfile: (p) async {
                        await ref.read(profileRepositoryProvider).setActive(p.id);
                        if (context.mounted) context.go(KvlRoute.home);
                      },
                      onTapAddMember: () => _showAddDialog(context, ref, session?.userId),
                    ),
                  ),
                ),
                const SizedBox(height: KvlSpacing.lg),
                if (hasSession)
                  _link(context, 'Manage Profiles', () => context.go(KvlRoute.profile)),
                _link(context, 'Login with another number', () => context.go(KvlRoute.otpLogin)),
                _link(context, 'Create a new account', () => context.go(KvlRoute.createAccount)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _link(BuildContext context, String label, VoidCallback onTap) => Padding(
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

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref, String? userId) async {
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
    final created = await repo.create(userId: userId, name: result.name, relation: result.relation);
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
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: KvlSpacing.xxl,
      mainAxisSpacing: KvlSpacing.lg,
      childAspectRatio: .9,
      children: [
        for (final p in profiles) _ProfileTile(profile: p, onTap: () => onTapProfile(p)),
        if (profiles.length < cap) _AddMemberTile(onTap: onTapAddMember),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.profile, required this.onTap});
  final Profile profile;
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
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .14),
              border: Border.all(color: Colors.white.withValues(alpha: .3), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              profile.initials,
              style: KvlText.title(28).copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.displayLabel,
            style: KvlText.caption(12.5).copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AddMemberTile extends StatelessWidget {
  const _AddMemberTile({required this.onTap});
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
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .55), width: 2, style: BorderStyle.solid),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text('Add Member',
              style: KvlText.caption(12.5).copyWith(color: Colors.white), textAlign: TextAlign.center),
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
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: KvlSpacing.md),
          DropdownButtonFormField<FamilyRelation>(
            initialValue: _relation,
            decoration: const InputDecoration(labelText: 'Relationship'),
            items: [
              for (final r in FamilyRelation.values)
                DropdownMenuItem(value: r, child: Text(r.label)),
            ],
            onChanged: (v) => setState(() => _relation = v ?? FamilyRelation.other),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
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
