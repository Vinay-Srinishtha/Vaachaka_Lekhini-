import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/theme/theme.dart';
import '../../settings/domain/settings_repository.dart';

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
                        'Vaachaka Lekhini',
                        style: KvlText.mantraDevanagari(
                          veryCompact ? 32 : 42,
                        ).copyWith(color: Colors.white, height: 1.05),
                      ),
                      const SizedBox(height: 8),
                      _ScaleText(
                        'Your Personal Spiritual Practice Companion',
                        style: KvlText.body(
                          veryCompact ? 14 : 17,
                        ).copyWith(color: Colors.white, height: 1.15),
                      ),
                      SizedBox(height: veryCompact ? 10 : 16),
                      _ScaleText(
                        'Chant with Purpose | Track with Pride',
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
          'Set Language',
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
        borderRadius: BorderRadius.circular(size * .28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9F9F9), Color(0xFFBFC1C4)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const CustomPaint(painter: _AppMarkPainter()),
    );
  }
}

class _AppMarkPainter extends CustomPainter {
  const _AppMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final navy = Paint()
      ..color = const Color(0xFF27205F)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final orange = Paint()
      ..color = KvlColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final face = Path()
      ..moveTo(size.width * .30, size.height * .30)
      ..cubicTo(
        size.width * .30,
        size.height * .45,
        size.width * .48,
        size.height * .48,
        size.width * .38,
        size.height * .58,
      )
      ..cubicTo(
        size.width * .31,
        size.height * .65,
        size.width * .21,
        size.height * .64,
        size.width * .14,
        size.height * .57,
      );
    canvas.drawPath(face, navy);
    canvas.drawCircle(
      Offset(size.width * .31, size.height * .27),
      2.3,
      Paint()..color = KvlColors.primary,
    );

    for (final x in [.45, .52, .59]) {
      canvas.drawLine(
        Offset(size.width * x, size.height * .50),
        Offset(size.width * x, size.height * (.62 - (x - .45))),
        orange,
      );
    }

    final slate = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .66,
        size.height * .39,
        size.width * .22,
        size.height * .35,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(slate, navy);
    final pen = Path()
      ..moveTo(size.width * .74, size.height * .62)
      ..lineTo(size.width * .87, size.height * .76)
      ..lineTo(size.width * .76, size.height * .70)
      ..close();
    canvas.drawPath(pen, navy);

    final textPaint = Paint()
      ..color = KvlColors.primary
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (.45 + i * .055);
      canvas.drawLine(
        Offset(size.width * .70, y),
        Offset(size.width * .84, y),
        textPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
            eyebrow: 'Existing user?',
            label: 'Login',
            compact: compact,
            onTap: onLogin,
          ),
        ),
        SizedBox(width: compact ? KvlSpacing.md : KvlSpacing.xl),
        Expanded(
          child: _AuthButton(
            eyebrow: 'New user?',
            label: 'Register',
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
        'Know our App',
        textAlign: TextAlign.center,
        style: KvlText.body(16).copyWith(color: Colors.white, height: 1.1),
      ),
    );
  }
}
