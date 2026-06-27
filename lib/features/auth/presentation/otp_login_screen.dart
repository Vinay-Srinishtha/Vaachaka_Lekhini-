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
// Password login screen — phone number + password.
// OTP is no longer used to sign in (only for password reset).
// ─────────────────────────────────────────────

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});
  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _mobileFocus = FocusNode();
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    _mobile.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _mobile.dispose();
    _password.dispose();
    _mobileFocus.dispose();
    super.dispose();
  }

  String get _digits => _mobile.text.replaceAll(RegExp(r'\D'), '');
  // 10-digit → prepend +91; 12-digit → already has country code
  String get _e164 => _digits.length == 12 ? '+$_digits' : '+91$_digits';
  bool get _mobileOk => _digits.length == 10 || _digits.length == 12;
  bool get _canSubmit => _mobileOk && _password.text.isNotEmpty;
  bool get _noAccount => _errorCode == 'account_not_found';
  bool get _accountBanned =>
      _errorCode == 'account_banned' || _errorCode == 'account_suspended';

  Future<void> _login() async {
    if (!_canSubmit) return;
    setState(() { _busy = true; _error = null; _errorCode = null; });

    final res = await ref.read(authRepositoryProvider).loginWithPassword(
          mobile: _e164,
          password: _password.text,
        );
    if (!mounted) return;
    switch (res) {
      case Ok(:final value):
        // Seed the primary member with the server UUID on a fresh device so the
        // local profile ID matches the server. User picks who practices next.
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
                userId: value.userId,
                name: value.username,
                relation: FamilyRelation.me);
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
      title: context.l10n.loginScreenTitle,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(context.l10n.welcomeBack,
              textAlign: TextAlign.center, style: KvlText.title(17)),
          const SizedBox(height: 4),
          Text(context.l10n.enterMobileAssociated,
              textAlign: TextAlign.center,
              style: KvlText.caption(12).copyWith(color: KvlColors.inkSoft)),
          const SizedBox(height: KvlSpacing.xl),

          // Mobile
          _MobileRow(
            controller: _mobile,
            focusNode: _mobileFocus,
            onSubmit: () => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: KvlSpacing.md),

          // Password
          KvlInput(
            label: 'Password',
            hint: 'Enter your password',
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) { if (_canSubmit) _login(); },
            suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18, color: KvlColors.inkSoft),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: KvlSpacing.sm),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.push(KvlRoute.forgotPassword),
              child: Text('Forgot password?',
                  style: KvlText.caption(12).copyWith(
                      color: KvlColors.primaryDeep, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: KvlSpacing.md),

          if (_noAccount) ...[
            _NoAccountCard(onCreateAccount: () => context.push(KvlRoute.createAccount)),
          ] else if (_accountBanned) ...[
            AuthBannedCard(suspended: _errorCode == 'account_suspended'),
          ] else ...[
            if (_error != null) ...[
              AuthErrorBar(_error!, onDismiss: () => setState(() { _error = null; _errorCode = null; })),
              const SizedBox(height: KvlSpacing.sm),
            ],
            KvlButton(
              label: _busy ? 'Logging in…' : context.l10n.loginConfirmButton,
              onPressed: (_busy || !_canSubmit) ? null : _login,
            ),
            const SizedBox(height: KvlSpacing.xl),
            _BottomLink(
              prefix: context.l10n.dontHaveAccount,
              link: context.l10n.createOneLink,
              onTap: () => context.push(KvlRoute.createAccount),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Private sub-widgets
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
    return KvlInput(
      label: 'Mobile',
      hint: 'Enter your mobile number',
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.phone,
      autofocus: true,
      inputFormatters: [AuthMobileFormatter()],
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => onSubmit?.call(),
    );
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
