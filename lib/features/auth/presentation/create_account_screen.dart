import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/storage/repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../profiles/domain/member_address.dart';
import '../../profiles/domain/profile.dart';
import '../../tnc/presentation/tnc_sheet.dart';
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
  String? _selectedState;

  bool _busy = false;
  bool _checkingMobile = false;
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
  String get _e164Mobile => _rawDigits.length == 12 ? '+$_rawDigits' : '+91$_rawDigits';
  bool get _mobileValid => _rawDigits.length == 10 || _rawDigits.length == 12;
  bool get _nameValid => _username.text.trim().isNotEmpty;
  bool get _passwordValid => _password.text.length >= 8;
  bool get _confirmValid => _confirm.text == _password.text;
  bool get _formValid => _nameValid && _mobileValid && _passwordValid && _confirmValid && _selectedState != null;
  bool get _accountExists => _errorCode == 'account_exists';
  bool get _accountBanned =>
      _errorCode == 'account_banned' || _errorCode == 'account_suspended';

  // Called as soon as the user types a valid 10-digit number.
  // Blocks the password section until we know the number is free.
  Future<void> _checkMobile() async {
    if (!_mobileValid) return;
    setState(() { _checkingMobile = true; _error = null; _errorCode = null; });
    final result = await ref.read(authRepositoryProvider).checkMobileRegistered(_e164Mobile);
    if (!mounted) return;
    setState(() {
      _checkingMobile = false;
      if (result case Ok(:final value) when value) {
        _errorCode = 'account_exists';
      }
    });
  }

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
    // Show T&C if there is an active version — registration requires acceptance.
    // If the fetch fails, skip the T&C step so registration isn't blocked.
    try {
      final tnc = await ref.read(tncRepositoryProvider).fetchCurrent();
      if (!mounted) return;
      if (tnc != null) {
        final accepted = await showTncSheet(context, tnc);
        if (!mounted) return;
        if (!accepted) return; // user dismissed without accepting
      }
    } catch (_) {
      if (!mounted) return;
      // T&C fetch failed — continue without it.
    }

    setState(() { _busy = true; _error = null; _errorCode = null; });

    // Guard: re-verify the number hasn't been registered between the check and submit.
    final checkResult = await ref.read(authRepositoryProvider).checkMobileRegistered(_e164Mobile);
    if (!mounted) return;
    if (checkResult case Ok(:final value) when value) {
      setState(() { _busy = false; _errorCode = 'account_exists'; });
      return;
    }

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
        final stateAddr = _selectedState != null
            ? [
                MemberAddress(
                  id: const Uuid().v4(),
                  type: AddressType.home,
                  line1: '',
                  state: _selectedState!,
                  city: _selectedState!,
                  pincode: '',
                )
              ]
            : const <MemberAddress>[];
        if (serverId != null) {
          await profileRepo.upsertRemote(Profile(
            id: serverId,
            userId: value.userId,
            name: value.username,
            relation: FamilyRelation.me,
            language: value.language,
            createdAt: value.createdAt,
            addresses: stateAddr,
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
                KvlInput(
                  label: context.l10n.mobileNumberLabel,
                  hint: context.l10n.mobileNumberHint,
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [AuthMobileFormatter()],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    // Always clear previous result when number changes.
                    if (_errorCode != null) {
                      setState(() { _error = null; _errorCode = null; });
                    }
                    // Check availability as soon as 10 digits are complete.
                    if (_mobileValid) _checkMobile();
                  },
                ),

                // Proactive check feedback — shown while verifying availability.
                if (_checkingMobile) ...[
                  const SizedBox(height: KvlSpacing.sm),
                  Row(children: [
                    SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: KvlColors.primaryDeep),
                    ),
                    const SizedBox(width: 8),
                    Text('Checking number…',
                        style: KvlText.caption(12).copyWith(color: KvlColors.inkSoft)),
                  ]),
                ],

                // Inline error: number already registered → divert to login, block further fields.
                if (!_checkingMobile && _accountExists) ...[
                  const SizedBox(height: KvlSpacing.sm),
                  _NumberExistsInline(onLogin: () => context.go(KvlRoute.otpLogin)),
                ] else if (!_checkingMobile && _accountBanned) ...[
                  const SizedBox(height: KvlSpacing.sm),
                  AuthBannedCard(suspended: _errorCode == 'account_suspended'),
                ],

                // Password, confirm, referral, submit — only after a valid 10-digit number,
                // availability confirmed, and not already taken.
                if (_mobileValid && !_checkingMobile && !_accountExists && !_accountBanned) ...[
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
                  const SizedBox(height: KvlSpacing.md),

                  // State dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('State',
                          style: KvlText.caption(12)
                              .copyWith(color: KvlColors.inkSoft)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedState,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select your state',
                          hintStyle: KvlText.body(13.5)
                              .copyWith(color: KvlColors.muted),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: KvlColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: KvlColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: KvlColors.primaryDeep, width: 1.5),
                          ),
                          filled: true,
                          fillColor: KvlColors.surface,
                        ),
                        items: kIndianStates
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s,
                                      style: KvlText.body(13.5)),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedState = v),
                      ),
                    ],
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
