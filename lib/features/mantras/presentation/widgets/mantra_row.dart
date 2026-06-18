import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/i18n/language_options.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../settings/domain/settings_repository.dart';
import '../../domain/mantra.dart';

/// Selectable row matching mockup 2.1 / 2.2. Active state shows
/// the saffron-soft background + filled radio.
class MantraRow extends ConsumerWidget {
  const MantraRow({
    super.key,
    required this.mantra,
    required this.selected,
    required this.onTap,
  });

  final Mantra mantra;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final script = mantra.name.scriptForLanguage(settings.languageCode);
    final name = mantra.name.displayForLanguage(settings.languageCode);
    return Padding(
      padding: const EdgeInsets.only(bottom: KvlSpacing.sm),
      child: KvlCard(
        variant: selected ? KvlCardVariant.soft : KvlCardVariant.plain,
        border: selected
            ? Border.all(color: KvlColors.primary, width: 1.5)
            : null,
        padding: const EdgeInsets.symmetric(
          horizontal: KvlSpacing.md,
          vertical: KvlSpacing.md,
        ),
        onTap: onTap,
        child: Row(
          children: [
            MantraThumb(
              glyph: mantra.name.thumbGlyph(),
              imageUrl: mantra.previewImageUrl ?? mantra.imageUrl,
            ),
            const SizedBox(width: KvlSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: KvlText.bodyByScript(
                      script,
                      13,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mantra.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KvlText.caption(11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: KvlSpacing.sm),
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? KvlColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? KvlColors.primary : KvlColors.border,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
          : null,
    );
  }
}
