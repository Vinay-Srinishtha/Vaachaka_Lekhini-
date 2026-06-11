import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/storage/repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../profiles/domain/profile.dart';
import 'auth_shared_widgets.dart';

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _username = TextEditingController();
  final _mobile = TextEditingController();
  final _referral = TextEditingController();
  String _language = 'en';

  String _otp = '';
  bool _otpSent = false;
  bool _busy = false;
  String? _error;
  String? _errorCode;
  int _resendSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _username.addListener(() => setState(() {}));
    _mobile.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _username.dispose();
    _mobile.dispose();
    _referral.dispose();
    super.dispose();
  }

  String get _rawDigits => _mobile.text.replaceAll(RegExp(r'\D'), '');
  String get _e164Mobile => '+91$_rawDigits';
  bool get _mobileValid => _rawDigits.length == 10;
  bool get _nameValid => _username.text.trim().isNotEmpty;
  bool get _formValid => _nameValid && _mobileValid;
  bool get _accountExists => _errorCode == 'account_exists';

  void _startResendCountdown() {
    _resendSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) t.cancel();
      });
    });
  }

  Future<void> _sendOtp() async {
    if (!_nameValid) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    if (!_mobileValid) {
      setState(() => _error = 'Enter a valid 10-digit mobile number.');
      return;
    }
    setState(() { _busy = true; _error = null; _errorCode = null; });
    final result = await ref.read(authRepositoryProvider).sendOtp(_e164Mobile);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case Ok():
          _otpSent = true;
          _otp = '';
          _startResendCountdown();
        case Err(:final failure):
          _error = failure.message;
          _errorCode = failure.code;
      }
    });
  }

  Future<void> _resendOtp() async {
    setState(() { _otp = ''; _error = null; _errorCode = null; });
    await _sendOtp();
  }

  Future<void> _register() async {
    if (_otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() { _busy = true; _error = null; _errorCode = null; });
    final result = await ref.read(authRepositoryProvider).verifyOtp(
      mobile: _e164Mobile,
      otp: _otp,
      username: _username.text.trim(),
      referralCode: _referral.text.trim().isEmpty ? null : _referral.text.trim(),
      language: _language,
    );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        final profileRepo = ref.read(profileRepositoryProvider);
        final me = await profileRepo.create(
          userId: value.userId,
          name: value.username,
          relation: FamilyRelation.me,
        );
        await profileRepo.setActive(me.id);
        if (!mounted) return;
        context.go(KvlRoute.home);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
          _errorCode = failure.code;
        });
    }
  }

  // ── Build ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: context.l10n.createAccountTitle,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.md),
          Text(
            context.l10n.beginSpiritualJourney,
            textAlign: TextAlign.center,
            style: KvlText.title(18),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.quickSetup,
            textAlign: TextAlign.center,
            style: KvlText.caption(11.5),
          ),
          const SizedBox(height: KvlSpacing.lg),

          KvlCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name
                KvlInput(
                  label: context.l10n.usernameLabel,
                  hint: context.l10n.usernameHint,
                  controller: _username,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: KvlSpacing.md),

                // Mobile
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 78,
                    child: KvlInput(label: 'Code', hint: '+91', readOnly: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KvlInput(
                      label: context.l10n.mobileNumberLabel,
                      hint: context.l10n.mobileNumberHint,
                      controller: _mobile,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [AuthMobileFormatter()],
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ]),
                const SizedBox(height: KvlSpacing.md),

                // Referral
                KvlInput(
                  label: context.l10n.referralCodeLabel,
                  hint: context.l10n.referralCodeHint,
                  controller: _referral,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: KvlSpacing.md),

                // Language picker
                _LanguagePicker(
                  value: _language,
                  onChanged: (v) => setState(() => _language = v),
                ),
                const SizedBox(height: KvlSpacing.lg),

                // ── Step 1: Send OTP ──
                if (!_otpSent) ...[
                  if (_error != null) ...[
                    AuthErrorBar(_error!),
                    const SizedBox(height: KvlSpacing.sm),
                  ],
                  KvlButton(
                    label: _busy ? context.l10n.sendingButton : context.l10n.sendOtpButton,
                    onPressed: (_busy || !_formValid) ? null : _sendOtp,
                  ),
                ],

                // ── Step 2: OTP entry ──
                if (_otpSent) ...[
                  // account_exists card replaces the OTP UI
                  if (_accountExists) ...[
                    _AccountExistsCard(
                        onLogin: () => context.go(KvlRoute.otpLogin)),
                  ] else ...[
                    Text(
                      context.l10n.enterSixDigitCodeSent,
                      style: KvlText.caption(11.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: KvlSpacing.sm),
                    PinCodeInput(
                      onChanged: (v) => setState(() => _otp = v),
                      onCompleted: (_) => _register(),
                    ),
                    const SizedBox(height: KvlSpacing.sm),
                    Center(
                      child: _resendSeconds > 0
                          ? Text(
                              context.l10n.resendOtpCountdown(_resendSeconds),
                              style: KvlText.caption(11)
                                  .copyWith(color: KvlColors.inkSoft),
                            )
                          : GestureDetector(
                              onTap: _busy ? null : _resendOtp,
                              child: Text(
                                context.l10n.resendOtp,
                                style: KvlText.caption(11.5).copyWith(
                                  color: KvlColors.primaryDeep,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: KvlSpacing.sm),
                      AuthErrorBar(_error!),
                    ],
                    const SizedBox(height: KvlSpacing.lg),
                    KvlButton(
                      label: _busy
                          ? context.l10n.verifyingButton
                          : context.l10n.registerConfirmButton,
                      onPressed: (_busy || _otp.length != 6) ? null : _register,
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Bottom "Already have an account?" — hidden when account_exists card shows
          if (!_accountExists) ...[
            const SizedBox(height: KvlSpacing.lg),
            Center(
              child: GestureDetector(
                onTap: () => context.push(KvlRoute.otpLogin),
                child: RichText(
                  text: TextSpan(
                    style: KvlText.caption(11.5),
                    children: [
                      TextSpan(text: context.l10n.alreadyHaveAccount),
                      TextSpan(
                        text: context.l10n.loginLink,
                        style: TextStyle(
                          color: KvlColors.primaryDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Private sub-widgets (create account screen only)
// ─────────────────────────────────────────────

/// Shown when verifyOtp returns account_exists.
class _AccountExistsCard extends StatelessWidget {
  const _AccountExistsCard({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: KvlColors.surfaceWarm,
        borderRadius: KvlRadius.brMD,
        border: Border.all(color: KvlColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.person_outline_rounded, size: 17, color: KvlColors.inkSoft),
          const SizedBox(width: 7),
          Text('Number already registered',
              style: KvlText.ui(13).copyWith(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 5),
        Text(
          'An account already exists for this number.',
          style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft),
        ),
        const SizedBox(height: 13),
        KvlButton(
          label: 'Log in instead',
          icon: Icons.arrow_forward_rounded,
          onPressed: onLogin,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// Language picker
// ─────────────────────────────────────────────

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('en', 'English'),
    ('hi', 'हिन्दी (Hindi)'),
    ('te', 'తెలుగు (Telugu)'),
    ('kn', 'ಕನ್ನಡ (Kannada)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.selectLanguage,
          style: KvlText.caption(11.5).copyWith(
            color: KvlColors.inkSoft,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: KvlColors.surface,
            borderRadius: KvlRadius.brMD,
            border: Border.all(color: KvlColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              borderRadius: KvlRadius.brMD,
              items: [
                for (final (code, label) in _options)
                  DropdownMenuItem(
                    value: code,
                    child: Text(label, style: KvlText.ui(13)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ),
      ],
    );
  }
}
