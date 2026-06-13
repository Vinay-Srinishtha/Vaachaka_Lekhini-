import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../settings/domain/settings_repository.dart';
import '../../../l10n/l10n.dart';
import '../domain/mantra.dart';

class MantraDetailsScreen extends ConsumerWidget {
  const MantraDetailsScreen({super.key, required this.mantraId});
  final String mantraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mantra = ref.watch(mantraByIdProvider(mantraId));
    if (mantra == null) {
      return KvlScaffold(
        title: context.l10n.mantraNotFoundTitle,
        body: Center(child: Text(context.l10n.mantraNotFound, style: KvlText.body())),
      );
    }
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final script = mantra.name.scriptForLanguage(settings.languageCode);
    final name = mantra.name.displayForLanguage(settings.languageCode);
    return KvlScaffold(
      title: '$name Mantra Details',

      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.sm),
          MantraText(name, script: script, size: 32),
          const SizedBox(height: KvlSpacing.md),
          _DeityHero(),
          const SizedBox(height: KvlSpacing.md),
          Text(
            mantra.description,
            style: KvlText.body(
              12,
            ).copyWith(height: 1.55, color: KvlColors.inkSoft),
          ),
          const SizedBox(height: KvlSpacing.md),
          _PronunciationCard(
            mantra: mantra,
            languageCode: settings.languageCode,
          ),
          const SizedBox(height: KvlSpacing.md),
          KvlButton(
            label: context.l10n.startPracticeWithMantra(name),
            onPressed: () =>
                context.push('${KvlRoute.voiceTraining}/$mantraId'),
          ),
        ],
      ),
    );
  }
}


class _DeityHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: KvlRadius.brLG,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A2B1A), Color(0xFF7A4422)],
          ),
        ),
        child: Center(
          child: Text(
            'ॐ',
            style: KvlText.mantraDevanagari(
              110,
            ).copyWith(color: Colors.white.withValues(alpha: .4)),
          ),
        ),
      ),
    );
  }
}

class _PronunciationCard extends StatefulWidget {
  const _PronunciationCard({required this.mantra, required this.languageCode});
  final Mantra mantra;
  final String languageCode;

  @override
  State<_PronunciationCard> createState() => _PronunciationCardState();
}

class _PronunciationCardState extends State<_PronunciationCard> {
  bool _loading = false;

  Future<void> _play() async {
    final asset = widget.mantra.pronunciationAsset;
    if (asset == null || asset.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pronunciation audio not available for this mantra yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final uri = Uri.tryParse(asset);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open pronunciation audio.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.mantra.name.displayForLanguage(widget.languageCode);
    final hasAudio = widget.mantra.pronunciationAsset?.isNotEmpty ?? false;

    return KvlCard(
      padding: const EdgeInsets.all(KvlSpacing.md),
      onTap: _play,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: hasAudio
                  ? KvlColors.primaryGradient
                  : const LinearGradient(colors: [KvlColors.muted, KvlColors.muted]),
              borderRadius: KvlRadius.brSM,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: KvlSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.pronunciationGuide,
                  style: KvlText.ui(11.5, FontWeight.w600),
                ),
                Text(
                  hasAudio ? '$name Mantra' : 'Audio coming soon',
                  style: KvlText.muted(10.5),
                ),
              ],
            ),
          ),
          if (_loading)
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: hasAudio ? KvlColors.primary : KvlColors.muted,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}
