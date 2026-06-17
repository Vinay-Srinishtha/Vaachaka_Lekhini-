import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:math';
import 'dart:typed_data';

import '../../../app/providers.dart';
import '../../../core/storage/repository.dart';
import '../../enrolment/handwriting/domain/handwriting_asset.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/auth_shared_widgets.dart';
import '../../profiles/domain/profile.dart';
import '../../programs/domain/program.dart';
import '../../../l10n/l10n.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/storage/hive_setup.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/settings_repository.dart';
import 'widgets/setting_row.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final profile = ref.watch(activeProfileProvider).value;
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final programs =
        ref.watch(programsForActiveProfileProvider).value ?? const [];
    final languages = KvlLanguage.availableFor(
      ref.watch(mantraCatalogProvider).value ?? const [],
    );
    final points = ref.watch(rewardTotalProvider).value ?? 0;
    final settingsRepo = ref.read(settingsRepositoryProvider);

    final totalChants = programs.fold<int>(0, (a, p) => a + p.totalProgress);
    final longestStreak = programs.isEmpty
        ? 0
        : programs.map((p) => p.longestStreak).reduce((a, b) => a > b ? a : b);

    return KvlScaffold(
      title: context.l10n.profileTitle,
      trailing: TextButton(
        onPressed: () => context.push(KvlRoute.profileEdit),
        child: Text(
          context.l10n.editButton,
          style: KvlText.ui(
            12,
            FontWeight.w600,
          ).copyWith(color: KvlColors.primaryDeep),
        ),
      ),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.sm),

          // Avatar + name
          Center(
            child: MilestoneRing(
              completed: programs.where((p) => p.isGoalReached).length,
              total: programs.length,
              strokeWidth: 3.5,
              gap: 3.0,
              child: Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFB572), KvlColors.primary],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  profile?.initials ?? '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              profile?.name ?? session?.username ?? 'Friend',
              style: KvlText.title(15),
            ),
          ),
          if (session != null)
            Center(child: Text(session.mobile, style: KvlText.muted(11))),

          const SizedBox(height: KvlSpacing.sm),
          if (profile != null && !profile.isProfileComplete)
            GestureDetector(
              onTap: () => context.push(KvlRoute.profileEdit),
              child: KvlCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: KvlSpacing.md,
                  vertical: KvlSpacing.sm,
                ),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBE9A8), Color(0xFFF5D970)],
                ),
                border: Border.all(color: const Color(0xFFE8C04A)),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: KvlColors.gold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Complete your profile → earn 50 reward points!',
                        style: KvlText.caption(11.5).copyWith(
                          color: const Color(0xFF5a4400),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF8a6900)),
                  ],
                ),
              ),
            )
          else if (profile != null && profile.isProfileComplete)
            KvlCard(
              padding: const EdgeInsets.symmetric(
                horizontal: KvlSpacing.md,
                vertical: KvlSpacing.sm,
              ),
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              ),
              border: Border.all(color: const Color(0xFF81C784)),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile complete · +50 pts earned',
                          style: KvlText.caption(11.5).copyWith(
                            color: const Color(0xFF1B5E20),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Reward points are added to your balance',
                          style: KvlText.caption(10.5).copyWith(
                            color: const Color(0xFF388E3C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(KvlRoute.profileEdit),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: KvlRadius.brPill,
                      ),
                      child: Text(
                        'Edit Profile',
                        style: KvlText.caption(11).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: KvlSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Kpi(
                  value: IndianNumberFormat.compact(totalChants),
                  label: context.l10n.totalChantsKpi,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Kpi(
                  value: '$longestStreak',
                  label: context.l10n.currentStreak,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Kpi(
                  value: '${programs.where((p) => p.isGoalReached).length}'
                      '/${programs.length}',
                  label: context.l10n.milestones,
                ),
              ),
            ],
          ),

          const SizedBox(height: KvlSpacing.md),
          KvlCard(
            padding: const EdgeInsets.all(KvlSpacing.md),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFFBE9A8), Color(0xFFF5D970)],
            ),
            border: Border.all(color: const Color(0xFFE8C04A)),
            onTap: () => context.push(KvlRoute.rewardHistory),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: KvlRadius.brSM,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.star_rounded,
                    color: KvlColors.gold,
                    size: 18,
                  ),
                ),
                const SizedBox(width: KvlSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.rewardPointsLabel,
                        style: KvlText.caption(10).copyWith(
                          color: const Color(0xFF8a6900),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        IndianNumberFormat.format(points),
                        style: KvlText.bigNumber(
                          18,
                        ).copyWith(color: const Color(0xFF5a4400)),
                      ),
                    ],
                  ),
                ),
                KvlButton(
                  size: KvlButtonSize.tiny,
                  expand: false,
                  label: context.l10n.visitStore,
                  onPressed: () => context.go(KvlRoute.store),
                ),
              ],
            ),
          ),

          const SizedBox(height: KvlSpacing.sm),
          _RewardRulesCard(profileComplete: profile?.isProfileComplete ?? false),

          SettingsSection(
            title: context.l10n.familyCommunitySection,
            children: [
              SettingRow(
                icon: Icons.switch_account_rounded,
                label: 'Switch User',
                onTap: () async {
                  await ref
                      .read(profileRepositoryProvider)
                      .clearActive();
                  if (context.mounted) context.go(KvlRoute.profileSelect);
                },
              ),
              SettingRow(
                icon: Icons.smartphone_rounded,
                label: context.l10n.changeMobileNumber,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _ChangeMobileSheet(parentRef: ref),
                ),
              ),
              // Only the primary member (Me) can manage family members.
              if (profile?.relation == FamilyRelation.me)
                SettingRow(
                  icon: Icons.group_outlined,
                  label: context.l10n.familyMembers,
                  onTap: () => context.push(KvlRoute.addFamily),
                ),
              SettingRow(
                icon: Icons.person_add_alt_1_outlined,
                label: context.l10n.inviteFriends,
                onTap: () => context.push(KvlRoute.inviteFriends),
              ),
            ],
          ),

          SettingsSection(
            title: context.l10n.practiceSettingsSection,
            children: [
              SettingRow(
                icon: Icons.alarm_rounded,
                label: context.l10n.reminderTime,
                value: settings.reminderTime.format(context),
                onTap: () async {
                  final t = await _pickReminderTime(
                    context,
                    initialTime: settings.reminderTime,
                  );
                  if (t != null) await settingsRepo.setReminderTime(t);
                },
              ),
              SettingRow(
                icon: Icons.music_note_rounded,
                label: context.l10n.notificationSound,
                value: settings.notificationSound,
                onTap: () => _pickFromList(
                  context,
                  title: context.l10n.notificationSound,
                  options: [
                    context.l10n.notificationSoundBell,
                    context.l10n.notificationSoundConch,
                    context.l10n.notificationSoundBowl,
                    context.l10n.notificationSoundChime,
                    context.l10n.notificationSoundNone,
                  ],
                  current: settings.notificationSound,
                  onPicked: settingsRepo.setNotificationSound,
                ),
              ),
            ],
          ),

          SettingsSection(
            title: context.l10n.voiceSettingsSection,
            children: [
              SettingRow(
                icon: Icons.mic_rounded,
                label: context.l10n.reTrainVoice,
                disabled: programs.where((p) => !p.isGoalReached).isEmpty,
                onTap: () {
                  final activePrograms = programs
                      .where((p) => !p.isGoalReached)
                      .toList();
                  if (activePrograms.isEmpty) return;
                  if (activePrograms.length == 1) {
                    context.push(
                      '${KvlRoute.voiceTraining}/${activePrograms.first.mantraId}?retrain=1',
                    );
                    return;
                  }
                  _RetrainMantraPicker.show(context, ref, activePrograms);
                },
              ),
              SettingRow(
                icon: Icons.tune_rounded,
                label: context.l10n.microphoneSensitivity,
                value: settings.micSensitivity.label,
                onTap: () => _pickFromList(
                  context,
                  title: context.l10n.microphoneSensitivity,
                  options: MicSensitivity.values.map((m) => m.label).toList(),
                  current: settings.micSensitivity.label,
                  onPicked: (v) async {
                    final next = MicSensitivity.values.firstWhere(
                      (m) => m.label == v,
                      orElse: () => MicSensitivity.medium,
                    );
                    await settingsRepo.setMicSensitivity(next);
                  },
                ),
              ),
            ],
          ),

          SettingsSection(
            title: context.l10n.writingStyleSection,
            children: [
              SettingRow(
                icon: Icons.edit_rounded,
                label: context.l10n.retrainWritingStyle,
                disabled: programs.where((p) => !p.isGoalReached).isEmpty,
                onTap: () {
                  final activePrograms = programs
                      .where((p) => !p.isGoalReached)
                      .toList();
                  if (activePrograms.isEmpty) return;
                  if (activePrograms.length == 1) {
                    // Write-on-screen is the only handwriting option — go
                    // straight there instead of a single-choice picker.
                    context.push(
                      '${KvlRoute.handwritingWrite}/${activePrograms.first.mantraId}?retrain=1',
                    );
                    return;
                  }
                  _RetrainWritingPicker.show(context, ref, activePrograms);
                },
              ),
            ],
          ),

          SettingsSection(
            title: context.l10n.displaySection,
            children: [
              SettingRow(
                icon: Icons.language_rounded,
                label: 'App Language',
                value: KvlLanguage.byCode(settings.languageCode).nativeLabel,
                onTap: () => _pickLanguage(
                  context,
                  languages: languages,
                  currentCode: settings.languageCode,
                  onPicked: settingsRepo.setLanguage,
                ),
              ),
              SettingRow(
                icon: Icons.translate_rounded,
                label: 'Mantra Script',
                value:
                    KvlLanguage.byCode(settings.mantraLanguageCode).nativeLabel,
                onTap: () => _pickLanguage(
                  context,
                  languages: languages,
                  currentCode: settings.mantraLanguageCode,
                  onPicked: settingsRepo.setMantraLanguage,
                  title: 'Choose Mantra Script',
                ),
              ),
            ],
          ),

          SettingsSection(
            title: context.l10n.linkSocialSection,
            children: [
              SettingRow(
                icon: Icons.facebook_rounded,
                label: context.l10n.linkFacebook,
                trailing: KvlSwitch(
                  value: settings.linkFacebook,
                  onChanged: settingsRepo.setLinkFacebook,
                ),
              ),
              SettingRow(
                icon: Icons.chat_bubble_rounded,
                label: context.l10n.linkWhatsApp,
                trailing: KvlSwitch(
                  value: settings.linkWhatsApp,
                  onChanged: settingsRepo.setLinkWhatsApp,
                ),
              ),
              SettingRow(
                icon: Icons.camera_alt_rounded,
                label: context.l10n.linkInstagram,
                trailing: KvlSwitch(
                  value: settings.linkInstagram,
                  onChanged: settingsRepo.setLinkInstagram,
                ),
              ),
            ],
          ),

          SettingsSection(
            title: context.l10n.supportPrivacySection,
            children: [
              SettingRow(
                icon: Icons.help_outline_rounded,
                label: context.l10n.helpFaqs,
                onTap: () => _openInfo(context, 'help'),
              ),
              SettingRow(
                icon: Icons.flag_outlined,
                label: context.l10n.reportIssue,
                onTap: () => _openInfo(context, 'report'),
              ),
              SettingRow(
                icon: Icons.feedback_outlined,
                label: context.l10n.shareFeedback,
                onTap: () => _openInfo(context, 'feedback'),
              ),
              SettingRow(
                icon: Icons.lock_outline_rounded,
                label: context.l10n.privacyPolicy,
                onTap: () => _openInfo(context, 'privacy'),
              ),
              SettingRow(
                icon: Icons.cloud_download_outlined,
                label: context.l10n.downloadYourData,
                onTap: () => _downloadData(ref),
              ),
              SettingRow(
                icon: Icons.info_outline_rounded,
                label: context.l10n.aboutApp,
                onTap: () => _openInfo(context, 'about'),
              ),
            ],
          ),

          const SizedBox(height: KvlSpacing.lg),
          KvlButton(
            variant: KvlButtonVariant.outlineDanger,
            label: context.l10n.logoutButton,
            onPressed: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: KvlSpacing.sm),
          KvlButton(
            variant: KvlButtonVariant.danger,
            label: context.l10n.deleteAccount,
            onPressed: () => _confirmDelete(context, ref),
          ),
          const SizedBox(height: KvlSpacing.sm),
          Center(
            child: Text(context.l10n.versionNumber, style: KvlText.muted(10)),
          ),
        ],
      ),
    );
  }

  Future<TimeOfDay?> _pickReminderTime(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderTimePickerSheet(initialTime: initialTime),
    );
  }

  Future<void> _pickFromList(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String? current,
    required Future<void> Function(String) onPicked,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: KvlColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(KvlSpacing.md),
              child: Text(title, style: KvlText.title(15)),
            ),
            for (final o in options)
              ListTile(
                title: Text(o, style: KvlText.body()),
                trailing: o == current
                    ? const Icon(Icons.check_rounded, color: KvlColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(o),
              ),
            const SizedBox(height: KvlSpacing.sm),
          ],
        ),
      ),
    );
    if (picked != null) await onPicked(picked);
  }

  Future<void> _pickLanguage(
    BuildContext context, {
    required List<KvlLanguage> languages,
    required String currentCode,
    required Future<void> Function(String code) onPicked,
    String? title,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: KvlColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: KvlSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(KvlSpacing.md),
                child: Text(
                  title ?? context.l10n.languagePickerTitle,
                  style: KvlText.title(15),
                ),
              ),
              for (final lang in languages)
                ListTile(
                  title: Text(lang.nativeLabel, style: KvlText.body()),
                  subtitle: Text(lang.label, style: KvlText.muted(10.5)),
                  trailing: lang.code == currentCode
                      ? const Icon(
                          Icons.check_rounded,
                          color: KvlColors.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(lang.code),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await onPicked(picked);
  }

  void _openInfo(BuildContext context, String topic) {
    context.push('/info/$topic');
  }

  Future<void> _downloadData(WidgetRef ref) => downloadPracticeReport(ref);
}

/// Shared entry point so other screens can trigger the PDF export.
Future<void> downloadPracticeReport(WidgetRef ref) async {
    final profile = ref.read(activeProfileProvider).value;
    final session = ref.read(sessionProvider).value;
    final settings = await ref.read(settingsRepositoryProvider).snapshot();
    final programs = ref.read(programsForActiveProfileProvider).value ?? const [];
    final programRepo = ref.read(programRepositoryProvider);
    final rewardRepo = ref.read(rewardRepositoryProvider);
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();

    // ─── Collect data for each program ───────────────────────────────────────
    // Completed / goal-reached programs appear first.
    final sortedPrograms = [...programs]..sort((a, b) {
        final aGoalReached = a.totalProgress >= a.targetWritings;
        final bGoalReached = b.totalProgress >= b.targetWritings;
        if (aGoalReached && !bGoalReached) return -1;
        if (!aGoalReached && bGoalReached) return 1;
        return 0;
      });

    final handwritingRepo = ref.read(handwritingRepositoryProvider);
    final List<_ProgramExportData> programData = [];
    for (final p in sortedPrograms) {
      final mantra = ref.read(mantraByIdProvider(p.mantraId));
      final mantraDevanagari = mantra?.name.devanagari ?? p.mantraId;
      final mantraRoman = mantra?.name.roman ?? '';
      final curStreak = await programRepo.currentStreak(p.id);
      final longestStreak = await programRepo.longestStreak(p.id);
      final dailyTarget = (p.targetDays > 0)
          ? (p.targetWritings / p.targetDays).ceil()
          : 0;
      final progressPct = p.targetWritings > 0
          ? ((p.totalProgress / p.targetWritings) * 100).clamp(0, 100).toStringAsFixed(1)
          : '0.0';
      final milestoneThresholds = ref.read(rewardRulesProvider).milestoneThresholds;
      int? nextMilestone;
      for (final t in milestoneThresholds) {
        if (p.totalProgress < t) { nextMilestone = t; break; }
      }
      final dedKey = 'dedication_${p.id}';
      final dedRaw = prefs.getString(dedKey);
      String dedicationLine = 'Not set';
      if (dedRaw != null && dedRaw.contains('||')) {
        final parts = dedRaw.split('||');
        final name = parts[0].trim();
        final note = parts.length > 1 ? parts[1].trim() : '';
        dedicationLine = note.isNotEmpty ? '$name ($note)' : name;
      }
      // Load handwriting pool PNGs for this mantra.
      final List<Uint8List> pool = [];
      if (profile != null) {
        final assets = await handwritingRepo.listForProfile(profile.id);
        for (final a in assets) {
          if (a.mantraId == p.mantraId &&
              a.mode == HandwritingMode.writeOnScreen &&
              a.filePath != null) {
            final f = File(a.filePath!);
            if (await f.exists()) pool.add(await f.readAsBytes());
          }
        }
      }

      programData.add(_ProgramExportData(
        program: p,
        mantraDevanagari: mantraDevanagari,
        mantraRoman: mantraRoman,
        curStreak: curStreak,
        longestStreak: longestStreak,
        dailyTarget: dailyTarget,
        progressPct: progressPct,
        nextMilestone: nextMilestone,
        dedicationLine: dedicationLine,
        handwritingPool: pool,
      ));
    }

    int totalPts = 0;
    if (profile != null) {
      totalPts = await rewardRepo.totalPoints(profile.id);
    }

    // ─── Build PDF ────────────────────────────────────────────────────────────
    final pdf = pw.Document();

    const primary = PdfColor.fromInt(0xFF5E35B1);
    const primaryLight = PdfColor.fromInt(0xFFEDE7F6);
    const inkDark = PdfColor.fromInt(0xFF1A1A2E);
    const inkSoft = PdfColor.fromInt(0xFF4A4A6A);
    const muted = PdfColor.fromInt(0xFF9E9E9E);

    // For each program: one or more pages showing handwriting images (or text fallback)
    final rng = Random();
    for (final pd in programData) {
      final mantraText = pd.mantraDevanagari.isNotEmpty
          ? pd.mantraDevanagari
          : pd.mantraRoman;
      final totalCount = pd.program.totalProgress;
      final goalReached = pd.program.totalProgress >= pd.program.targetWritings;
      final statusLabel = goalReached ? 'Goal Achieved' : 'In Progress';
      const statusColorAchieved = PdfColor.fromInt(0xFF2E7D32);
      const statusColorProgress = PdfColor.fromInt(0xFFE65100);
      final statusColor = goalReached ? statusColorAchieved : statusColorProgress;

      final hasImages = pd.handwritingPool.isNotEmpty;
      // Pre-convert pool bytes to pw.MemoryImage
      final poolImages = pd.handwritingPool
          .map((b) => pw.MemoryImage(b))
          .toList();

      // Build random allocation: slot i → pool[randomIndex]
      List<int> imageAlloc = [];
      if (hasImages && totalCount > 0) {
        imageAlloc = List.generate(totalCount, (_) => rng.nextInt(poolImages.length));
      }

      // 20 images per page (4 cols × 5 rows) when showing images; 50 text items otherwise
      final itemsPerPage = hasImages ? 20 : 50;
      final pageCount = totalCount == 0 ? 1 : ((totalCount - 1) ~/ itemsPerPage + 1);

      for (int pg = 0; pg < pageCount; pg++) {
        final startIdx = pg * itemsPerPage;
        final endIdx = (startIdx + itemsPerPage).clamp(0, totalCount);
        final countOnPage = endIdx - startIdx;
        final pgStartIdx = startIdx; // capture for closure

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(36),
            build: (ctx) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Header bar
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const pw.BoxDecoration(color: primary),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Vachika Lekhini',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Page ${pg + 1} / $pageCount',
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  // Mantra name + status row
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        pd.mantraRoman.isNotEmpty
                            ? '${pd.mantraDevanagari}  •  ${pd.mantraRoman}'
                            : pd.mantraDevanagari,
                        style: const pw.TextStyle(color: inkSoft, fontSize: 11),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: statusColor,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                        ),
                        child: pw.Text(
                          statusLabel,
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Written ${_fmtNum(totalCount)} / ${_fmtNum(pd.program.targetWritings)} times',
                    style: const pw.TextStyle(color: muted, fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: primaryLight, thickness: 1),
                  pw.SizedBox(height: 6),
                  // Grid — images if pool exists, text fallback otherwise
                  if (countOnPage > 0)
                    pw.Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(countOnPage, (i) {
                        final slotIndex = pgStartIdx + i;
                        if (hasImages) {
                          final img = poolImages[imageAlloc[slotIndex]];
                          return pw.Container(
                            width: 118,
                            height: 80,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: primaryLight, width: 0.8),
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.ClipRRect(
                              horizontalRadius: 4,
                              verticalRadius: 4,
                              child: pw.Image(img, fit: pw.BoxFit.contain),
                            ),
                          );
                        } else {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: primaryLight, width: 0.5),
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              '${slotIndex + 1}. $mantraText',
                              style: pw.TextStyle(fontSize: 10, color: inkDark, fontWeight: pw.FontWeight.bold),
                            ),
                          );
                        }
                      }),
                    ),
                  if (totalCount == 0)
                    pw.Center(
                      child: pw.Text('No entries recorded yet', style: const pw.TextStyle(color: muted, fontSize: 12)),
                    ),
                ],
              );
            },
          ),
        );
      }
    }

    // ─── Summary page ─────────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const pw.BoxDecoration(color: primary),
                child: pw.Text(
                  'Practice Summary',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Exported on ${_fmtDate(now)} at ${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}',
                style: const pw.TextStyle(color: muted, fontSize: 9),
              ),
              pw.SizedBox(height: 16),

              // Account section
              _pdfSectionHeader('Account', primary, primaryLight),
              pw.SizedBox(height: 6),
              _pdfTable([
                ['Name', profile?.name ?? '—'],
                ['Mobile', session?.mobile ?? '—'],
                ['Username', session?.username ?? '—'],
                ['Language', settings.languageCode],
                ['Reward Points', '$totalPts pts'],
              ], inkDark, inkSoft, primaryLight),
              pw.SizedBox(height: 16),

              // Programs section
              _pdfSectionHeader('Mantra Programs', primary, primaryLight),
              pw.SizedBox(height: 6),
              ...programData.map((pd) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const pw.BoxDecoration(color: primaryLight),
                    child: pw.Text(
                      pd.mantraRoman.isNotEmpty
                          ? '${pd.mantraDevanagari}  (${pd.mantraRoman})'
                          : pd.mantraDevanagari,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                  _pdfTable([
                    ['Started', _fmtDate(pd.program.startedAt)],
                    ['Status', pd.program.totalProgress >= pd.program.targetWritings ? '✓ Goal Achieved' : 'In Progress'],
                    ['Target', '${_fmtNum(pd.program.targetWritings)} chants over ${pd.program.targetDays} days'],
                    ['Completed', '${_fmtNum(pd.program.totalProgress)} (${pd.progressPct}%)'],
                    ['Remaining', _fmtNum((pd.program.targetWritings - pd.program.totalProgress).clamp(0, pd.program.targetWritings))],
                    ['Daily Goal', '${_fmtNum(pd.dailyTarget)} chants/day'],
                    ['Current Streak', '${pd.curStreak} days'],
                    ['Longest Streak', '${pd.longestStreak} days'],
                    if (pd.nextMilestone != null)
                      ['Next Milestone', '${_fmtNum(pd.nextMilestone!)} (${_fmtNum(pd.nextMilestone! - pd.program.totalProgress)} to go)']
                    else
                      ['Milestones', 'All crossed'],
                    ['Dedicated To', pd.dedicationLine],
                  ], inkDark, inkSoft, primaryLight),
                  pw.SizedBox(height: 12),
                ],
              )),

              pw.Spacer(),
              pw.Divider(color: primaryLight),
              pw.Text(
                'Generated by Vachika Lekhini  •  May your practice bring peace and purpose.',
                style: const pw.TextStyle(color: muted, fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    // ─── Save and share ───────────────────────────────────────────────────────
    final dir = await getTemporaryDirectory();
    final stamp = now.toIso8601String().replaceAll(':', '-').substring(0, 19);
    final file = File('${dir.path}/vachika_lekhini_export_$stamp.pdf');
    await file.writeAsBytes(await pdf.save(), flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Vachika Lekhini – My Practice Report',
        text: 'My mantra practice data from Vachika Lekhini',
      ),
    );
  }

