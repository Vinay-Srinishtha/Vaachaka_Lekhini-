import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/theme.dart';

/// Welcome splash — orange gradient background, brand mark in Devanagari +
/// Lexend, "Continue to App" pill. Matches mockup 1.1.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: KvlColors.welcomeGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(KvlSpacing.xl, KvlSpacing.huge, KvlSpacing.xl, KvlSpacing.xxl),
            child: Column(
              children: [
                const Spacer(flex: 2),
                _Logo(),
                const SizedBox(height: KvlSpacing.xl),
                Text(
                  'कोटि वाचिक लेखिनी',
                  textAlign: TextAlign.center,
                  style: KvlText.mantraDevanagari(26).copyWith(color: Colors.white),
                ),
                const SizedBox(height: KvlSpacing.xs),
                Text(
                  'Koti Vachika Lekhini',
                  style: KvlText.title(18).copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: KvlSpacing.md),
                Text(
                  'Your Personal Spiritual Practice Companion',
                  textAlign: TextAlign.center,
                  style: KvlText.body(12).copyWith(color: Colors.white.withValues(alpha: .92)),
                ),
                const SizedBox(height: KvlSpacing.md),
                Text(
                  "Write God's Name with AI\nChant with Purpose · Track with Pride",
                  textAlign: TextAlign.center,
                  style: KvlText.body(11).copyWith(color: Colors.white.withValues(alpha: .85), height: 1.6),
                ),
                const Spacer(flex: 3),
                _ContinueButton(onTap: () => context.go(KvlRoute.profileSelect)),
                const SizedBox(height: KvlSpacing.lg),
                Text(
                  'Know our App',
                  style: KvlText.caption(11.5).copyWith(
                    color: Colors.white.withValues(alpha: .85),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .14),
        border: Border.all(color: Colors.white.withValues(alpha: .3)),
      ),
      alignment: Alignment.center,
      child: Text(
        'ॐ',
        style: KvlText.mantraDevanagari(64).copyWith(color: Colors.white),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: KvlRadius.brPill,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: .2),
      child: InkWell(
        onTap: onTap,
        borderRadius: KvlRadius.brPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.xxl, vertical: KvlSpacing.md),
          child: Text(
            'Continue to App',
            style: KvlText.ui(14, FontWeight.w600).copyWith(color: KvlColors.primaryDeep),
          ),
        ),
      ),
    );
  }
}
