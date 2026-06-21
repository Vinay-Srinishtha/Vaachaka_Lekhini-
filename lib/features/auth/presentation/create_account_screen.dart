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
// Password-only signup — name + mobile + password (no OTP).
// ─────────────────────────────────────────────

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _username = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _referral = TextEditingController();
  final String _language = 'en';

  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    _username.addListener(() => setState(() {}));
    _mobile.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
    _confirm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _username.dispose();
    _mobile.dispose();
    _password.dispose();
    _confirm.dispose();
    _referral.dispose();
    super.dispose();
  }

  String get _rawDigits => _mobile.text.replaceAll(RegExp(r'\D'), '');
  String get _e164Mobile => '+91$_rawDigits';
  bool get _mobileValid => _rawDigits.length == 10;
  bool get _nameValid => _username.text.trim().isNotEmpty;
  bool get _passwordValid => _password.text.length >= 8;
  bool get _confirmValid => _confirm.text == _password.text;
  bool get _formValid => _nameValid && _mobileValid && _passwordValid && _confirmValid;
  bool get _accountExists => _errorCode == 'account_exists';
  bool get _accountBanned =>
      _errorCode == 'account_banned' || _errorCode == 'account_suspended';

  Future<void> _register() async {
    if (!_nameValid) {
      setState(() => _error = context.l10n.authErrorEnterName);
      return;
    }
    if (!_mobileValid) {
      setState(() => _error = context.l10n.authErrorEnterMobileValid);
      return;
    }
    if (!_passwordValid) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (!_confirmValid) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() { _busy = true; _error = null; _errorCode = null; });

    final result = await ref.read(authRepositoryProvider).register(
          mobile: _e164Mobile,
          username: _username.text.trim(),
          password: _password.text,
          referralCode: _referral.text.trim().isEmpty ? null : _referral.text.trim(),
          language: _language,
        );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        final profileRepo = ref.read(profileRepositoryProvider);
        final serverId = value.primaryMemberId;
        if (serverId != null) {
          await profileRepo.upsertRemote(Profile(
            id: serverId,
            userId: value.userId,
            name: value.username,
            relation: FamilyRelation.me,
            language: value.language,
            createdAt: value.createdAt,
          ));
        } else {
          await profileRepo.create(
            userId: value.userId,
            name: value.username,
            relation: FamilyRelation.me,
          );
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
      title: context.l10n.createAccountTitle,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.md),
          Text(context.l10n.beginSpiritualJourney,
              textAlign: TextAlign.center, style: KvlText.title(18)),
          const SizedBox(height: 4),
          Text(context.l10n.quickSetup,
              textAlign: TextAlign.center, style: KvlText.caption(11.5)),
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
                      // Clear account-exists error when number changes.
                      onChanged: (_) {
                        if (_accountExists || _accountBanned) {
                          setState(() { _error = null; _errorCode = null; });
                        }
                      },
                    ),
                  ),
                ]),

                // Inline error: number already registered → divert to login, block further fields.
                if (_accountExists) ...[
                  const SizedBox(height: KvlSpacing.sm),
                  _NumberExistsInline(onLogin: () => context.go(KvlRoute.otpLogin)),
                ] else if (_accountBanned) ...[
                  const SizedBox(height: KvlSpacing.sm),
                  AuthBannedCard(suspended: _errorCode == 'account_suspended'),
                ],

                // Password, confirm, referral, submit — only after a valid 10-digit number
                // and only when the number is not already taken.
                if (_mobileValid && !_accountExists && !_accountBanned) ...[
                  const SizedBox(height: KvlSpacing.md),
                  KvlInput(
                    label: 'Password',
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
                    label: 'Confirm password',
                    hint: 'Re-enter your password',
                    controller: _confirm,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                  ),
                  if (_confirm.text.isNotEmpty && !_confirmValid) ...[
                    const SizedBox(height: 4),
                    Text('Passwords do not match.',
                        style: KvlText.caption(11).copyWith(color: KvlColors.danger)),
                  ],
                  const SizedBox(height: KvlSpacing.md),
                  KvlInput(
                    label: context.l10n.referralCodeLabel,
                    hint: context.l10n.referralCodeHint,
                    controller: _referral,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: KvlSpacing.lg),
                  if (_error != null) ...[
                    AuthErrorBar(_error!, onDismiss: () => setState(() { _error = null; _errorCode = null; })),
                    const SizedBox(height: KvlSpacing.sm),
                  ],
                  KvlButton(
                    label: _busy ? 'Creating account…' : context.l10n.registerConfirmButton,
                    onPressed: (_busy || !_formValid) ? null : _register,
                  ),
                ],
              ],
            ),
          ),

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
                            color: KvlColors.primaryDeep, fontWeight: FontWeight.w600),
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

// Compact inline error shown directly under the phone field when the number
// is already registered. Blocks the password fields entirely.
class _NumberExistsInline extends StatelessWidget {
  const _NumberExistsInline({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KvlColors.danger.withValues(alpha: .07),
        borderRadius: KvlRadius.brMD,
        border: Border.all(color: KvlColors.danger.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: KvlColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.numberAlreadyRegistered,
              style: KvlText.caption(12).copyWith(color: KvlColors.danger),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onLogin,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: KvlColors.primary,
                borderRadius: KvlRadius.brSM,
              ),
              child: Text(
                context.l10n.logInInstead,
                style: KvlText.ui(11, FontWeight.w700).copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
