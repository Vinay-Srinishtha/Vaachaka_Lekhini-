import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../domain/profile.dart';

class AddFamilyScreen extends ConsumerStatefulWidget {
  const AddFamilyScreen({super.key});

  @override
  ConsumerState<AddFamilyScreen> createState() => _AddFamilyScreenState();
}

class _AddFamilyScreenState extends ConsumerState<AddFamilyScreen> {
  final _name = TextEditingController();
  FamilyRelation _relation = FamilyRelation.other;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = ref.read(sessionProvider).value;
    if (session == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.l10n.enterNameError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).create(
            userId: session.userId,
            name: name,
            relation: _relation,
          );
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final profiles = ref.watch(profilesProvider).value ?? const [];
    final cap = ref.watch(profileCapProvider);
    final remaining = (cap - profiles.length).clamp(0, cap);

    return KvlScaffold(
      title: context.l10n.addFamilyTitle,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.md),
          Text(
            context.l10n.addFamilyDescription(cap),
            textAlign: TextAlign.center,
            style: KvlText.caption(11.5).copyWith(height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.slotsRemaining(remaining),
            textAlign: TextAlign.center,
            style: KvlText.caption(11).copyWith(color: KvlColors.primaryDeep, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: KvlSpacing.lg),

          if (profiles.isNotEmpty) ...[
            Text(context.l10n.existingMembersLabel, style: KvlText.title(13)),
            const SizedBox(height: KvlSpacing.sm),
            for (final p in profiles) ...[
              KvlCard(
                padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md, vertical: KvlSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFFFFB572), KvlColors.primary]),
                      ),
                      alignment: Alignment.center,
                      child: Text(p.initials,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                    const SizedBox(width: KvlSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: KvlText.ui(12, FontWeight.w600)),
                          Text(p.relation.label, style: KvlText.muted(10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KvlSpacing.sm),
            ],
            const SizedBox(height: KvlSpacing.md),
          ],

          if (remaining > 0) ...[
            KvlCard(
              padding: const EdgeInsets.all(KvlSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.l10n.registeredMobileLabel,
                      style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md, vertical: 12),
                    decoration: BoxDecoration(color: KvlColors.surfaceWarm, borderRadius: KvlRadius.brMD, border: Border.all(color: KvlColors.border)),
                    child: Text(session?.mobile ?? '+91 ', style: KvlText.ui(13).copyWith(color: KvlColors.inkSoft)),
                  ),
                  const SizedBox(height: KvlSpacing.md),
                  KvlInput(label: context.l10n.familyMemberNameLabel, hint: context.l10n.familyMemberNameHint, controller: _name),
                  const SizedBox(height: KvlSpacing.sm),
                  Text(context.l10n.relationshipDropdownLabel,
                      style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md),
                    decoration: BoxDecoration(color: KvlColors.surface, borderRadius: KvlRadius.brMD, border: Border.all(color: KvlColors.border)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<FamilyRelation>(
                        value: _relation,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: [
                          for (final r in FamilyRelation.values)
                            DropdownMenuItem(value: r, child: Text(r.label, style: KvlText.ui(13))),
                        ],
                        onChanged: (v) => setState(() => _relation = v ?? FamilyRelation.other),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center, style: KvlText.caption(11).copyWith(color: KvlColors.danger)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: KvlSpacing.md),
            KvlButton(label: _busy ? context.l10n.savingButton : context.l10n.saveMemberButton, onPressed: _busy ? null : _save),
          ] else
            Center(child: Text(context.l10n.maxFamilyMembersReached, style: KvlText.muted(12))),
        ],
      ),
    );
  }
}
