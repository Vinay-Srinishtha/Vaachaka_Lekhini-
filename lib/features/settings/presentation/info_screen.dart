import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';

/// About App, Help & FAQs, Report Issue, Share Feedback, Privacy Policy.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.topic});
  final String topic;

  @override
  Widget build(BuildContext context) {
    if (topic == 'help') return const _FaqScreen();

    final t = _topicFor(context, topic);
    final actionLabel = _actionLabel(context, topic);
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
          if (actionLabel != null) ...[
            const SizedBox(height: KvlSpacing.xl),
            KvlButton(
              label: actionLabel,
              icon: Icons.open_in_new_rounded,
              onPressed: () => _launchAction(context, topic),
            ),
          ],
        ],
      ),
    );
  }

  String? _actionLabel(BuildContext context, String key) => switch (key) {
    'report' => 'Send Email Report',
    'feedback' => 'Share Feedback via Email',
    _ => null,
  };

  Future<void> _launchAction(BuildContext context, String key) async {
    final Uri uri;
    switch (key) {
      case 'report':
        uri = Uri(
          scheme: 'mailto',
          path: 'support@vaachikalekhini.com',
          query: 'subject=Bug Report - Vaachika Lekhini',
        );
      case 'feedback':
        uri = Uri(
          scheme: 'mailto',
          path: 'support@vaachikalekhini.com',
          query: 'subject=Feedback - Vaachika Lekhini',
        );
      default:
        return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  _Topic _topicFor(BuildContext context, String key) {
    switch (key) {
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

class _FaqScreen extends StatelessWidget {
  const _FaqScreen();

  static const _faqs = [
    (
      q: 'How do I start a new mantra program?',
      a: 'Go to Programs → tap "Create New Program" → pick a mantra → set your daily target → begin. Your progress is saved automatically.',
    ),
    (
      q: 'How does voice counting work?',
      a: 'Vaachaka Lekhini listens for your mantra using offline speech recognition (Vosk). No audio is ever sent to a server. Tap START on the counter screen, chant aloud, and the counter increments automatically.',
    ),
    (
      q: 'Why isn\'t my voice being counted?',
      a: 'Make sure microphone permission is granted in your phone\'s Settings. Try re-training your voice sample in Profile → Voice Settings → Re-train Voice. Speak at a normal pace with a brief pause between repetitions.',
    ),
    (
      q: 'How does handwriting verification work?',
      a: 'When you write the mantra on-screen, the app compares it to your enrolled sample using a pixel-grid similarity check. If your score is below the threshold, try writing more slowly and clearly.',
    ),
    (
      q: 'Where is my data stored?',
      a: 'All practice data (chant counts, session history, handwriting samples) lives on your device in a local database. It is synced to the cloud when you are connected, so you can restore everything on a new device by logging in with your registered number.',
    ),
    (
      q: 'How do I change my registered mobile number?',
      a: 'Go to Profile → Edit (top right) → tap the phone number field → enter your new number → verify via OTP. The change is saved to the server immediately.',
    ),
    (
      q: 'How do reward points work?',
      a: 'You earn points by completing milestones (1,000 / 10,000 / 1,00,000 / 10,00,000 chants) and when friends you invite join the app. Points can be redeemed in the Store tab.',
    ),
    (
      q: 'Can I add family members?',
      a: 'Yes. Go to Profile → Family Members → Add Family Member. Each member has their own programs, progress, and reward balance. Switch between members using the profile selector.',
    ),
    (
      q: 'What if the app doesn\'t notify me at the right time?',
      a: 'Go to Profile → Practice Settings → Reminder Time and set your preferred time. Make sure notification permission is granted for this app in your phone\'s Settings.',
    ),
    (
      q: 'How do I contact support?',
      a: 'Go to Profile → Report Issue to send an email report, or tap Share Feedback to send a suggestion. We respond to every message.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: context.l10n.infoHelpTitle,
      scrollable: false,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: KvlSpacing.sm),
        itemCount: _faqs.length,
        separatorBuilder: (_, _) => const SizedBox(height: KvlSpacing.xs),
        itemBuilder: (context, i) => _FaqTile(q: _faqs[i].q, a: _faqs[i].a),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.q, required this.a});
  final String q;
  final String a;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: KvlRadius.brLG,
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KvlSpacing.md,
            vertical: KvlSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.q,
                      style: KvlText.ui(13, FontWeight.w600),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: KvlColors.primaryDeep,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _open
                    ? Padding(
                        padding: const EdgeInsets.only(top: KvlSpacing.sm),
                        child: Text(
                          widget.a,
                          style: KvlText.body(12).copyWith(
                            height: 1.6,
                            color: KvlColors.inkSoft,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Topic {
  const _Topic({required this.title, required this.icon, required this.body});
  final String title;
  final IconData icon;
  final String body;
}
