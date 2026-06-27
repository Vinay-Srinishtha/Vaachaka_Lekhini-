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
// Forgot-password flow: phone → SMS code → new password → signed in.
// The reset code is valid for 9 minutes; a new one can only be requested
// 2 hours after the previous expires (enforced server-side).
// ─────────────────────────────────────────────

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String _otp = '';
  bool _codeSent = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    _mobile.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
    _confirm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _mobile.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String get _digits => _mobile.text.replaceAll(RegExp(r'\D'), '');
  String get _e164 => _digits.length == 12 ? '+$_digits' : '+91$_digits';
  bool get _mobileOk => _digits.length == 10 || _digits.length == 12;
  bool get _passwordValid => _password.text.length >= 8;
  bool get _confirmValid => _confirm.text == _password.text;
  bool get _resetValid => _otp.length == 6 && _passwordValid && _confirmValid;
  bool get _noAccount => _errorCode == 'account_not_found';
  bool get _cooldown => _errorCode == 'reset_cooldown';
  bool get _accountBanned =>
      _errorCode == 'account_banned' || _errorCode == 'account_suspended';

  Future<void> _sendCode() async {
    if (!_mobileOk) return;
    setState(() { _busy = true; _error = null; _errorCode = null; });
    final res = await ref.read(authRepositoryProvider).requestPasswordReset(_e164);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (res) {
        case Ok():
          _codeSent = true;
          _otp = '';
        case Err(:final failure):
          _error = isAccountLevelError(failure.code)
              ? null
              : localizeAuthError(context, code: failure.code, fallback: failure.message);
          _errorCode = failure.code;
      }
    });
  }

  Future<void> _reset() async {
    if (!_resetValid) {
      setState(() => _error = !_passwordValid
          ? 'Password must be at least 8 characters.'
          : (!_confirmValid ? 'Passwords do not match.' : context.l10n.enterSixDigitCode));
      return;
    }
    setState(() { _busy = true; _error = null; _errorCode = null; });
    final res = await ref.read(authRepositoryProvider).resetPassword(
          mobile: _e164,
          otp: _otp,
          newPassword: _password.text,
        );
    if (!mounted) return;
    switch (res) {
      case Ok(:final value):
        final pr = ref.read(profileRepositoryProvider);
        final list = await pr.listForUser(value.userId);
        if (list.isEmpty) {
          final serverId = value.primaryMemberId;
          if (serverId != null) {
            await pr.upsertRemote(Profile(
              id: serverId,
              userId: value.userId,
              name: value.username,
              relation: FamilyRelation.me,
              language: value.language,
              createdAt: value.createdAt,
            ));
          } else {
            await pr.create(
                userId: value.userId, name: value.username, relation: FamilyRelation.me);
          }
        }
        if (!mounted) return;
        context.go(KvlRoute.profileSelect);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = isAccountLevelError(failure.code)
              ? null
              : localizeAuthError(context, code: failure.code, fallback: failure.message);
          _errorCode = failure.code;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: 'Reset Password',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text('Forgot your password?',
              textAlign: TextAlign.center, style: KvlText.title(17)),
          const SizedBox(height: 4),
          Text(
            _codeSent
                ? 'Enter the code sent to your number and choose a new password.'
                : 'Enter your registered mobile number. We will send you a one-time code.',
            textAlign: TextAlign.center,
            style: KvlText.caption(12).copyWith(color: KvlColors.inkSoft),
          ),
          const SizedBox(height: KvlSpacing.xl),

          // Mobile
          KvlInput(
            label: 'Mobile',
            hint: 'Enter your mobile number',
            controller: _mobile,
            keyboardType: TextInputType.phone,
            autofocus: true,
            readOnly: _codeSent,
            inputFormatters: [AuthMobileFormatter()],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) { if (!_codeSent && _mobileOk) _sendCode(); },
          ),
          const SizedBox(height: KvlSpacing.lg),

          if (_noAccount) ...[
            _NoAccountCard(onCreateAccount: () => context.go(KvlRoute.createAccount)),
          ] else if (_accountBanned) ...[
            AuthBannedCard(suspended: _errorCode == 'account_suspended'),
          ] else if (!_codeSent) ...[
            if (_cooldown && _error == null) ...[
              AuthErrorBar(
                  'For your security, a new reset code can only be requested 2 hours after the last one. Please try again later.'),
              const SizedBox(height: KvlSpacing.sm),
            ],
            if (_error != null) ...[
              AuthErrorBar(_error!, onDismiss: () => setState(() { _error = null; _errorCode = null; })),
              const SizedBox(height: KvlSpacing.sm),
            ],
            KvlButton(
              label: _busy ? context.l10n.sendingButton : 'Send Code',
              onPressed: (_busy || !_mobileOk) ? null : _sendCode,
            ),
          ] else ...[
            // Code + new password
            Text('Enter the 6-digit code',
                textAlign: TextAlign.center,
                style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft)),
            const SizedBox(height: KvlSpacing.sm),
            PinCodeInput(onChanged: (v) => setState(() => _otp = v)),
            const SizedBox(height: KvlSpacing.sm),
            Center(
              child: GestureDetector(
                onTap: _busy ? null : _sendCode,
                child: Text('Resend code',
                    style: KvlText.caption(11.5).copyWith(
                        color: KvlColors.primaryDeep, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: KvlSpacing.md),
            KvlInput(
              label: 'New password',
              hint: 'At least 8 characters',
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    size: 18, color: KvlColors.inkSoft),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: KvlSpacing.md),
            KvlInput(
              label: 'Confirm new password',
              hint: 'Re-enter your password',
              controller: _confirm,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
            ),
            if (_confirm.text.isNotEmpty && !_confirmValid) ...[
              const SizedBox(height: 4),
              Text('Passwords do not match.',
                  style: KvlText.caption(11).copyWith(color: KvlColors.danger)),
            ],
            if (_error != null) ...[
              const SizedBox(height: KvlSpacing.sm),
              AuthErrorBar(_error!, onDismiss: () => setState(() { _error = null; _errorCode = null; })),
            ],
            const SizedBox(height: KvlSpacing.lg),
            KvlButton(
              label: _busy ? 'Resetting…' : 'Reset Password & Sign In',
              onPressed: (_busy || !_resetValid) ? null : _reset,
            ),
          ],
        ],
      ),
    );
  }
}

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
        Text(context.l10n.noAccountForNumber,
            style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft)),
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
