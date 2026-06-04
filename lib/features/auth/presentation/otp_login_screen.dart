import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
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
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(authRepositoryProvider).verifyOtp(
          mobile: _e164Mobile,
          otp: _otp,
        );
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
      title: 'Login',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.md),
          Text('Welcome back', textAlign: TextAlign.center, style: KvlText.title(17)),
          const SizedBox(height: 4),
          Text(
            'Enter the mobile number associated with your account.',
            textAlign: TextAlign.center,
            style: KvlText.caption(11.5),
          ),
          const SizedBox(height: KvlSpacing.lg),
          Row(
            children: [
              SizedBox(width: 78, child: KvlInput(label: 'Code', hint: '+91', readOnly: true)),
              const SizedBox(width: 8),
              Expanded(
                child: KvlInput(
                  label: 'Mobile',
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
            KvlButton(label: _busy ? 'Sending…' : 'Send OTP', onPressed: _busy ? null : _sendOtp)
          else ...[
            Text(
              'Enter the 6-digit code sent to your number.',
              textAlign: TextAlign.center,
              style: KvlText.caption(11.5),
            ),
            const SizedBox(height: KvlSpacing.md),
            PinCodeInput(onChanged: (v) => _otp = v, onCompleted: (_) => _login()),
            const SizedBox(height: KvlSpacing.sm),
            Center(
              child: _resendSeconds > 0
                  ? Text('Resend OTP in ${_resendSeconds}s', style: KvlText.caption(11))
                  : GestureDetector(
                      onTap: _sendOtp,
                      child: Text(
                        'Resend OTP',
                        style: KvlText.caption(11.5).copyWith(color: KvlColors.primaryDeep, fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
            const SizedBox(height: KvlSpacing.lg),
            KvlButton(label: _busy ? 'Verifying…' : 'Login', onPressed: _busy ? null : _login),
          ],
          if (_error != null) ...[
            const SizedBox(height: KvlSpacing.sm),
            Text(_error!,
                textAlign: TextAlign.center,
                style: KvlText.caption(11.5).copyWith(color: KvlColors.danger)),
          ],
          const SizedBox(height: KvlSpacing.lg),
          Center(
            child: GestureDetector(
              onTap: () => context.go(KvlRoute.createAccount),
              child: RichText(
                text: TextSpan(
                  style: KvlText.caption(11.5),
                  children: [
                    const TextSpan(text: "Don't have an account? "),
                    TextSpan(
                      text: 'Create one',
                      style: TextStyle(color: KvlColors.primaryDeep, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