pw.Widget _pdfSectionHeader(String title, PdfColor primary, PdfColor bg) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: pw.BoxDecoration(
      color: bg,
      border: pw.Border(left: pw.BorderSide(color: primary, width: 3)),
    ),
    child: pw.Text(
      title,
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primary),
    ),
  );
}

pw.Widget _pdfTable(
  List<List<String>> rows,
  PdfColor inkDark,
  PdfColor inkSoft,
  PdfColor stripe,
) {
  return pw.Table(
    columnWidths: {
      0: const pw.FlexColumnWidth(1.4),
      1: const pw.FlexColumnWidth(2.6),
    },
    children: rows.asMap().entries.map((entry) {
      final i = entry.key;
      final row = entry.value;
      return pw.TableRow(
        decoration: i.isEven ? null : pw.BoxDecoration(color: stripe),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pw.Text(row[0], style: pw.TextStyle(fontSize: 9, color: inkSoft)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pw.Text(row[1], style: pw.TextStyle(fontSize: 9, color: inkDark, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      );
    }).toList(),
  );
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

String _fmtNum(int n) {
  if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(2)} Cr';
  if (n >= 100000) return '${(n / 100000).toStringAsFixed(2)} L';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}

// ─── ProfileScreen private helpers (need BuildContext / WidgetRef) ────────────

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.logoutDialogTitle),
        content: Text(context.l10n.logoutDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.logoutDialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.logoutDialogConfirm),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(authRepositoryProvider).logout();
    }
  }

Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.deleteDialogTitle),
        content: Text(context.l10n.deleteDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.deleteDialogCancel),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: KvlColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.deleteDialogConfirm),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;

    await ref.read(authRepositoryProvider).deleteAccount();
    final db = ref.read(appDatabaseProvider);
    await db.delete(db.sessions).go();
    await db.delete(db.programs).go();
    await db.delete(db.rewardEvents).go();
    final boxes = [profilesBox(), settingsBox(), cacheBox()];
    for (final b in boxes) {
      await b.clear();
    }
}

