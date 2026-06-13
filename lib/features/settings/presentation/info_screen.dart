import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';

/// About App, Help & FAQs, Report Issue, Share Feedback, Privacy Policy.
class InfoScreen extends ConsumerWidget {
  const InfoScreen({super.key, required this.topic});
  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (topic == 'help') return const _FaqScreen();
    if (topic == 'report') return const _ReportScreen();

    // Privacy policy — load body from API, fall back to l10n string.
    if (topic == 'privacy') {
      final settingsAsync = ref.watch(appSettingsProvider);
      final privacyBody = settingsAsync.value?.privacyPolicy;
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
              (privacyBody != null && privacyBody.isNotEmpty)
                  ? privacyBody
                  : t.body,
              textAlign: TextAlign.center,
              style: KvlText.body(12).copyWith(height: 1.6),
            ),
          ],
        ),
      );
    }

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

// ---------------------------------------------------------------------------
// Report Issue — full text-input form that launches a mailto: on send.
// ---------------------------------------------------------------------------

class _ReportScreen extends ConsumerStatefulWidget {
  const _ReportScreen();

  @override
  ConsumerState<_ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<_ReportScreen> {
  static const _fallbackEmail = 'support@vaachikalekhini.com';

  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController(text: 'Bug Report');
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  String get _recipientEmail {
    final settings = ref.read(appSettingsProvider).value;
    return settings?.supportEmail ?? _fallbackEmail;
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);

    final email = _recipientEmail;
    final subject = Uri.encodeComponent(_subjectCtrl.text.trim());
    final body = Uri.encodeComponent(_bodyCtrl.text.trim());
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening your email app…'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No email app found. Please email $email directly.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    // Watch so the email address updates if the provider resolves after build.
    final settingsAsync = ref.watch(appSettingsProvider);
    final email = settingsAsync.value?.supportEmail ?? _fallbackEmail;

    return KvlScaffold(
      title: 'Report Issue',
      scrollable: true,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: KvlSpacing.md),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: KvlColors.primaryGhost,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.flag_outlined, color: KvlColors.primaryDeep, size: 26),
            ),
            const SizedBox(height: KvlSpacing.sm),
            Center(
              child: Text(
                'Tell us what went wrong',
                style: KvlText.title(16),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'We read every report and respond within 48 hours.',
                textAlign: TextAlign.center,
                style: KvlText.muted(11.5),
              ),
            ),
            const SizedBox(height: KvlSpacing.lg),
            TextFormField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject',
                hintText: 'e.g. Bug Report, Feature Request…',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
            ),
            const SizedBox(height: KvlSpacing.md),
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                hintText:
                    'What happened? What did you expect to happen? Which screen were you on?',
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              minLines: 5,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().length < 10)
                      ? 'Please describe the issue (at least 10 characters)'
                      : null,
            ),
            const SizedBox(height: KvlSpacing.lg),
            KvlButton(
              label: _sending ? 'Opening email…' : 'Send Report',
              icon: Icons.send_rounded,
              onPressed: _sending ? null : _send,
            ),
            const SizedBox(height: KvlSpacing.sm),
            Center(
              child: Text(
                'Sends to $email',
                style: KvlText.muted(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Help & FAQs — loaded from /api/v1/faqs with local fallback list.
// ---------------------------------------------------------------------------

class _FaqScreen extends ConsumerWidget {
  const _FaqScreen();

  static const _fallbackFaqs = [
    (
      q: 'How do I start a new mantra program?',
      a: 'Go to Programs → tap "Create New Program" → pick a mantra → set your daily target → begin.',
    ),
    (
      q: 'How do I contact support?',
      a: 'Go to Profile → Report Issue to send an email report. We respond to every message.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faqsAsync = ref.watch(faqsProvider);

    return KvlScaffold(
      title: context.l10n.infoHelpTitle,
      scrollable: false,
      body: faqsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _buildList(context, _fallbackFaqs.map((e) => (question: e.q, answer: e.a)).toList()),
        data: (faqs) {
          if (faqs.isEmpty) {
            return _buildList(
              context,
              _fallbackFaqs.map((e) => (question: e.q, answer: e.a)).toList(),
            );
          }
          return _buildList(context, faqs);
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<({String question, String answer})> faqs) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: KvlSpacing.sm),
      itemCount: faqs.length,
      separatorBuilder: (_, _) => const SizedBox(height: KvlSpacing.xs),
      itemBuilder: (context, i) => _FaqTile(q: faqs[i].question, a: faqs[i].answer),
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
