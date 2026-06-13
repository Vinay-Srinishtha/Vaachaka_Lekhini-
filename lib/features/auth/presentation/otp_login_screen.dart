import 'dart:async';

import 'package:flutter/material.dart';
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

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});
  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  final _mobile = TextEditingController();
  final _mobileFocus = FocusNode();
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
    _mobile.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mobile.dispose();
    _mobileFocus.dispose();
    super.dispose();
  }

  String get _digits => _mobile.text.replaceAll(RegExp(r'\D'), '');
  String get _e164 => '+91$_digits';
  bool get _mobileOk => _digits.length == 10;
  bool get _noAccount => _errorCode == 'account_not_found';

  void _startCountdown() {
    _resendSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { if (--_resendSeconds <= 0) t.cancel(); });
    });
  }

  Future<void> _sendOtp() async {
    if (!_mobileOk) return;
    setState(() { _busy = true; _error = null; _errorCode = null; });

    // Pre-check: is this number registered?
    final check =
        await ref.read(authRepositoryProvider).checkMobileRegistered(_e164);
    if (!mounted) return;
    if (check case Err(:final failure)) {
      setState(() { _busy = false; _error = localizeAuthError(context, code: failure.code, fallback: failure.message); _errorCode = failure.code; });
      return;
    }
    if (check case Ok(:final value) when !value) {
      setState(() { _busy = false; _errorCode = 'account_not_found'; });
      return;
    }

    // Number exists — request OTP.
    final res = await ref.read(authRepositoryProvider).sendOtp(_e164);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (res) {
        case Ok():
          _otpSent = true;
          _otp = '';
          _startCountdown();
        case Err(:final failure):
          _error = localizeAuthError(context, code: failure.code, fallback: failure.message);
          _errorCode = failure.code;
      }
    });
  }

  Future<void> _resend() async {
    setState(() { _otp = ''; _error = null; _errorCode = null; });
    await _sendOtp();
  }

  Future<void> _verify() async {
    if (_otp.length != 6) { setState(() => _error = context.l10n.enterSixDigitCode); return; }
    setState(() { _busy = true; _error = null; _errorCode = null; });
    final res = await ref.read(authRepositoryProvider)
        .verifyOtp(mobile: _e164, otp: _otp);
    if (!mounted) return;
    switch (res) {
      case Ok(:final value):
        final pr = ref.read(profileRepositoryProvider);
        final list = await pr.listForUser(value.userId);
        if (list.isEmpty) {
          final me = await pr.create(
              userId: value.userId,
              name: value.username,
              relation: FamilyRelation.me);
          await pr.setActive(me.id);
        } else if (await pr.getActive() == null) {
          await pr.setActive(list.first.id);
        }
        if (!mounted) return;
        context.go(KvlRoute.home);
      case Err(:final failure):
        setState(() { _busy = false; _error = localizeAuthError(context, code: failure.code, fallback: failure.message); _errorCode = failure.code; });
    }
  }

  // ── Build ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: context.l10n.loginScreenTitle,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // Header
          Text(context.l10n.welcomeBack,
              textAlign: TextAlign.center, style: KvlText.title(17)),
          const SizedBox(height: 4),
          Text(context.l10n.enterMobileAssociated,
              textAlign: TextAlign.center,
              style: KvlText.caption(12).copyWith(color: KvlColors.inkSoft)),

          const SizedBox(height: KvlSpacing.xl),

          // Mobile row
          _MobileRow(
            controller: _mobile,
            focusNode: _mobileFocus,
            onSubmit: () { if (_mobileOk && !_otpSent) _sendOtp(); },
          ),

          const SizedBox(height: KvlSpacing.lg),

          // ── Step 1: not-found card OR send-OTP ──
          if (!_otpSent) ...[
            if (_noAccount) ...[
              _NoAccountCard(
                  onCreateAccount: () => context.push(KvlRoute.createAccount)),
            ] else ...[
              if (_error != null) ...[
                AuthErrorBar(_error!, onDismiss: () => setState(() { _error = null; _errorCode = null; })),
                const SizedBox(height: KvlSpacing.sm),
              ],
              KvlButton(
                label: _busy ? context.l10n.sendingButton : context.l10n.sendOtpButton,
                onPressed: (_busy || !_mobileOk) ? null : _sendOtp,
              ),
              const SizedBox(height: KvlSpacing.xl),
              _BottomLink(
                prefix: context.l10n.dontHaveAccount,
                link: context.l10n.createOneLink,
                onTap: () => context.push(KvlRoute.createAccount),
              ),
            ],
          ],

          // ── Step 2: OTP entry ──
          if (_otpSent) ...[
            _OtpSection(
              busy: _busy,
              resendSeconds: _resendSeconds,
              otp: _otp,
              error: _error,
              onChanged: (v) => setState(() => _otp = v),
              onCompleted: (_) => _verify(),
              onResend: _resend,
              onVerify: _verify,
              onDismissError: () => setState(() { _error = null; _errorCode = null; }),
              verifyLabel:
                  _busy ? context.l10n.verifyingButton : context.l10n.loginConfirmButton,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Private sub-widgets (login screen only)
// ─────────────────────────────────────────────

class _NoAccountCard extends StatelessWidget {
  const _NoAccountCard({required this.onCreateAccount});
  final VoidCallback onCreateAccount;

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
          Icon(Icons.person_off_outlined, size: 17, color: KvlColors.inkSoft),
          const SizedBox(width: 7),
          Text(context.l10n.numberNotRegistered,
              style: KvlText.ui(13).copyWith(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 5),
        Text(
          context.l10n.noAccountForNumber,
          style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft),
        ),
        const SizedBox(height: 13),
        KvlButton(
          label: context.l10n.createAnAccount,
          icon: Icons.arrow_forward_rounded,
          onPressed: onCreateAccount,
        ),
      ]),
    );
  }
}

