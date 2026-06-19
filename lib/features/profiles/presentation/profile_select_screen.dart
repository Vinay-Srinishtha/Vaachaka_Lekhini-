import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../domain/profile.dart';

/// Transitional screen shown while auto-activating the primary profile.
/// The "who is practicing?" selection flow has been removed — each account
/// maps to a single practitioner. This widget finds the primary profile and
/// sets it active, then navigates to home.
class ProfileSelectScreen extends ConsumerStatefulWidget {
  const ProfileSelectScreen({super.key});

  @override
  ConsumerState<ProfileSelectScreen> createState() =>
      _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends ConsumerState<ProfileSelectScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);

    profilesAsync.whenData((profiles) {
      if (_handled || !mounted) return;
      final primary = profiles.firstWhere(
        (p) => p.relation == null || p.relation == FamilyRelation.me,
        orElse: () => profiles.isNotEmpty ? profiles.first : throw StateError('no profiles'),
      );
      _handled = true;
      ref.read(profileRepositoryProvider).setActive(primary.id).then((_) {
        ref.read(programsForActiveProfileProvider);
        if (mounted) context.go(KvlRoute.home);
      });
    });

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: KvlColors.welcomeGradient),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
