import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// One screen for the small "content TBD" placeholders surfaced from Profile:
/// About App, Help & FAQs, Report Issue, Share Feedback, Privacy Policy.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.topic});
  final String topic;

  @override
  Widget build(BuildContext context) {
    final t = _topicFor(topic);
    return KvlScaffold(
      title: t.title,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.lg),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: KvlColors.primaryGhost,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(t.icon, color: KvlColors.primaryDeep, size: 28),
          ),
          const SizedBox(height: KvlSpacing.md),
          Center(child: Text(t.title, style: KvlText.title(17))),
          const SizedBox(height: KvlSpacing.sm),
          Text(
            t.body,
            textAlign: TextAlign.center,
            style: KvlText.body(12).copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  _Topic _topicFor(String key) {
    switch (key) {
      case 'help':
        return const _Topic(
          title: 'Help & FAQs',
          icon: Icons.help_outline_rounded,
          body:
              'Common questions and how-to guides will be published here. For urgent issues, please use Report Issue.',
        );
      case 'report':
        return const _Topic(
          title: 'Report Issue',
          icon: Icons.flag_outlined,
          body:
              'Tell us what went wrong and we will look into it. Email integration is being set up.',
        );
      case 'feedback':
        return const _Topic(
          title: 'Share Feedback',
          icon: Icons.feedback_outlined,
          body:
              'We listen to every suggestion. Let us know what feels right or what needs to change.',
        );
      case 'privacy':
        return const _Topic(
          title: 'Privacy Policy',
          icon: Icons.lock_outline_rounded,
          body:
              'Your practice data lives on your device until you choose to sync it. Voice and handwriting samples never leave this device in version 1.',
        );
      case 'about':
      default:
        return const _Topic(
          title: 'About Vaachaka Lekhini',
          icon: Icons.self_improvement_rounded,
          body:
              'Vaachaka Lekhini is your personal spiritual practice companion. Chant or write your chosen mantras, track your progress, and grow your discipline — together with your family.\n\nVersion 0.1.0',
        );
    }
  }
}

class _Topic {
  const _Topic({required this.title, required this.icon, required this.body});
  final String title;
  final IconData icon;
  final String body;
}
