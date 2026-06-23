import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/member_address.dart';
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
  late final TextEditingController _gothraCtrl;

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
    _gothraCtrl = TextEditingController(text: profile?.gothra ?? '');
    _gender = profile?.gender;
    _motherTongue = profile?.motherTongue;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthYearCtrl.dispose();
    _locationCtrl.dispose();
    _gothraCtrl.dispose();
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
      final gothra = _gothraCtrl.text.trim();
      final updated = profile.copyWith(
        name: name,
        gender: _gender,
        birthYear: birthYear,
        motherTongue: _motherTongue,
        location: location.isNotEmpty ? location : null,
        gothra: gothra.isNotEmpty ? gothra : null,
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

            // Gothra
            _buildLabel('Gothra (Gotra)'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _gothraCtrl,
              decoration: _inputDecoration('e.g. Kashyapa, Bharadwaja, Vasishtha'),
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
            const _SectionHeader(label: 'Addresses'),
            const SizedBox(height: KvlSpacing.sm),
            _AddressesSection(
              profile: ref.watch(activeProfileProvider).value,
              onChanged: () => setState(() {}),
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

// ─────────────────────────────────────────────────────────────────────────────
// Address section
// ─────────────────────────────────────────────────────────────────────────────

class _AddressesSection extends ConsumerWidget {
  const _AddressesSection({required this.profile, required this.onChanged});
  final Profile? profile;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = profile?.addresses ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (addresses.isEmpty)
          Text(
            'No addresses saved yet.',
            style: KvlText.caption(13).copyWith(color: KvlColors.muted),
          )
        else
          ...addresses.map((addr) => Padding(
                padding: const EdgeInsets.only(bottom: KvlSpacing.xs),
                child: _AddressTile(
                  address: addr,
                  onEdit: () => _openSheet(context, ref, addr, addresses),
                  onDelete: () => _delete(context, ref, addr, addresses),
                ),
              )),
        const SizedBox(height: KvlSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _openSheet(context, ref, null, addresses),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add Address'),
          style: OutlinedButton.styleFrom(
            foregroundColor: KvlColors.primary,
            side: const BorderSide(color: KvlColors.primary),
            shape: RoundedRectangleBorder(borderRadius: KvlRadius.brMD),
            minimumSize: const Size.fromHeight(44),
          ),
        ),
      ],
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref, MemberAddress? existing,
      List<MemberAddress> all) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressSheet(
        initial: existing,
        onSave: (addr) => _save(ref, addr, all, existing),
      ),
    );
  }

  Future<void> _save(WidgetRef ref, MemberAddress updated,
      List<MemberAddress> all, MemberAddress? existing) async {
    final current = profile;
    if (current == null) return;
    List<MemberAddress> next;
    if (existing == null) {
      next = [...all, updated];
    } else {
      next = [for (final a in all) if (a.id == updated.id) updated else a];
    }
    await ref.read(profileRepositoryProvider).update(current.copyWith(addresses: next));
    onChanged();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, MemberAddress addr,
      List<MemberAddress> all) async {
    final current = profile;
    if (current == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Remove address?'),
        content: Text(addr.summary),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(profileRepositoryProvider).update(current.copyWith(
      addresses: [for (final a in all) if (a.id != addr.id) a],
    ));
    onChanged();
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.address, required this.onEdit, required this.onDelete});
  final MemberAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KvlRadius.brMD,
        border: Border.all(color: KvlColors.muted.withValues(alpha: .15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: KvlColors.primarySoft,
            borderRadius: KvlRadius.brSM,
          ),
          alignment: Alignment.center,
          child: Icon(
            switch (address.type) {
              AddressType.home => Icons.home_rounded,
              AddressType.work => Icons.work_rounded,
              AddressType.other => Icons.location_on_rounded,
            },
            size: 18,
            color: KvlColors.primary,
          ),
        ),
        title: Text(address.type.label, style: KvlText.ui(13, FontWeight.w700)),
        subtitle: Text(
          address.summary,
          style: KvlText.caption(12).copyWith(color: KvlColors.muted),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_rounded, size: 18), onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressSheet extends StatefulWidget {
  const _AddressSheet({this.initial, required this.onSave});
  final MemberAddress? initial;
  final void Function(MemberAddress) onSave;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  late MemberAddress _addr;
  final _line1Ctrl = TextEditingController();
  final _line2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _addr = widget.initial ?? MemberAddress.blank();
    _line1Ctrl.text = _addr.line1;
    _line2Ctrl.text = _addr.line2 ?? '';
    _cityCtrl.text = _addr.city;
    _pincodeCtrl.text = _addr.pincode;
  }

  @override
  void dispose() {
    _line1Ctrl.dispose();
    _line2Ctrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = _addr.copyWith(
      line1: _line1Ctrl.text.trim(),
      line2: _line2Ctrl.text.trim(),
      city: _cityCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim(),
    );
    Navigator.of(context).pop();
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: KvlColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(KvlSpacing.lg, KvlSpacing.lg, KvlSpacing.lg, bottom + KvlSpacing.lg),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: KvlSpacing.md),
                  decoration: BoxDecoration(
                    color: KvlColors.muted.withValues(alpha: .3),
                    borderRadius: KvlRadius.brPill,
                  ),
                ),
              ),
              Text(
                widget.initial == null ? 'Add Address' : 'Edit Address',
                style: KvlText.title(16),
              ),
              const SizedBox(height: KvlSpacing.md),
              Row(
                children: AddressType.values.map((t) {
                  final sel = _addr.type == t;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _addr = _addr.copyWith(type: t)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? KvlColors.primary : Colors.white,
                            borderRadius: KvlRadius.brMD,
                            border: Border.all(
                              color: sel ? KvlColors.primary : KvlColors.muted.withValues(alpha: .3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            t.label,
                            style: KvlText.ui(13, FontWeight.w600).copyWith(
                              color: sel ? Colors.white : KvlColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: KvlSpacing.md),
              _field(ctrl: _line1Ctrl, label: 'Address Line 1', hint: 'Flat/House no., Building, Street',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: KvlSpacing.sm),
              _field(ctrl: _line2Ctrl, label: 'Address Line 2 (optional)', hint: 'Area, Locality, Landmark'),
              const SizedBox(height: KvlSpacing.sm),
              _field(ctrl: _cityCtrl, label: 'City / Town', hint: 'e.g. Hyderabad',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: KvlSpacing.sm),
              DropdownButtonFormField<String>(
                value: _addr.state.isEmpty ? null : _addr.state,
                decoration: _inputDecoration('State'),
                isExpanded: true,
                hint: const Text('Select state'),
                items: kIndianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _addr = _addr.copyWith(state: v ?? '')),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: KvlSpacing.sm),
              _field(ctrl: _pincodeCtrl, label: 'PIN Code', hint: '6-digit postal code',
                  keyboardType: TextInputType.number, maxLength: 6,
                  validator: (v) {
                    if (v == null || v.trim().length != 6) return '6 digits required';
                    if (int.tryParse(v.trim()) == null) return 'Numbers only';
                    return null;
                  }),
              const SizedBox(height: KvlSpacing.md),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: KvlColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: KvlRadius.brMD),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _submit,
                child: Text(
                  widget.initial == null ? 'Save Address' : 'Update Address',
                  style: KvlText.ui(14, FontWeight.w700).copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLength: maxLength,
        decoration: _inputDecoration(label).copyWith(hintText: hint),
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      );

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: KvlRadius.brMD,
          borderSide: BorderSide(color: KvlColors.muted.withValues(alpha: .3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: KvlRadius.brMD,
          borderSide: BorderSide(color: KvlColors.muted.withValues(alpha: .3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: KvlRadius.brMD,
          borderSide: const BorderSide(color: KvlColors.primary),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

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
