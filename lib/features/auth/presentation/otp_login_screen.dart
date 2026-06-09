import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../l10n/l10n.dart';
import '../../../app/router.dart';
import '../../../core/storage/repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../profiles/domain/profile.dart';

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  final _mobile = TextEditingController();
  String _otp = '';
  bool _otpSent = false;
  bool _busy = false;
  String? _error;
  int _resendSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _mobile.dispose();
    super.dispose();
  }

  String get _e164Mobile {
    final digits = _mobile.text.replaceAll(RegExp(r'\D'), '');
    return '+91$digits';
  }

  void _startResendCountdown() {
    _resendSeconds = 25;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) t.cancel();
      });
    });
  }

  Future<void> _sendOtp() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(authRepositoryProvider).sendOtp(_e164Mobile);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case Ok():
          _otpSent = true;
          _startResendCountdown();
        case Err(:final failure):
          _error = failure.message;
      }
    });
  }

  Future<void> _login() async {
    if (_otp.length != 6) {
      setState(() => _error = context.l10n.enterSixDigitCode);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .verifyOtp(mobile: _e164Mobile, otp: _otp);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        // Returning user — ensure they have at least one profile.
        final profileRepo = ref.read(profileRepositoryProvider);
        final list = await profileRepo.listForUser(value.userId);
        if (list.isEmpty) {
          final me = await profileRepo.create(
            userId: value.userId,
            name: value.username,
            relation: FamilyRelation.me,
          );
          await profileRepo.setActive(me.id);
        } else if ((await profileRepo.getActive()) == null) {
          await profileRepo.setActive(list.first.id);
        }
        if (!mounted) return;
        context.go(KvlRoute.home);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: context.l10n.loginScreenTitle,
      scrollable: true,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: KvlSpacing.md),
            Text(
              context.l10n.welcomeBack,
              textAlign: TextAlign.center,
              style: KvlText.title(17),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.enterMobileAssociated,
              textAlign: TextAlign.center,
              style: KvlText.caption(11.5),
            ),
            const SizedBox(height: KvlSpacing.lg),
            Row(
              children: [
                SizedBox(
                  width: 78,
                  child: KvlInput(label: 'Code', hint: '+91', readOnly: true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KvlInput(
                    label: context.l10n.mobileLabel,
                    hint: '98765 43210',
                    controller: _mobile,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KvlSpacing.lg),
            if (!_otpSent)
              KvlButton(
                label: _busy
                    ? context.l10n.sendingButton
                    : context.l10n.sendOtpButton,
                onPressed: _busy ? null : _sendOtp,
              )
            else ...[
              Text(
                context.l10n.enterSixDigitCodeSent,
                textAlign: TextAlign.center,
                style: KvlText.caption(11.5),
              ),
              const SizedBox(height: KvlSpacing.md),
              PinCodeInput(
                onChanged: (v) => _otp = v,
                onCompleted: (_) => _login(),
              ),
              const SizedBox(height: KvlSpacing.sm),
              Center(
                child: _resendSeconds > 0
                    ? Text(
                        context.l10n.resendOtpCountdown(_resendSeconds),
                        style: KvlText.caption(11),
                      )
                    : GestureDetector(
                        onTap: _sendOtp,
                        child: Text(
                          context.l10n.resendOtp,
                          style: KvlText.caption(11.5).copyWith(
                            color: KvlColors.primaryDeep,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: KvlSpacing.lg),
              KvlButton(
                label: _busy
                    ? context.l10n.verifyingButton
                    : context.l10n.loginConfirmButton,
                onPressed: _busy ? null : _login,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: KvlSpacing.sm),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: KvlText.caption(11.5).copyWith(color: KvlColors.danger),
              ),
            ],
            const SizedBox(height: KvlSpacing.lg),
            Center(
              child: GestureDetector(
                onTap: () => context.push(KvlRoute.createAccount),
                child: RichText(
                  text: TextSpan(
                    style: KvlText.caption(11.5),
                    children: [
                      TextSpan(text: context.l10n.dontHaveAccount),
                      TextSpan(
                        text: context.l10n.createOneLink,
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
        ),
      ),
    );
  }
}
