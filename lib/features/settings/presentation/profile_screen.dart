import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';
import '../../../core/storage/repository.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/auth_shared_widgets.dart';
import '../../profiles/domain/profile.dart';
import '../../programs/domain/program.dart';
import '../../../l10n/l10n.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/storage/hive_setup.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
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
        : programs.map((p) => p.daysElapsed).reduce((a, b) => a > b ? a : b);

    return KvlScaffold(
      title: context.l10n.profileTitle,
      trailing: TextButton(
        onPressed: () => _EditProfileSheet.show(context, ref),
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
          const SizedBox(height: 6),
          Center(
            child: Text(
              profile?.name ?? session?.username ?? 'Friend',
              style: KvlText.title(15),
            ),
          ),
          if (session != null)
            Center(child: Text(session.mobile, style: KvlText.muted(11))),

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
                  value:
                      '${programs.where((p) => p.totalProgress > 0).length}/5',
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

          SettingsSection(
            title: context.l10n.familyCommunitySection,
            children: [
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
                onTap: () {
                  final activePrograms = programs
                      .where((p) => !p.isCompleted)
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
                onTap: () {
                  final activePrograms = programs
                      .where((p) => !p.isCompleted)
                      .toList();
                  if (activePrograms.isEmpty) return;
                  if (activePrograms.length == 1) {
                    context.push(
                      '${KvlRoute.handwritingSubmit}/${activePrograms.first.mantraId}?retrain=1',
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
                icon: Icons.brightness_6_rounded,
                label: context.l10n.themeSetting,
                value: switch (settings.themeMode) {
                  ThemeMode.light => context.l10n.themeLight,
                  ThemeMode.dark => context.l10n.themeDark,
                  ThemeMode.system => context.l10n.themeSystem,
                },
                onTap: () => _pickFromList(
                  context,
                  title: context.l10n.themeSetting,
                  options: [
                    context.l10n.themeLight,
                    context.l10n.themeDark,
                    context.l10n.themeSystem,
                  ],
                  current: switch (settings.themeMode) {
                    ThemeMode.light => context.l10n.themeLight,
                    ThemeMode.dark => context.l10n.themeDark,
                    ThemeMode.system => context.l10n.themeSystem,
                  },
                  onPicked: (label) async {
                    final mode = switch (label) {
                      _ when label == context.l10n.themeDark => ThemeMode.dark,
                      _ when label == context.l10n.themeSystem => ThemeMode.system,
                      _ => ThemeMode.light,
                    };
                    await settingsRepo.setThemeMode(mode);
                  },
                ),
              ),
              SettingRow(
                icon: Icons.language_rounded,
                label: context.l10n.languageSetting,
                value: KvlLanguage.byCode(settings.languageCode).nativeLabel,
                onTap: () => _pickLanguage(
                  context,
                  languages: languages,
                  currentCode: settings.languageCode,
                  onPicked: settingsRepo.setLanguage,
                ),
              ),
              SettingRow(
                icon: Icons.text_fields_rounded,
                label: context.l10n.fontSizeSetting,
                value: settings.fontScale == 1.0
                    ? context.l10n.fontSizeDefaultPct
                    : '${(settings.fontScale * 100).round()}%',
                onTap: () => _pickFromList(
                  context,
                  title: context.l10n.fontSizeSetting,
                  options: [
                    context.l10n.fontSizeSmall,
                    context.l10n.fontSizeDefaultPct,
                    context.l10n.fontSizeLarge,
                    context.l10n.fontSizeExtraLarge,
                  ],
                  current: settings.fontScale == 1.0
                      ? context.l10n.fontSizeDefaultPct
                      : null,
                  onPicked: (label) async {
                    final scale = switch (label) {
                      _ when label == context.l10n.fontSizeSmall => 0.9,
                      _ when label == context.l10n.fontSizeLarge => 1.15,
                      _ when label == context.l10n.fontSizeExtraLarge => 1.3,
                      _ => 1.0,
                    };
                    await settingsRepo.setFontScale(scale);
                  },
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
                  context.l10n.languagePickerTitle,
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

  Future<void> _downloadData(WidgetRef ref) async {
    final profile = ref.read(activeProfileProvider).value;
    final session = ref.read(sessionProvider).value;
    final settings = await ref.read(settingsRepositoryProvider).snapshot();
    final programs = ref.read(programsForActiveProfileProvider).value ?? const [];
    final programRepo = ref.read(programRepositoryProvider);
    final rewardRepo = ref.read(rewardRepositoryProvider);
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final buf = StringBuffer();

    // ─── Header ──────────────────────────────────────────────────────────────
    buf.writeln('╔══════════════════════════════════════════════════════╗');
    buf.writeln('║          VACHIKA LEKHINI  –  DATA EXPORT             ║');
    buf.writeln('╚══════════════════════════════════════════════════════╝');
    buf.writeln('Exported on : ${_fmt(now)}');
    buf.writeln();

    // ─── Profile & Account ───────────────────────────────────────────────────
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('  PROFILE & ACCOUNT');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('  Name      : ${profile?.name ?? '—'}');
    buf.writeln('  Relation  : ${profile?.relation.name ?? '—'}');
    buf.writeln('  Mobile    : ${session?.mobile ?? '—'}');
    buf.writeln('  Username  : ${session?.username ?? '—'}');
    buf.writeln('  Language  : ${settings.languageCode}');
    buf.writeln();

    // Reward points
    if (profile != null) {
      final totalPts = await rewardRepo.totalPoints(profile.id);
      final rewardHistory = await rewardRepo.history(profile.id);
      buf.writeln('  Reward Points : $totalPts pts');
      buf.writeln();
      if (rewardHistory.isNotEmpty) {
        buf.writeln('  Reward History:');
        for (final e in rewardHistory) {
          final sign = e.signedAmount >= 0 ? '+' : '';
          buf.writeln('    ${_fmt(e.occurredAt)}  $sign${e.signedAmount} pts  —  ${e.source}');
        }
      }
    }
    buf.writeln();

    // ─── Settings ────────────────────────────────────────────────────────────
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('  SETTINGS');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('  Theme           : ${settings.themeMode.name}');
    buf.writeln('  Font Scale      : ${settings.fontScale}x');
    buf.writeln('  Reminder Time   : ${settings.reminderTime.hour.toString().padLeft(2, "0")}:${settings.reminderTime.minute.toString().padLeft(2, "0")}');
    buf.writeln('  Notification    : ${settings.notificationSound}');
    buf.writeln('  Mic Sensitivity : ${settings.micSensitivity.name}');
    buf.writeln();

    // ─── Programs ────────────────────────────────────────────────────────────
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('  MANTRA PROGRAMS  (${programs.length} total)');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    for (int pi = 0; pi < programs.length; pi++) {
      final p = programs[pi];
      final mantra = ref.read(mantraByIdProvider(p.mantraId));
      final mantraName = mantra != null
          ? '${mantra.name.devanagari}  (${mantra.name.roman})'
          : p.mantraId;

      // Streaks
      final curStreak = await programRepo.currentStreak(p.id);
      final longestStreak = await programRepo.longestStreak(p.id);

      // Daily target
      final dailyTarget = (p.targetDays > 0)
          ? (p.targetWritings / p.targetDays).ceil()
          : 0;

      // Progress percentage
      final progressPct = p.targetWritings > 0
          ? ((p.totalChants / p.targetWritings) * 100).clamp(0, 100).toStringAsFixed(1)
          : '0.0';

      // Next milestone
      final milestoneThresholds = ref.watch(rewardRulesProvider).milestoneThresholds;
      int? nextMilestone;
      for (final t in milestoneThresholds) {
        if (p.totalChants < t) { nextMilestone = t; break; }
      }

      // Dedication
      final dedKey = 'dedication_${p.id}';
      final dedRaw = prefs.getString(dedKey);
      String dedicationLine = 'Not set';
      if (dedRaw != null && dedRaw.contains('||')) {
        final parts = dedRaw.split('||');
        final name = parts[0].trim();
        final note = parts.length > 1 ? parts[1].trim() : '';
        dedicationLine = note.isNotEmpty ? '$name  ($note)' : name;
      }

      // Last 90 days daily counts
      final from90 = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 89));
      final countsByDay = await programRepo.sessionCountsByDay(
        programId: p.id,
        from: from90,
        to: now,
      );

      buf.writeln();
      buf.writeln('  ┌─ Program ${pi + 1} ─────────────────────────────────');
      buf.writeln('  │  Mantra      : $mantraName');
      buf.writeln('  │  Started     : ${_fmtDate(p.startedAt)}');
      buf.writeln('  │  Status      : ${p.isCompleted ? "completed" : "active"}');
      buf.writeln('  │  Target      : ${_fmtNum(p.targetWritings)} chants over ${p.targetDays} days');
      buf.writeln('  │  Daily Goal  : ${_fmtNum(dailyTarget)} chants/day');
      buf.writeln('  │  Completed   : ${_fmtNum(p.totalChants)} chants  ($progressPct%)');
      buf.writeln('  │  Remaining   : ${_fmtNum((p.targetWritings - p.totalChants).clamp(0, p.targetWritings))} chants');
      buf.writeln('  │  Current Streak   : $curStreak days 🔥');
      buf.writeln('  │  Longest Streak   : $longestStreak days');
      if (nextMilestone != null) {
        final toMilestone = nextMilestone - p.totalChants;
        buf.writeln('  │  Next Milestone   : ${_fmtNum(nextMilestone)}  (${_fmtNum(toMilestone)} to go)');
      } else {
        buf.writeln('  │  Milestones  : All crossed ✨');
      }
      buf.writeln('  │  Dedicated To: $dedicationLine');

      // Session history
      if (countsByDay.isNotEmpty) {
        buf.writeln('  │');
        buf.writeln('  │  Daily Practice (last 90 days, active days only):');
        final sortedDays = countsByDay.keys.toList()..sort();
        for (final day in sortedDays) {
          final cnt = countsByDay[day] ?? 0;
          if (cnt > 0) {
            final bar = '█' * (cnt ~/ (dailyTarget > 0 ? (dailyTarget / 10).ceil() : 10)).clamp(1, 20);
            final metGoal = dailyTarget > 0 && cnt >= dailyTarget ? ' ✓' : '';
            buf.writeln('  │    ${_fmtDate(day)}  ${_fmtNum(cnt).padLeft(7)} chants  $bar$metGoal');
          }
        }
      }
      buf.writeln('  └──────────────────────────────────────────────────');
    }

    buf.writeln();
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('  Generated by Vachika Lekhini 🙏');
    buf.writeln('  May your practice bring peace and purpose.');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Write to a temp .txt file and share
    final dir = await getTemporaryDirectory();
    final stamp = now.toIso8601String().replaceAll(':', '-').substring(0, 19);
    final file = File('${dir.path}/vachika_lekhini_export_$stamp.txt');
    await file.writeAsString(buf.toString(), flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/plain')],
        subject: 'Vachika Lekhini – My Practice Report',
        text: 'My mantra practice data from Vachika Lekhini 🙏',
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}  '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  static String _fmtNum(int n) {
    // Simple Indian-style number formatting
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(2)} L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

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

    final db = ref.read(appDatabaseProvider);
    await db.delete(db.sessions).go();
    await db.delete(db.programs).go();
    await db.delete(db.rewardEvents).go();
    final boxes = [profilesBox(), settingsBox(), cacheBox()];
    for (final b in boxes) {
      await b.clear();
    }
    await ref.read(authRepositoryProvider).deleteAccount();
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
      builder: (sheetCtx) => _RetrainWritingPickerSheet(
        programs: programs,
        onPicked: (mantraId) {
          Navigator.pop(sheetCtx);
          context.push('${KvlRoute.handwritingSubmit}/$mantraId?retrain=1');
        },
      ),
    );
  }
}

class _RetrainWritingPickerSheet extends ConsumerWidget {
  const _RetrainWritingPickerSheet({
    required this.programs,
    required this.onPicked,
  });

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
          Text(
            'Retrain writing for which mantra?',
            style: KvlText.ui(16, FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose from your active programs',
            style: KvlText.caption(12).copyWith(color: KvlColors.muted),
          ),
          const SizedBox(height: 16),
          ...programs.map((p) {
            final mantra = ref.watch(mantraByIdProvider(p.mantraId));
            final name =
                mantra?.name.displayForLanguage(settings.languageCode) ??
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

class _RetrainPickerSheet extends ConsumerWidget {
  const _RetrainPickerSheet({
    required this.programs,
    required this.onPicked,
  });

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
          Text(
            'Retrain voice for which mantra?',
            style: KvlText.ui(16, FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose from your active programs',
            style: KvlText.caption(12).copyWith(color: KvlColors.muted),
          ),
          const SizedBox(height: 16),
          ...programs.map((p) {
            final mantra = ref.watch(mantraByIdProvider(p.mantraId));
            final name = mantra?.name.displayForLanguage(settings.languageCode)
                ?? p.mantraId;
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
// Edit Profile Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileSheet {
  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheetBody(ref: ref),
    );
  }
}

class _EditProfileSheetBody extends ConsumerStatefulWidget {
  const _EditProfileSheetBody({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_EditProfileSheetBody> createState() =>
      _EditProfileSheetBodyState();
}

class _EditProfileSheetBodyState extends ConsumerState<_EditProfileSheetBody> {
  late final TextEditingController _nameCtrl;
  bool _nameBusy = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final session = widget.ref.read(sessionProvider).value;
    _nameCtrl = TextEditingController(text: session?.username ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = context.l10n.nameEmptyError);
      return;
    }
    setState(() { _nameBusy = true; _nameError = null; });
    final res = await ref.read(authRepositoryProvider).updateName(name);
    if (!mounted) return;
    switch (res) {
      case Ok():
        // Also update the "me" profile if present.
        final profile = ref.read(activeProfileProvider).value;
        if (profile != null) {
          await ref.read(profileRepositoryProvider).update(
            profile.copyWith(name: name),
          );
        }
        setState(() => _nameBusy = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.nameUpdatedSuccess),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      case Err(:final failure):
        setState(() { _nameBusy = false; _nameError = failure.message; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;

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
                      Icons.person_outline_rounded,
                      color: KvlColors.primaryDeep,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: KvlSpacing.sm),
                  Expanded(
                    child: Text(context.l10n.editProfileTitle, style: KvlText.title(16)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              const SizedBox(height: KvlSpacing.md),

              // Name field
              KvlInput(
                label: context.l10n.displayNameLabel,
                hint: context.l10n.displayNameHint,
                controller: _nameCtrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveName(),
              ),
              if (_nameError != null) ...[
                const SizedBox(height: KvlSpacing.xs),
                Text(
                  _nameError!,
                  style: KvlText.caption(11).copyWith(color: KvlColors.danger),
                ),
              ],
              const SizedBox(height: KvlSpacing.sm),
              KvlButton(
                label: _nameBusy ? context.l10n.savingNameButton : context.l10n.saveNameButton,
                onPressed: _nameBusy ? null : _saveName,
              ),

              const SizedBox(height: KvlSpacing.lg),
              const Divider(),
              const SizedBox(height: KvlSpacing.sm),

              // Mobile number section
              Row(
                children: [
                  const Icon(
                    Icons.smartphone_rounded,
                    size: 18,
                    color: KvlColors.primaryDeep,
                  ),
                  const SizedBox(width: 8),
                  Text(context.l10n.mobileNumberLabel2, style: KvlText.ui(13, FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                session?.mobile ?? '—',
                style: KvlText.muted(12),
              ),
              const SizedBox(height: KvlSpacing.sm),
              KvlButton(
                variant: KvlButtonVariant.ghost,
                label: context.l10n.changeMobileNumber,
                icon: Icons.edit_rounded,
                onPressed: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _ChangeMobileSheet(parentRef: ref),
                  );
                },
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
