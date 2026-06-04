import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

class InviteFriendsScreen extends ConsumerWidget {
  const InviteFriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final invite = ref.watch(inviteServiceProvider);
    final userId = session?.userId ?? 'guest';
    final link = invite.linkFor(userId);

    Future<void> doShare() async {
      await invite.share(userId, sender: session?.username);
    }

    Future<void> doCopy() async {
      await invite.copyLink(userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite link copied')),
        );
      }
    }

    return KvlScaffold(
      title: 'Invite Friends',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.lg),
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(color: KvlColors.primaryGhost, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.group_add_rounded, color: KvlColors.primaryDeep, size: 48),
            ),
          ),
          const SizedBox(height: KvlSpacing.lg),
          Text(
            'Share the journey of\nspiritual growth',
            textAlign: TextAlign.center,
            style: KvlText.title(18).copyWith(height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            'Invite friends to join Koti Vachika Lekhini and earn reward points.',
            textAlign: TextAlign.center,
            style: KvlText.caption(11.5).copyWith(height: 1.5),
          ),
          const SizedBox(height: KvlSpacing.lg),
          KvlCard(
            padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md, vertical: KvlSpacing.sm),
            onTap: doCopy,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    link,
                    style: KvlText.caption(11.5).copyWith(fontFamily: 'monospace', color: KvlColors.inkSoft),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: KvlColors.primaryGhost, borderRadius: KvlRadius.brSM),
                  alignment: Alignment.center,
                  child: const Icon(Icons.copy_rounded, color: KvlColors.primaryDeep, size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: KvlSpacing.md),
          _ShareTile(
            label: 'Share via WhatsApp',
            color: const Color(0xFF25D366),
            icon: Icons.chat_bubble_rounded,
            onTap: doShare,
          ),
          const SizedBox(height: KvlSpacing.sm),
          _ShareTile(
            label: 'Share via Facebook',
            color: const Color(0xFF1877F2),
            icon: Icons.facebook_rounded,
            onTap: doShare,
          ),
          const SizedBox(height: KvlSpacing.sm),
          _ShareTile(
            label: 'Share via Instagram',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFB95E), Color(0xFFC13584), Color(0xFF5851DB)],
            ),
            icon: Icons.camera_alt_rounded,
            onTap: doShare,
          ),
          const SizedBox(height: KvlSpacing.md),
          Center(
            child: Text(
              'All channels open your device share sheet.',
              style: KvlText.muted(10),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.gradient,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md, vertical: KvlSpacing.sm),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              gradient: gradient,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: KvlSpacing.sm),
          Text(label, style: KvlText.ui(12, FontWeight.w500)),
        ],
      ),
    );
  }
}
