import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/theme/theme.dart';
import '../../settings/domain/settings_repository.dart';
import '../../../l10n/l10n.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _languageChosen = false;

  @override
  void initState() {
    super.initState();
    // Show auth buttons immediately for returning users who already have a
    // persisted language preference (settingsProvider has a sync Hive value).
    final saved = ref.read(settingsProvider).value;
    if (saved != null) _languageChosen = true;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final languages = KvlLanguage.availableFor(
      ref.watch(mantraCatalogProvider).value ?? const [],
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
                      const Spacer(flex: 3),
                      _AppMark(size: veryCompact ? 84 : (compact ? 96 : 112)),
                      SizedBox(height: veryCompact ? 10 : 18),
                      _ScaleText(
                        context.l10n.appName,
                        style: KvlText.mantraDevanagari(
                          veryCompact ? 32 : 44,
                        ).copyWith(
                          color: Colors.white,
                          height: 1.05,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: .35),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      _ScaleText(
                        context.l10n.appTagline,
                        style: KvlText.body(
                          veryCompact ? 13 : 15.5,
                        ).copyWith(
                          color: Colors.white.withValues(alpha: .88),
                          height: 1.3,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: veryCompact ? 6 : 10),
                      // decorative divider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 28, height: 1, color: Colors.white.withValues(alpha: .30)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('🕉', style: TextStyle(fontSize: veryCompact ? 13 : 15)),
                          ),
                          Container(width: 28, height: 1, color: Colors.white.withValues(alpha: .30)),
                        ],
                      ),
                      SizedBox(height: veryCompact ? 6 : 10),
                      _ScaleText(
                        context.l10n.appMottoChant,
                        style: KvlText.body(
                          veryCompact ? 12.5 : 14.5,
                        ).copyWith(
                          color: Colors.white.withValues(alpha: .80),
                          height: 1.3,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: veryCompact ? 14 : 22),
                      // Language selector moved here — below the tagline
                      _LanguageSelector(
                        compact: compact,
                        languages: languages,
                        currentCode: settings.languageCode,
                        onChanged: (code) async {
                          await settingsRepo.setLanguage(code);
                          if (mounted) setState(() => _languageChosen = true);
                        },
                      ),
                      const Spacer(flex: 3),
                      // Login/Register hidden until language is chosen
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: _languageChosen
                            ? KeyedSubtree(
                                key: const ValueKey('auth'),
                                child: _AuthActions(
                                  compact: compact,
                                  onLogin: () =>
                                      context.push(KvlRoute.otpLogin),
                                  onRegister: () =>
                                      context.push(KvlRoute.createAccount),
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('hidden')),
                      ),
                      const Spacer(flex: 3),
                      _KnowAppButton(onTap: () => context.push('/info/about')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          context.l10n.setLanguage,
          style: KvlText.body(compact ? 12 : 13).copyWith(
            color: Colors.white.withValues(alpha: .65),
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: compact ? KvlSpacing.sm : KvlSpacing.md),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: Colors.black.withValues(alpha: .18),
            border: Border.all(color: Colors.white.withValues(alpha: .15), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final lang in languages)
                _LanguageTab(
                  language: lang,
                  selected: lang.code == currentCode,
                  compact: compact,
                  onTap: () => onChanged(lang.code),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageTab extends StatelessWidget {
  const _LanguageTab({
    required this.language,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final KvlLanguage language;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 14.0 : 15.5;
    final textStyle = switch (language.code) {
      'hi' => KvlText.bodyDevanagari(fontSize),
      'kn' => KvlText.bodyKannada(fontSize),
      _ => KvlText.body(fontSize),
    };
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 7 : 9,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          color: selected ? Colors.white.withValues(alpha: .92) : Colors.transparent,
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withValues(alpha: .15), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          language.nativeLabel,
          style: textStyle.copyWith(
            color: selected ? const Color(0xFFB03A10) : Colors.white.withValues(alpha: .88),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
    return Stack(
      alignment: Alignment.center,
      children: [
        // golden glow ring
        Container(
          width: size + 28,
          height: size + 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFD080).withValues(alpha: .55),
                const Color(0xFFFFAA30).withValues(alpha: .18),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // icon
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * .22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B2800).withValues(alpha: .55),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFFFFCC60).withValues(alpha: .22),
                blurRadius: 16,
                offset: Offset.zero,
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
        ),
      ],
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
      color: Colors.transparent,
      borderRadius: KvlRadius.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: KvlRadius.brPill,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: KvlRadius.brPill,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFDF4), Color(0xFFFFF0D0)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B1A00).withValues(alpha: .38),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: .12),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: SizedBox(
            height: compact ? 68 : 78,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScaleText(
                  eyebrow,
                  style: KvlText.caption(
                    compact ? 11 : 12.5,
                  ).copyWith(
                    color: const Color(0xFF6B3A1A),
                    letterSpacing: 0.4,
                  ),
                ),
                _ScaleText(
                  label,
                  style: KvlText.title(
                    compact ? 20 : 24,
                    FontWeight.w600,
                  ).copyWith(color: const Color(0xFFB03A10), height: 1.05),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KnowAppButton extends StatelessWidget {
  const _KnowAppButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.xl, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: KvlRadius.brPill,
          color: Colors.black.withValues(alpha: .15),
          border: Border.all(color: Colors.white.withValues(alpha: .55), width: 1.2),
        ),
        child: Text(
          context.l10n.knowOurApp,
          textAlign: TextAlign.center,
          style: KvlText.body(15).copyWith(
            color: Colors.white,
            height: 1.1,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
