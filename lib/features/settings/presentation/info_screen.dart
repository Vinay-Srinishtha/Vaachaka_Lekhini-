import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';

/// One screen for the small "content TBD" placeholders surfaced from Profile:
/// About App, Help & FAQs, Report Issue, Share Feedback, Privacy Policy.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.topic});
  final String topic;

  @override
  Widget build(BuildContext context) {
    final t = _topicFor(context, topic);
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

  _Topic _topicFor(BuildContext context, String key) {
    switch (key) {
      case 'help':
        return _Topic(
          title: context.l10n.infoHelpTitle,
          icon: Icons.help_outline_rounded,
          body: context.l10n.infoHelpBody,
        );
      case 'report':
        return _Topic(
          title: context.l10n.infoReportTitle,
          icon: Icons.flag_outlined,
          body: context.l10n.infoReportBody,
        );
      case 'feedback':
        return _Topic(
          title: context.l10n.infoFeedbackTitle,
          icon: Icons.feedback_outlined,
          body: context.l10n.infoFeedbackBody,
        );
      case 'privacy':
        return _Topic(
          title: context.l10n.infoPrivacyTitle,
          icon: Icons.lock_outline_rounded,
          body: context.l10n.infoPrivacyBody,
        );
      case 'about':
      default:
        return _Topic(
          title: context.l10n.infoAboutTitle,
          icon: Icons.self_improvement_rounded,
          body: context.l10n.infoAboutBody,
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
