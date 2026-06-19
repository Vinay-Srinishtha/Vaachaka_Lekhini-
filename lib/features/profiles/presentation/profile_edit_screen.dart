import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/profile.dart';

/// Full-screen profile editor. Lets the user fill in Gender, Age (birth year),
/// and Mother Tongue.
///
/// On first save when all required fields are filled, calls
/// POST /api/v1/me/complete-profile which awards 50 reward points (once only).
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _birthYearCtrl;
  late final TextEditingController _locationCtrl;

  Gender? _gender;
  String? _motherTongue;
  bool _busy = false;
  String? _error;
  bool _rewardEarned = false;

  static const _motherTongues = [
    ('hi', 'Hindi'),
    ('te', 'Telugu'),
    ('kn', 'Kannada'),
    ('ta', 'Tamil'),
    ('mr', 'Marathi'),
    ('gu', 'Gujarati'),
    ('bn', 'Bengali'),
    ('ml', 'Malayalam'),
    ('pa', 'Punjabi'),
    ('or', 'Odia'),
    ('en', 'English'),
    ('sa', 'Sanskrit'),
    ('other', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(activeProfileProvider).value;
    _nameCtrl = TextEditingController(text: profile?.name ?? '');
    _birthYearCtrl = TextEditingController(
      text: profile?.birthYear != null ? '${profile!.birthYear}' : '',
    );
    _locationCtrl = TextEditingController(text: profile?.location ?? '');
    _gender = profile?.gender;
    _motherTongue = profile?.motherTongue;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthYearCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  bool get _isComplete {
    final name = _nameCtrl.text.trim();
    final year = int.tryParse(_birthYearCtrl.text.trim());
    return name.isNotEmpty && _gender != null && year != null && _motherTongue != null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _busy = true; _error = null; _rewardEarned = false; });

    try {
      final profile = ref.read(activeProfileProvider).value;
      if (profile == null) throw Exception('No active profile');

      final name = _nameCtrl.text.trim();
      final birthYear = int.tryParse(_birthYearCtrl.text.trim());

      final location = _locationCtrl.text.trim();
      final updated = profile.copyWith(
        name: name,
        gender: _gender,
        birthYear: birthYear,
        motherTongue: _motherTongue,
        location: location.isNotEmpty ? location : null,
      );

      await ref.read(profileRepositoryProvider).update(updated);

      // If profile is now complete and hasn't been rewarded yet, call the
      // server endpoint to earn the one-time 50-point bonus.
      if (updated.isProfileComplete && profile.profileCompletedAt == null) {
        final api = ref.read(apiClientProvider);
        final resp = await api.dio.post<Map<String, dynamic>>(
          '/api/v1/me/complete-profile',
          data: {
            'member_id': profile.id,
            'gender': _gender?.serverValue,
            'birth_year': birthYear,
            'mother_tongue': _motherTongue,
          },
        );
        final body = resp.data;
        if (body != null && body['rewarded'] == true) {
          // Mark profile as completed locally so we don't re-award.
          await ref.read(profileRepositoryProvider).update(
            updated.copyWith(profileCompletedAt: DateTime.now()),
          );
          if (mounted) setState(() => _rewardEarned = true);
        }
      }

      if (mounted && !_rewardEarned) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to save — please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_rewardEarned) {
      return _RewardCelebration(onContinue: () => Navigator.of(context).pop());
    }

    return KvlScaffold(
      title: 'Edit Profile',
      scrollable: true,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: KvlSpacing.sm),
            _SectionHeader(label: 'Personal details'),
            const SizedBox(height: KvlSpacing.sm),

            // Name
            _buildLabel('Full name'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDecoration('e.g. Ravi Kumar'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                return null;
              },
            ),
            const SizedBox(height: KvlSpacing.md),

            // Gender
            _buildLabel('Gender'),
            const SizedBox(height: 4),
            _EnumDropdown<Gender>(
              options: Gender.values.toList(),
              selected: _gender,
              hint: 'Select gender',
              label: (g) => g.label,
              onSelected: (g) => setState(() => _gender = g),
            ),
            const SizedBox(height: KvlSpacing.md),

            // Location
            _buildLabel('Location'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _locationCtrl,
              decoration: _inputDecoration('e.g. Hyderabad, Telangana'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: KvlSpacing.md),

            // Birth year
            _buildLabel('Year of birth'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _birthYearCtrl,
              decoration: _inputDecoration('e.g. 1990'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Year of birth is required';
                final y = int.tryParse(v);
                if (y == null || y < 1900 || y > DateTime.now().year) {
                  return 'Enter a valid year';
                }
                return null;
              },
            ),
            const SizedBox(height: KvlSpacing.md),

            // Mother tongue
            _buildLabel('Mother tongue'),
            const SizedBox(height: 4),
            _DropdownSelector(
              options: _motherTongues,
              selected: _motherTongue,
              hint: 'Select your mother tongue',
              onSelected: (v) => setState(() => _motherTongue = v),
            ),

            const SizedBox(height: KvlSpacing.lg),

            // Completion banner
            if (_isComplete) ...[
              _CompletionBanner(alreadyDone: false),
              const SizedBox(height: KvlSpacing.md),
            ],

            if (_error != null) ...[
              Text(
                _error!,
                style: KvlText.caption(11).copyWith(color: KvlColors.danger),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KvlSpacing.sm),
            ],

            KvlButton(
              label: _busy ? 'Saving…' : 'Save Profile',
              onPressed: (_busy || !_isComplete) ? null : _save,
            ),
            const SizedBox(height: KvlSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: KvlText.ui(12, FontWeight.w600).copyWith(color: KvlColors.inkSoft),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: KvlText.muted(13),
        filled: true,
        fillColor: KvlColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: KvlRadius.brMD,
          borderSide: BorderSide(color: KvlColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: KvlRadius.brMD,
          borderSide: BorderSide(color: KvlColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: KvlRadius.brMD,
          borderSide: const BorderSide(color: KvlColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: KvlRadius.brMD,
          borderSide: const BorderSide(color: KvlColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: KvlRadius.brMD,
          borderSide: const BorderSide(color: KvlColors.danger, width: 1.5),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: KvlText.caption(10).copyWith(
          color: KvlColors.muted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      );
}

class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
    required this.options,
    required this.selected,
    required this.hint,
    required this.label,
    required this.onSelected,
  });

  final List<T> options;
  final T? selected;
  final String hint;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KvlColors.surface,
        borderRadius: KvlRadius.brMD,
        border: Border.all(color: KvlColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: selected,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(hint, style: KvlText.muted(13)),
          ),
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          borderRadius: KvlRadius.brMD,
          style: KvlText.body(),
          items: options.map((o) {
            return DropdownMenuItem<T>(
              value: o,
              child: Text(label(o), style: KvlText.body()),
            );
          }).toList(),
          onChanged: (v) { if (v != null) onSelected(v); },
        ),
      ),
    );
  }
}

