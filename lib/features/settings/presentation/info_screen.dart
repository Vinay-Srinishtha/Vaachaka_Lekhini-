import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
    if (topic == 'feedback') return const _FeedbackScreen();
    if (topic == 'privacy') return const _PrivacyScreen();
    if (topic == 'about') return const _AboutScreen();

    // Fallback
    return _SimpleInfoScreen(
      title: context.l10n.infoAboutTitle,
      icon: Icons.self_improvement_rounded,
      iconBg: KvlColors.primaryGhost,
      iconColor: KvlColors.primaryDeep,
      body: context.l10n.infoAboutBody,
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

Widget _heroIcon({
  required IconData icon,
  required Color bg,
  required Color color,
  double size = 72,
  double iconSize = 32,
}) {
  return Center(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: iconSize),
    ),
  );
}

Widget _infoChip(IconData icon, String label, Color bg, Color fg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 6),
        Text(label, style: KvlText.ui(12, FontWeight.w600).copyWith(color: fg)),
      ],
    ),
  );
}

SnackBar _errorSnack(String msg) => SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
      backgroundColor: KvlColors.danger,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: '✕',
        textColor: Colors.white,
        onPressed: () {},  // Flutter auto-dismisses the snackbar on action tap
      ),
    );

// ---------------------------------------------------------------------------
// About App
// ---------------------------------------------------------------------------

