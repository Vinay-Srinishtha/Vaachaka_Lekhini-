import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/storage/repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../profiles/domain/profile.dart';

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

  @override
  void dispose() {
    _username.dispose();
    _mobile.dispose();
    _referral.dispose();
    super.dispose();
  }

  String get _e164Mobile {
    final digits = _mobile.text.replaceAll(RegExp(r'\D'), '');
    return '+91$digits';
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
        case Err(:final failure):
          _error = failure.message;
      }
    });
  }

  Future<void> _register() async {
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
          username: _username.text,
          referralCode: _referral.text,
          language: _language,
        );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        // Auto-create a "Me" profile so the user lands on Home with a counter scope.
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
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: 'Create Account',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.md),
          Text(
            'Begin your spiritual journey',
            textAlign: TextAlign.center,
            style: KvlText.title(18),
          ),
          const SizedBox(height: 4),
          Text(
            'Quick setup · takes 30 seconds',
            textAlign: TextAlign.center,
            style: KvlText.caption(11.5),
          ),
          const SizedBox(height: KvlSpacing.lg),
          KvlCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KvlInput(
                  label: 'Username',
                  hint: 'Enter your name',
                  controller: _username,
                ),
                const SizedBox(height: KvlSpacing.md),
                Row(
                  children: [
                    SizedBox(
                      width: 78,
                      child: KvlInput(label: 'Code', hint: '+91', readOnly: true),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: KvlInput(
                        label: 'Mobile Number',
                        hint: '98765 43210',
                        controller: _mobile,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KvlSpacing.md),
                KvlInput(
                  label: 'Referral Code (Optional)',
                  hint: 'Enter referral code',
                  controller: _referral,
                ),
                const SizedBox(height: KvlSpacing.md),
                _LanguagePicker(value: _language, onChanged: (v) => setState(() => _language = v)),
                const SizedBox(height: KvlSpacing.lg),
                if (!_otpSent)
                  KvlButton(label: _busy ? 'Sending…' : 'Send OTP', onPressed: _busy ? null : _sendOtp)
                else ...[
                  Text('Enter the 6-digit code', style: KvlText.caption(11.5), textAlign: TextAlign.center),
                  const SizedBox(height: KvlSpacing.sm),
                  PinCodeInput(onChanged: (v) => _otp = v, onCompleted: (_) => _register()),
                  const SizedBox(height: KvlSpacing.lg),
                  KvlButton(label: _busy ? 'Verifying…' : 'Register', onPressed: _busy ? null : _register),
                ],
                if (_error != null) ...[
                  const SizedBox(height: KvlSpacing.sm),
                  Text(_error!, style: KvlText.caption(11.5).copyWith(color: KvlColors.danger), textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
          const SizedBox(height: KvlSpacing.lg),
          Center(
            child: GestureDetector(
              onTap: () => context.go(KvlRoute.otpLogin),
              child: RichText(
                text: TextSpan(
                  style: KvlText.caption(11.5),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Login',
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
        Text('Select Language', style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft, fontWeight: FontWeight.w500)),
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
                  DropdownMenuItem(value: code, child: Text(label, style: KvlText.ui(13))),
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
