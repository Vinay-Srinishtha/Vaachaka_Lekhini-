import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/theme/theme.dart';
import '../../settings/domain/settings_repository.dart';
import '../../../l10n/l10n.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final languages = KvlLanguage.availableFor(
      ref.watch(mantraCatalogProvider),
    );
    final settingsRepo = ref.read(settingsRepositoryProvider);

    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: KvlColors.welcomeGradient),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final w = constraints.maxWidth;
                final compact = h < 760 || w < 390;
                final veryCompact = h < 680;
                final side = w < 360 ? KvlSpacing.lg : 42.0;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    side,
                    veryCompact ? KvlSpacing.md : KvlSpacing.xl,
                    side,
                    veryCompact ? KvlSpacing.md : KvlSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      _LanguageSelector(
                        compact: compact,
                        languages: languages,
                        currentCode: settings.languageCode,
                        onChanged: settingsRepo.setLanguage,
                      ),
                      const Spacer(flex: 3),
                      _AppMark(size: veryCompact ? 84 : (compact ? 96 : 112)),
                      SizedBox(height: veryCompact ? 10 : 18),
                      _ScaleText(
                        context.l10n.appName,
                        style: KvlText.mantraDevanagari(
                          veryCompact ? 32 : 42,
                        ).copyWith(color: Colors.white, height: 1.05),
                      ),
                      const SizedBox(height: 8),
                      _ScaleText(
                        context.l10n.appTagline,
                        style: KvlText.body(
                          veryCompact ? 14 : 17,
                        ).copyWith(color: Colors.white, height: 1.15),
                      ),
                      SizedBox(height: veryCompact ? 10 : 16),
                      _ScaleText(
                        context.l10n.appMottoChant,
                        style: KvlText.body(
                          veryCompact ? 13.5 : 16,
                        ).copyWith(color: Colors.white, height: 1.15),
                      ),
                      const Spacer(flex: 3),
                      _AuthActions(
                        compact: compact,
                        onLogin: () => context.push(KvlRoute.otpLogin),
                        onRegister: () => context.push(KvlRoute.createAccount),
                      ),
                      const Spacer(flex: 3),
                      const _KnowAppButton(),
                      const Spacer(flex: 4),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaleText extends StatelessWidget {
  const _ScaleText(this.text, {required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1, textAlign: TextAlign.center, style: style),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.compact,
    required this.languages,
    required this.currentCode,
    required this.onChanged,
  });

  final bool compact;
  final List<KvlLanguage> languages;
  final String currentCode;
  final Future<void> Function(String code) onChanged;

  @override
  Widget build(BuildContext context) {
    final languageStyle = KvlText.body(
      compact ? 15 : 17,
    ).copyWith(color: Colors.white);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.setLanguage,
          style: KvlText.body(compact ? 16 : 18).copyWith(color: KvlColors.ink),
        ),
        SizedBox(height: compact ? KvlSpacing.md : KvlSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final lang in languages)
              _LanguageTab(
                language: lang,
                selected: lang.code == currentCode,
                style: languageStyle,
                compact: compact,
                onTap: () => onChanged(lang.code),
              ),
          ],
        ),
      ],
    );
  }
}

class _LanguageTab extends StatelessWidget {
  const _LanguageTab({
    required this.language,
    required this.selected,
    required this.style,
    required this.compact,
    required this.onTap,
  });

  final KvlLanguage language;
  final bool selected;
  final TextStyle style;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = switch (language.code) {
      'hi' => KvlText.bodyDevanagari(
        compact ? 16 : 18,
      ).copyWith(color: Colors.white),
      'kn' => KvlText.bodyKannada(
        compact ? 16 : 18,
      ).copyWith(color: Colors.white),
      _ => style,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: KvlRadius.brSM,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          language.nativeLabel,
          style: textStyle.copyWith(
            decoration: selected ? TextDecoration.underline : null,
            decorationColor: Colors.white,
            decorationThickness: 1.2,
          ),
        ),
      ),
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .22),
        child: Image.asset(
          'assets/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _AuthActions extends StatelessWidget {
  const _AuthActions({
    required this.compact,
    required this.onLogin,
    required this.onRegister,
  });
  final bool compact;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AuthButton(
            eyebrow: context.l10n.existingUser,
            label: context.l10n.loginButton,
            compact: compact,
            onTap: onLogin,
          ),
        ),
        SizedBox(width: compact ? KvlSpacing.md : KvlSpacing.xl),
        Expanded(
          child: _AuthButton(
            eyebrow: context.l10n.newUser,
            label: context.l10n.registerButton,
            compact: compact,
            onTap: onRegister,
          ),
        ),
      ],
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.eyebrow,
    required this.label,
    required this.compact,
    required this.onTap,
  });
  final String eyebrow;
  final String label;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFCEF),
      borderRadius: KvlRadius.brPill,
      elevation: 9,
      shadowColor: Colors.black.withValues(alpha: .22),
      child: InkWell(
        onTap: onTap,
        borderRadius: KvlRadius.brPill,
        child: SizedBox(
          height: compact ? 66 : 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScaleText(
                eyebrow,
                style: KvlText.caption(
                  compact ? 11.5 : 13,
                ).copyWith(color: const Color(0xFF1E2733)),
              ),
              _ScaleText(
                label,
                style: KvlText.title(
                  compact ? 18 : 22,
                  FontWeight.w400,
                ).copyWith(color: KvlColors.primary, height: 1.05),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KnowAppButton extends StatelessWidget {
  const _KnowAppButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: KvlSpacing.lg,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: KvlRadius.brPill,
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      child: Text(
        context.l10n.knowOurApp,
        textAlign: TextAlign.center,
        style: KvlText.body(16).copyWith(color: Colors.white, height: 1.1),
      ),
    );
  }
}