class _DropdownSelector extends StatelessWidget {
  const _DropdownSelector({
    required this.options,
    required this.selected,
    required this.hint,
    required this.onSelected,
  });

  final List<(String, String)> options;
  final String? selected;
  final String hint;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KvlColors.surface,
        borderRadius: KvlRadius.brMD,
        border: Border.all(color: KvlColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(hint, style: KvlText.muted(13)),
          ),
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          borderRadius: KvlRadius.brMD,
          style: KvlText.body(),
          items: options.map((pair) {
            final (code, name) = pair;
            return DropdownMenuItem(
              value: code,
              child: Text(name, style: KvlText.body()),
            );
          }).toList(),
          onChanged: (v) { if (v != null) onSelected(v); },
        ),
      ),
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({required this.alreadyDone});
  final bool alreadyDone;

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      padding: const EdgeInsets.all(KvlSpacing.md),
      gradient: const LinearGradient(
        colors: [Color(0xFFFBE9A8), Color(0xFFF5D970)],
      ),
      border: Border.all(color: const Color(0xFFE8C04A)),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: KvlRadius.brSM,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.star_rounded, color: KvlColors.gold, size: 18),
          ),
          const SizedBox(width: KvlSpacing.sm),
          Expanded(
            child: Text(
              alreadyDone
                  ? 'Profile already complete — 50 pts earned'
                  : 'Complete your profile → earn 50 reward points!',
              style: KvlText.caption(12).copyWith(
                color: const Color(0xFF5a4400),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCelebration extends StatelessWidget {
  const _RewardCelebration({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KvlColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KvlSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.star_rounded, color: KvlColors.gold, size: 80),
              const SizedBox(height: KvlSpacing.md),
              Text(
                'Profile Complete!',
                style: KvlText.title(26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KvlSpacing.sm),
              Text(
                'You\'ve earned 50 reward points for completing your profile.',
                style: KvlText.body().copyWith(color: KvlColors.inkSoft),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KvlSpacing.xl),
              KvlButton(
                label: 'Continue',
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
