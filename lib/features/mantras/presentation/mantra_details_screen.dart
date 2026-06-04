import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/mantra.dart';

class MantraDetailsScreen extends ConsumerWidget {
  const MantraDetailsScreen({super.key, required this.mantraId});
  final String mantraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mantra = ref.watch(mantraByIdProvider(mantraId));
    if (mantra == null) {
      return KvlScaffold(
        title: 'Not found',
        body: Center(child: Text('Mantra not found', style: KvlText.body())),
      );
    }
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final script = mantra.name.scriptForLanguage(settings.languageCode);
    final name = mantra.name.displayForLanguage(settings.languageCode);
    return KvlScaffold(
      title: '$name Mantra Details',
      trailing: const _FavoriteButton(),
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
            label: 'Start Practice with $name Mantra',
            onPressed: () =>
                context.push('${KvlRoute.voiceTraining}/$mantraId'),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton();

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _on = false;
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
        child: Icon(
          _on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: _on ? KvlColors.primary : KvlColors.inkSoft,
          key: ValueKey(_on),
        ),
      ),
      onPressed: () => setState(() => _on = !_on),
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

class _PronunciationCard extends StatelessWidget {
  const _PronunciationCard({required this.mantra, required this.languageCode});
  final Mantra mantra;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final name = mantra.name.displayForLanguage(languageCode);
    return KvlCard(
      padding: const EdgeInsets.all(KvlSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: KvlColors.primaryGradient,
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
                  'Pronunciation Guide',
                  style: KvlText.ui(11.5, FontWeight.w600),
                ),
                Text('$name Mantra', style: KvlText.muted(10.5)),
              ],
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: KvlColors.primary,
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