class _ReminderTimePickerSheet extends StatefulWidget {
  const _ReminderTimePickerSheet({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_ReminderTimePickerSheet> createState() =>
      _ReminderTimePickerSheetState();
}

class _ReminderTimePickerSheetState extends State<_ReminderTimePickerSheet> {
  late int _hour;
  late int _minute;
  late bool _isPm;

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hour;
    _isPm = h >= 12;
    _hour = h % 12 == 0 ? 12 : h % 12;
    _minute = widget.initialTime.minute;
  }

  TimeOfDay get _time => TimeOfDay(
    hour: _isPm ? (_hour == 12 ? 12 : _hour + 12) : (_hour == 12 ? 0 : _hour),
    minute: _minute,
  );

  String get _hourLabel => _hour.toString().padLeft(2, '0');
  String get _minuteLabel => _minute.toString().padLeft(2, '0');

  void _changeHour(int delta) {
    setState(() {
      _hour = ((_hour - 1 + delta) % 12) + 1;
      if (_hour <= 0) _hour += 12;
    });
  }

  void _changeMinute(int delta) {
    setState(() {
      _minute = (_minute + delta) % 60;
      if (_minute < 0) _minute += 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = MaterialLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: KvlColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            KvlSpacing.lg,
            KvlSpacing.sm,
            KvlSpacing.lg,
            KvlSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KvlColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: KvlSpacing.md),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: KvlColors.primaryGhost,
                      borderRadius: KvlRadius.brMD,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.alarm_rounded,
                      color: KvlColors.primaryDeep,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: KvlSpacing.sm),
                  Expanded(
                    child: Text(
                      context.l10n.reminderTime,
                      style: KvlText.title(16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: KvlSpacing.md),
              KvlCard(
                variant: KvlCardVariant.warm,
                border: Border.all(color: KvlColors.primarySoft),
                padding: const EdgeInsets.all(KvlSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$_hourLabel:$_minuteLabel',
                        style: KvlText.bigNumber(
                          34,
                        ).copyWith(color: KvlColors.ink),
                      ),
                    ),
                    _PeriodToggle(
                      isPm: _isPm,
                      onChanged: (value) => setState(() => _isPm = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KvlSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _TimeStepper(
                      label: 'Hour',
                      value: _hourLabel,
                      onDecrease: () => _changeHour(-1),
                      onIncrease: () => _changeHour(1),
                    ),
                  ),
                  const SizedBox(width: KvlSpacing.sm),
                  Expanded(
                    child: _TimeStepper(
                      label: 'Minute',
                      value: _minuteLabel,
                      onDecrease: () => _changeMinute(-1),
                      onIncrease: () => _changeMinute(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KvlSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final minute in const [0, 15, 30, 45])
                    _MinuteChip(
                      minute: minute,
                      selected: _minute == minute,
                      onTap: () => setState(() => _minute = minute),
                    ),
                ],
              ),
              const SizedBox(height: KvlSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: KvlButton(
                      label: labels.cancelButtonLabel,
                      variant: KvlButtonVariant.ghost,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: KvlSpacing.sm),
                  Expanded(
                    child: KvlButton(
                      label: labels.okButtonLabel,
                      onPressed: () => Navigator.of(context).pop(_time),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.isPm, required this.onChanged});

  final bool isPm;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: KvlRadius.brMD,
        border: Border.all(color: KvlColors.primarySoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodPill(
            label: 'AM',
            selected: !isPm,
            onTap: () => onChanged(false),
          ),
          _PeriodPill(
            label: 'PM',
            selected: isPm,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: KvlRadius.brSM,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? KvlColors.primary : Colors.transparent,
          borderRadius: KvlRadius.brSM,
        ),
        child: Text(
          label,
          style: KvlText.caption(11).copyWith(
            color: selected ? Colors.white : KvlColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TimeStepper extends StatelessWidget {
  const _TimeStepper({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      variant: KvlCardVariant.flat,
      padding: const EdgeInsets.symmetric(
        horizontal: KvlSpacing.sm,
        vertical: KvlSpacing.sm,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: KvlText.caption(
              10,
            ).copyWith(color: KvlColors.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _StepIconButton(icon: Icons.remove_rounded, onTap: onDecrease),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: KvlText.bigNumber(24).copyWith(color: KvlColors.ink),
                ),
              ),
              _StepIconButton(icon: Icons.add_rounded, onTap: onIncrease),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepIconButton extends StatelessWidget {
  const _StepIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: KvlColors.primaryGhost,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: KvlColors.primaryDeep, size: 19),
      ),
    );
  }
}

class _MinuteChip extends StatelessWidget {
  const _MinuteChip({
    required this.minute,
    required this.selected,
    required this.onTap,
  });

  final int minute;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: KvlRadius.brSM,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? KvlColors.primary : KvlColors.primaryGhost,
          borderRadius: KvlRadius.brSM,
          border: Border.all(
            color: selected ? KvlColors.primary : KvlColors.primarySoft,
          ),
        ),
        child: Text(
          ':${minute.toString().padLeft(2, '0')}',
          style: KvlText.caption(11.5).copyWith(
            color: selected ? Colors.white : KvlColors.primaryDeep,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RewardRulesCard extends StatelessWidget {
  const _RewardRulesCard({required this.profileComplete});
  final bool profileComplete;

  @override
  Widget build(BuildContext context) {
    const rules = [
      (icon: Icons.person_rounded,      label: 'Complete your profile',      pts: 50,   note: 'One-time bonus'),
      (icon: Icons.edit_rounded,         label: 'Each handwriting session',   pts: 5,    note: 'Per session'),
      (icon: Icons.mic_rounded,          label: 'Each voice chanting session', pts: 5,   note: 'Per session'),
      (icon: Icons.local_fire_department_rounded, label: 'Daily practice streak', pts: 10, note: 'Per streak day'),
      (icon: Icons.group_add_rounded,    label: 'Invite a friend',            pts: 25,   note: 'Per referral'),
      (icon: Icons.emoji_events_rounded, label: 'Reach a milestone',          pts: 100,  note: 'Per milestone'),
    ];
    return KvlCard(
      padding: const EdgeInsets.all(KvlSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: KvlColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'How to earn points',
                style: KvlText.caption(12).copyWith(
                  fontWeight: FontWeight.w800,
                  color: KvlColors.inkSoft,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: KvlSpacing.sm),
          for (final r in rules) ...[
            _RuleRow(
              icon: r.icon,
              label: r.label,
              pts: r.pts,
              note: r.note,
              earned: r.icon == Icons.person_rounded && profileComplete,
            ),
            if (r != rules.last)
              const Divider(height: 1, thickness: 0.5),
          ],
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.icon,
    required this.label,
    required this.pts,
    required this.note,
    required this.earned,
  });
  final IconData icon;
  final String label;
  final int pts;
  final String note;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: earned ? const Color(0xFFE8F5E9) : KvlColors.primaryGhost,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: earned ? const Color(0xFF2E7D32) : KvlColors.primary),
          ),
          const SizedBox(width: KvlSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: KvlText.caption(12).copyWith(fontWeight: FontWeight.w600, color: KvlColors.ink)),
                Text(note, style: KvlText.caption(10.5).copyWith(color: KvlColors.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: earned ? const Color(0xFFE8F5E9) : KvlColors.primaryGhost,
              borderRadius: KvlRadius.brPill,
            ),
            child: Text(
              earned ? '✓ earned' : '+$pts pts',
              style: KvlText.caption(11).copyWith(
                fontWeight: FontWeight.w700,
                color: earned ? const Color(0xFF2E7D32) : KvlColors.primaryDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) {
    return KvlCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: KvlSpacing.sm,
      ),
      child: Column(
        children: [
          Text(value, style: KvlText.bigNumber(15)),
          Text(
            label,
            style: KvlText.muted(9.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RetrainMantraPicker {
  static void show(BuildContext context, WidgetRef ref, List<Program> programs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _RetrainPickerSheet(
        title: 'Retrain voice for which mantra?',
        programs: programs,
        onPicked: (mantraId) {
          Navigator.pop(sheetCtx);
          context.push('${KvlRoute.voiceTraining}/$mantraId?retrain=1');
        },
      ),
    );
  }
}

class _RetrainWritingPicker {
  static void show(BuildContext context, WidgetRef ref, List<Program> programs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _RetrainPickerSheet(
        title: 'Retrain writing for which mantra?',
        programs: programs,
        onPicked: (mantraId) {
          Navigator.pop(sheetCtx);
          context.push('${KvlRoute.handwritingWrite}/$mantraId?retrain=1');
        },
      ),
    );
  }
}

class _RetrainPickerSheet extends ConsumerWidget {
  const _RetrainPickerSheet({
    required this.title,
    required this.programs,
    required this.onPicked,
  });

  final String title;
  final List<Program> programs;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;

    return Container(
      decoration: BoxDecoration(
        color: KvlColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KvlColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: KvlText.ui(16, FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Choose from your active programs',
            style: KvlText.caption(12).copyWith(color: KvlColors.muted),
          ),
          const SizedBox(height: 16),
          ...programs.map((p) {
            final mantra = ref.watch(mantraByIdProvider(p.mantraId));
            final name =
                mantra?.name.displayForLanguage(settings.mantraLanguageCode) ??
                p.mantraId;
            return _MantraPickerTile(
              name: name,
              onTap: () => onPicked(p.mantraId),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MantraPickerTile extends StatelessWidget {
  const _MantraPickerTile({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: KvlColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: KvlColors.border.withValues(alpha: .6)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: KvlColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.mic_rounded,
                  color: KvlColors.primaryDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: KvlText.ui(14, FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: KvlColors.muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Change Mobile Sheet (two-step: enter new number → OTP)
// ─────────────────────────────────────────────────────────────────────────────

class _ChangeMobileSheet extends ConsumerStatefulWidget {
  const _ChangeMobileSheet({required this.parentRef});
  final WidgetRef parentRef;

  @override
  ConsumerState<_ChangeMobileSheet> createState() => _ChangeMobileSheetState();
}

class _ChangeMobileSheetState extends ConsumerState<_ChangeMobileSheet> {
  final _mobileCtrl = TextEditingController();
  String _otp = '';
  bool _otpSent = false;
  bool _busy = false;
  String? _error;
  int _resendSeconds = 0;
  Timer? _timer;

  // Cached before any async gap to avoid unmounted-ref crash.
  late final AuthRepository _authRepo;
  String? _currentMobile;

  @override
  void initState() {
    super.initState();
    // Cache the repository reference immediately — safe here since the widget is mounted.
    _authRepo = ref.read(authRepositoryProvider);
    _currentMobile = ref.read(sessionProvider).value?.mobile;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mobileCtrl.dispose();
    super.dispose();
  }

  String get _digits => _mobileCtrl.text.replaceAll(RegExp(r'\D'), '');
  String get _e164 => '+91$_digits';
  bool get _mobileOk => _validateMobile() == null;

  String? _validateMobile() {
    if (_digits.isEmpty) return context.l10n.authErrorInvalidMobile;
    if (_digits.length != 10) return context.l10n.authErrorEnterMobileValid;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_digits)) {
      return context.l10n.authErrorMobileIndian;
    }
    if (_e164 == _currentMobile) {
      return context.l10n.authErrorSameMobile;
    }
    return null;
  }

  void _startCountdown() {
    _resendSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { if (--_resendSeconds <= 0) t.cancel(); });
    });
  }

  Future<void> _sendOtp() async {
    final validationError = _validateMobile();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() { _busy = true; _error = null; });
    // Use cached repo — never touch `ref` after an await.
    final res = await _authRepo.sendOtp(_e164);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res is Ok<void>) {
        _otpSent = true;
        _otp = '';
        _startCountdown();
      } else if (res is Err<void>) {
        _error = localizeAuthError(context, code: res.failure.code, fallback: res.failure.message);
      }
    });
  }

  Future<void> _verify() async {
    if (_otp.length != 6) {
      setState(() => _error = context.l10n.authErrorEnterOtp6);
      return;
    }
    setState(() { _busy = true; _error = null; });
    final res = await _authRepo.updateMobile(
      newMobile: _e164,
      otp: _otp,
    );
    if (!mounted) return;
    if (res is Ok<Session>) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.mobileUpdatedSuccess),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (res is Err<Session>) {
      setState(() { _busy = false; _error = localizeAuthError(context, code: res.failure.code, fallback: res.failure.message); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: KvlColors.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(
          KvlSpacing.lg,
          KvlSpacing.sm,
          KvlSpacing.lg,
          KvlSpacing.lg,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KvlColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: KvlSpacing.md),

              // Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: KvlColors.primaryGhost,
                      borderRadius: KvlRadius.brMD,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.smartphone_rounded,
                      color: KvlColors.primaryDeep,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: KvlSpacing.sm),
                  Expanded(
                    child: Text(context.l10n.changeMobileSheetTitle, style: KvlText.title(16)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              const SizedBox(height: KvlSpacing.md),

              if (!_otpSent) ...[
                Text(
                  context.l10n.enterNewMobileHint,
                  style: KvlText.caption(12).copyWith(color: KvlColors.inkSoft),
                ),
                const SizedBox(height: KvlSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 78,
                      child: KvlInput(label: 'Code', hint: '+91', readOnly: true),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: KvlInput(
                        label: 'New Mobile',
                        hint: '98765 43210',
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                        autofocus: true,
                        inputFormatters: [AuthMobileFormatter()],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) { if (_mobileOk) _sendOtp(); },
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: KvlSpacing.xs),
                  AuthErrorBar(_error!),
                ],
                const SizedBox(height: KvlSpacing.md),
                KvlButton(
                  label: _busy ? context.l10n.sendingOtpButton : context.l10n.sendOtpButton,
                  onPressed: (_busy || !_mobileOk) ? null : _sendOtp,
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sms_outlined, size: 14, color: KvlColors.inkSoft),
                    const SizedBox(width: 5),
                    Text(
                      context.l10n.enterSixDigitCodeSentToMobile(_digits),
                      style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft),
                    ),
                  ],
                ),
                const SizedBox(height: KvlSpacing.md),
                PinCodeInput(
                  onChanged: (v) => setState(() => _otp = v),
                  onCompleted: (_) => _verify(),
                ),
                const SizedBox(height: KvlSpacing.sm),
                Center(
                  child: _resendSeconds > 0
                      ? Text(
                          context.l10n.resendCodeCountdown(_resendSeconds),
                          style: KvlText.caption(11).copyWith(color: KvlColors.inkSoft),
                        )
                      : GestureDetector(
                          onTap: _busy ? null : () {
                            setState(() { _otp = ''; _error = null; });
                            _sendOtp();
                          },
                          child: Text(
                            context.l10n.resendCode,
                            style: KvlText.caption(11.5).copyWith(
                              color: KvlColors.primaryDeep,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: KvlSpacing.sm),
                  AuthErrorBar(_error!),
                ],
                const SizedBox(height: KvlSpacing.lg),
                KvlButton(
                  label: _busy ? context.l10n.verifyingButton2 : context.l10n.confirmNewNumber,
                  onPressed: (_busy || _otp.length != 6) ? null : _verify,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramExportData {
  const _ProgramExportData({
    required this.program,
    required this.mantraDevanagari,
    required this.mantraRoman,
    required this.curStreak,
    required this.longestStreak,
    required this.dailyTarget,
    required this.progressPct,
    required this.nextMilestone,
    required this.dedicationLine,
    required this.handwritingPool,
  });
  final Program program;
  final String mantraDevanagari;
  final String mantraRoman;
  final int curStreak;
  final int longestStreak;
  final int dailyTarget;
  final String progressPct;
  final int? nextMilestone;
  final String dedicationLine;
  /// PNG bytes for each sample in the rolling pool (may be empty).
  final List<Uint8List> handwritingPool;
}