class _MobileRow extends StatelessWidget {
  const _MobileRow({required this.controller, this.focusNode, this.onSubmit});
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 78,
        child: KvlInput(label: 'Code', hint: '+91', readOnly: true),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: KvlInput(
          label: 'Mobile',
          hint: '98765 43210',
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.phone,
          autofocus: true,
          inputFormatters: [AuthMobileFormatter()],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit?.call(),
        ),
      ),
    ]);
  }
}

class _OtpSection extends StatelessWidget {
  const _OtpSection({
    required this.busy,
    required this.resendSeconds,
    required this.otp,
    required this.error,
    required this.onChanged,
    required this.onCompleted,
    required this.onResend,
    required this.onVerify,
    required this.verifyLabel,
    this.onDismissError,
  });

  final bool busy;
  final int resendSeconds;
  final String otp;
  final String? error;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;
  final VoidCallback onResend;
  final VoidCallback onVerify;
  final String verifyLabel;
  final VoidCallback? onDismissError;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.sms_outlined, size: 14, color: KvlColors.inkSoft),
        const SizedBox(width: 5),
        Text(context.l10n.enterSixDigitCodeSent,
            style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft)),
      ]),
      const SizedBox(height: KvlSpacing.md),
      PinCodeInput(onChanged: onChanged, onCompleted: onCompleted),
      const SizedBox(height: KvlSpacing.sm),
      Center(
        child: resendSeconds > 0
            ? Text(context.l10n.resendCodeIn(resendSeconds),
                style: KvlText.caption(11).copyWith(color: KvlColors.inkSoft))
            : GestureDetector(
                onTap: busy ? null : onResend,
                child: Text(context.l10n.resendCode,
                    style: KvlText.caption(11.5).copyWith(
                        color: KvlColors.primaryDeep,
                        fontWeight: FontWeight.w600)),
              ),
      ),
      if (error != null) ...[
        const SizedBox(height: KvlSpacing.sm),
        AuthErrorBar(error!, onDismiss: onDismissError),
      ],
      const SizedBox(height: KvlSpacing.lg),
      KvlButton(
        label: verifyLabel,
        onPressed: (busy || otp.length != 6) ? null : onVerify,
      ),
    ]);
  }
}

class _BottomLink extends StatelessWidget {
  const _BottomLink({required this.prefix, required this.link, required this.onTap});
  final String prefix;
  final String link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            style: KvlText.caption(11.5),
            children: [
              TextSpan(text: prefix),
              TextSpan(
                  text: link,
                  style: TextStyle(
                      color: KvlColors.primaryDeep,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