class _AboutScreen extends ConsumerWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return KvlScaffold(
      title: context.l10n.infoAboutTitle,
      scrollable: false,
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _MarkdownBody(
          markdown: context.l10n.infoAboutBody,
          headerIcon: Icons.self_improvement_rounded,
          headerIconBg: KvlColors.primaryGhost,
          headerIconColor: KvlColors.primaryDeep,
          title: context.l10n.infoAboutTitle,
        ),
        data: (s) => _MarkdownBody(
          markdown: (s.aboutApp?.isNotEmpty == true)
              ? s.aboutApp!
              : context.l10n.infoAboutBody,
          headerIcon: Icons.self_improvement_rounded,
          headerIconBg: KvlColors.primaryGhost,
          headerIconColor: KvlColors.primaryDeep,
          title: context.l10n.infoAboutTitle,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Privacy Policy
// ---------------------------------------------------------------------------

class _PrivacyScreen extends ConsumerWidget {
  const _PrivacyScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return KvlScaffold(
      title: context.l10n.infoPrivacyTitle,
      scrollable: false,
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _MarkdownBody(
          markdown: context.l10n.infoPrivacyBody,
          headerIcon: Icons.lock_rounded,
          headerIconBg: KvlColors.accentSoft,
          headerIconColor: KvlColors.accent,
          title: context.l10n.infoPrivacyTitle,
          chip: 'Your data stays private',
        ),
        data: (s) => _MarkdownBody(
          markdown: (s.privacyPolicy.isNotEmpty)
              ? s.privacyPolicy
              : context.l10n.infoPrivacyBody,
          headerIcon: Icons.lock_rounded,
          headerIconBg: KvlColors.accentSoft,
          headerIconColor: KvlColors.accent,
          title: context.l10n.infoPrivacyTitle,
          chip: 'Your data stays private',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium Markdown body — used by About App + Privacy Policy
// ---------------------------------------------------------------------------

class _MarkdownBody extends StatelessWidget {
  const _MarkdownBody({
    required this.markdown,
    required this.headerIcon,
    required this.headerIconBg,
    required this.headerIconColor,
    required this.title,
    this.chip,
  });

  final String markdown;
  final IconData headerIcon;
  final Color headerIconBg;
  final Color headerIconColor;
  final String title;
  final String? chip;

  @override
  Widget build(BuildContext context) {
    final mdStyle = MarkdownStyleSheet(
      // Body text
      p: KvlText.body(14).copyWith(height: 1.75, color: KvlColors.inkSoft),
      // Headings
      h1: KvlText.title(22).copyWith(color: KvlColors.ink, height: 1.3),
      h2: KvlText.title(18).copyWith(color: KvlColors.ink, height: 1.3),
      h3: KvlText.ui(15, FontWeight.w700).copyWith(color: KvlColors.inkSoft, height: 1.4),
      // Lists
      listBullet: KvlText.body(14).copyWith(color: KvlColors.primary),
      // Blockquote
      blockquote: KvlText.body(14).copyWith(
        color: KvlColors.inkSoft,
        fontStyle: FontStyle.italic,
        height: 1.7,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: KvlColors.primary, width: 3.5)),
        color: KvlColors.primaryGhost,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      // Code
      code: KvlText.caption(12.5).copyWith(
        fontFamily: 'monospace',
        color: KvlColors.primaryDeep,
        backgroundColor: KvlColors.primaryGhost,
      ),
      codeblockDecoration: BoxDecoration(
        color: KvlColors.primaryGhost,
        borderRadius: KvlRadius.brMD,
        border: Border.all(color: KvlColors.primarySoft),
      ),
      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: KvlColors.rule, width: 1),
        ),
      ),
      // Spacing
      pPadding: const EdgeInsets.only(bottom: 12),
      h1Padding: const EdgeInsets.only(top: 20, bottom: 8),
      h2Padding: const EdgeInsets.only(top: 16, bottom: 6),
      h3Padding: const EdgeInsets.only(top: 12, bottom: 4),
      listIndent: 20,
      blockSpacing: 12,
      tableHead: KvlText.caption(12).copyWith(fontWeight: FontWeight.w700, color: KvlColors.ink),
      tableBody: KvlText.body(13).copyWith(color: KvlColors.inkSoft),
      tableHeadAlign: TextAlign.left,
      tableBorder: TableBorder.all(color: KvlColors.rule, width: 1),
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sticky header
        Padding(
          padding: const EdgeInsets.fromLTRB(0, KvlSpacing.md, 0, KvlSpacing.sm),
          child: Column(
            children: [
              _heroIcon(icon: headerIcon, bg: headerIconBg, color: headerIconColor),
              const SizedBox(height: KvlSpacing.sm),
              Text(title, style: KvlText.title(18), textAlign: TextAlign.center),
              if (chip != null) ...[
                const SizedBox(height: KvlSpacing.xs),
                _infoChip(Icons.verified_rounded, chip!, headerIconBg, headerIconColor),
              ],
            ],
          ),
        ),
        // Scrollable markdown content
        Expanded(
          child: Markdown(
            data: markdown,
            styleSheet: mdStyle,
            padding: const EdgeInsets.fromLTRB(
              KvlSpacing.md,
              KvlSpacing.sm,
              KvlSpacing.md,
              KvlSpacing.xl,
            ),
            onTapLink: (text, href, title) async {
              if (href != null) {
                final uri = Uri.tryParse(href);
                if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            shrinkWrap: false,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Simple info (About)
// ---------------------------------------------------------------------------

class _SimpleInfoScreen extends StatelessWidget {
  const _SimpleInfoScreen({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.body,
  });
  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String body;

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: title,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.lg),
          _heroIcon(icon: icon, bg: iconBg, color: iconColor),
          const SizedBox(height: KvlSpacing.md),
          Center(child: Text(title, style: KvlText.title(18))),
          const SizedBox(height: KvlSpacing.md),
          Container(
            padding: const EdgeInsets.all(KvlSpacing.md),
            decoration: BoxDecoration(
              color: KvlColors.surface,
              borderRadius: KvlRadius.brLG,
              border: Border.all(color: KvlColors.border),
            ),
            child: Text(
              body,
              style: KvlText.body(13).copyWith(height: 1.7, color: KvlColors.inkSoft),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Report Issue
// ---------------------------------------------------------------------------

class _ReportScreen extends ConsumerStatefulWidget {
  const _ReportScreen();

  @override
  ConsumerState<_ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<_ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController(text: 'Bug Report');
  final _bodyCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.post<void>(
        '/api/v1/support',
        data: {
          'kind': 'report',
          'subject': _subjectCtrl.text.trim(),
          'body': _bodyCtrl.text.trim(),
        },
      );
      if (mounted) setState(() { _sending = false; _sent = true; });
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(_errorSnack('Failed to send: ${e.message ?? 'network error'}'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: 'Report Issue',
      scrollable: true,
      body: _sent ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.lg),

          // Hero icon
          _heroIcon(
            icon: Icons.flag_rounded,
            bg: const Color(0xFFFFEBE9),
            color: KvlColors.danger,
          ),
          const SizedBox(height: KvlSpacing.md),
          Center(child: Text('Report an Issue', style: KvlText.title(18))),
          const SizedBox(height: KvlSpacing.xs),
          Center(
            child: Text(
              'We read every report and respond within 48 hours.',
              textAlign: TextAlign.center,
              style: KvlText.muted(12),
            ),
          ),
          const SizedBox(height: KvlSpacing.md),

          // Info chips row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip(Icons.timer_outlined, '48h response', KvlColors.primaryGhost, KvlColors.primaryDeep),
              const SizedBox(width: 8),
              _infoChip(Icons.lock_outline_rounded, 'Private', KvlColors.accentSoft, KvlColors.accent),
            ],
          ),
          const SizedBox(height: KvlSpacing.lg),

          // Form card
          Container(
            padding: const EdgeInsets.all(KvlSpacing.md),
            decoration: BoxDecoration(
              color: KvlColors.surface,
              borderRadius: KvlRadius.brLG,
              border: Border.all(color: KvlColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    hintText: 'e.g. Bug Report, Feature Request…',
                    prefixIcon: Icon(Icons.title_rounded, size: 18),
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
                    hintText: 'What happened? What did you expect? Which screen?',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 80),
                      child: Icon(Icons.edit_note_rounded, size: 18),
                    ),
                  ),
                  maxLines: 8,
                  minLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Please describe the issue (at least 10 characters)'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: KvlSpacing.lg),

          KvlButton(
            label: _sending ? 'Sending…' : 'Send Report',
            icon: Icons.send_rounded,
            onPressed: _sending ? null : _send,
          ),
          const SizedBox(height: KvlSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: KvlSpacing.xl),
        _heroIcon(
          icon: Icons.check_circle_rounded,
          bg: KvlColors.successSoft,
          color: KvlColors.success,
          size: 80,
          iconSize: 36,
        ),
        const SizedBox(height: KvlSpacing.md),
        Center(child: Text('Report Submitted', style: KvlText.title(18))),
        const SizedBox(height: KvlSpacing.sm),
        Center(
          child: Text(
            "We'll read your report and respond within 48 hours.",
            textAlign: TextAlign.center,
            style: KvlText.muted(13),
          ),
        ),
        const SizedBox(height: KvlSpacing.lg),
        Center(
          child: _infoChip(Icons.favorite_rounded, 'Thank you for helping us improve', KvlColors.primaryGhost, KvlColors.primaryDeep),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Share Feedback
// ---------------------------------------------------------------------------

class _FeedbackScreen extends ConsumerStatefulWidget {
  const _FeedbackScreen();

  @override
  ConsumerState<_FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<_FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController(text: 'Suggestion');
  final _bodyCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.post<void>(
        '/api/v1/support',
        data: {
          'kind': 'feedback',
          'subject': _subjectCtrl.text.trim(),
          'body': _bodyCtrl.text.trim(),
        },
      );
      if (mounted) setState(() { _sending = false; _sent = true; });
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(_errorSnack('Failed to send: ${e.message ?? 'network error'}'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: 'Share Feedback',
      scrollable: true,
      body: _sent ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.lg),

          _heroIcon(
            icon: Icons.favorite_rounded,
            bg: KvlColors.primaryGhost,
            color: KvlColors.primary,
          ),
          const SizedBox(height: KvlSpacing.md),
          Center(child: Text('Share Your Thoughts', style: KvlText.title(18))),
          const SizedBox(height: KvlSpacing.xs),
          Center(
            child: Text(
              'We listen to every suggestion and use it to improve the app.',
              textAlign: TextAlign.center,
              style: KvlText.muted(12),
            ),
          ),
          const SizedBox(height: KvlSpacing.md),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip(Icons.auto_awesome_rounded, 'Shapes the roadmap', KvlColors.primaryGhost, KvlColors.primaryDeep),
              const SizedBox(width: 8),
              _infoChip(Icons.visibility_off_outlined, 'Anonymous ok', KvlColors.accentSoft, KvlColors.accent),
            ],
          ),
          const SizedBox(height: KvlSpacing.lg),

          Container(
            padding: const EdgeInsets.all(KvlSpacing.md),
            decoration: BoxDecoration(
              color: KvlColors.surface,
              borderRadius: KvlRadius.brLG,
              border: Border.all(color: KvlColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    hintText: 'e.g. Suggestion, Idea, Compliment…',
                    prefixIcon: Icon(Icons.label_outline_rounded, size: 18),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
                ),
                const SizedBox(height: KvlSpacing.md),
                TextFormField(
                  controller: _bodyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Your feedback',
                    hintText: 'What do you love? What could be better?',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 80),
                      child: Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    ),
                  ),
                  maxLines: 8,
                  minLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Please share a bit more (at least 10 characters)'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: KvlSpacing.lg),

          KvlButton(
            label: _sending ? 'Sending…' : 'Send Feedback',
            icon: Icons.send_rounded,
            onPressed: _sending ? null : _send,
          ),
          const SizedBox(height: KvlSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: KvlSpacing.xl),
        _heroIcon(
          icon: Icons.favorite_rounded,
          bg: KvlColors.primaryGhost,
          color: KvlColors.primary,
          size: 80,
          iconSize: 36,
        ),
        const SizedBox(height: KvlSpacing.md),
        Center(child: Text('Thank You!', style: KvlText.title(18))),
        const SizedBox(height: KvlSpacing.sm),
        Center(
          child: Text(
            'We read every suggestion and use it to improve the app.',
            textAlign: TextAlign.center,
            style: KvlText.muted(13),
          ),
        ),
        const SizedBox(height: KvlSpacing.lg),
        Center(
          child: _infoChip(Icons.auto_awesome_rounded, 'Your voice shapes the app', KvlColors.primaryGhost, KvlColors.primaryDeep),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Help & FAQs
// ---------------------------------------------------------------------------

class _FaqScreen extends ConsumerWidget {
  const _FaqScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faqsAsync = ref.watch(faqsProvider);

    return KvlScaffold(
      title: context.l10n.infoHelpTitle,
      scrollable: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header banner
          Container(
            margin: const EdgeInsets.only(bottom: KvlSpacing.md),
            padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md, vertical: KvlSpacing.sm),
            decoration: BoxDecoration(
              gradient: KvlColors.primaryGradient,
              borderRadius: KvlRadius.brLG,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: KvlSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Help & FAQs',
                          style: KvlText.ui(14, FontWeight.w700).copyWith(color: Colors.white)),
                      Text('Tap a question to expand the answer',
                          style: KvlText.ui(11, FontWeight.w400).copyWith(
                              color: Colors.white.withValues(alpha: .85))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: faqsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: KvlColors.muted, size: 40),
                    const SizedBox(height: KvlSpacing.sm),
                    Text(
                      'Could not load FAQs.\nPlease check your connection.',
                      style: KvlText.muted(13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (faqs) => faqs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox_rounded, color: KvlColors.muted, size: 40),
                          const SizedBox(height: KvlSpacing.sm),
                          Text('No FAQs available yet.', style: KvlText.muted(13)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: faqs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: KvlSpacing.xs),
                      itemBuilder: (context, i) =>
                          _FaqTile(q: faqs[i].question, a: faqs[i].answer, index: i),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.q, required this.a, required this.index});
  final String q;
  final String a;
  final int index;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  static const _accentColors = [
    KvlColors.primary,
    KvlColors.accent,
    KvlColors.gold,
    KvlColors.success,
  ];

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColors[widget.index % _accentColors.length];

    return Container(
      decoration: BoxDecoration(
        color: KvlColors.surface,
        borderRadius: KvlRadius.brLG,
        border: Border.all(
          color: _open ? accentColor.withValues(alpha: .4) : KvlColors.border,
          width: _open ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: KvlRadius.brLG,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KvlSpacing.md,
                  vertical: KvlSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: .12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.index + 1}',
                        style: KvlText.ui(11, FontWeight.w700).copyWith(color: accentColor),
                      ),
                    ),
                    const SizedBox(width: KvlSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.q,
                        style: KvlText.ui(13, FontWeight.w600),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: _open
                  ? Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: .05),
                        border: Border(top: BorderSide(color: accentColor.withValues(alpha: .15))),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        KvlSpacing.md, KvlSpacing.sm, KvlSpacing.md, KvlSpacing.md),
                      child: Text(
                        widget.a,
                        style: KvlText.body(12.5).copyWith(
                          height: 1.65,
                          color: KvlColors.inkSoft,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
