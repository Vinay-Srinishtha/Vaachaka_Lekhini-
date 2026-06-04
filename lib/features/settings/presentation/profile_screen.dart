import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
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
    final programs = ref.watch(programsForActiveProfileProvider).value ?? const [];
    final points = ref.watch(rewardTotalProvider).value ?? 0;
    final settingsRepo = ref.read(settingsRepositoryProvider);

    final totalChants = programs.fold<int>(0, (a, p) => a + p.totalProgress);
    final longestStreak = programs.isEmpty
        ? 0
        : programs.map((p) => p.daysElapsed).reduce((a, b) => a > b ? a : b);

    return KvlScaffold(
      title: 'Profile',
      trailing: TextButton(
        onPressed: () {},
        child: Text('Edit', style: KvlText.ui(12, FontWeight.w600).copyWith(color: KvlColors.primaryDeep)),
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
              child: Text(profile?.initials ?? '?',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 6),
          Center(child: Text(profile?.name ?? session?.username ?? 'Friend', style: KvlText.title(15))),
          if (session != null)
            Center(child: Text(session.mobile, style: KvlText.muted(11))),

          const SizedBox(height: KvlSpacing.md),
          Row(
            children: [
              Expanded(child: _Kpi(value: IndianNumberFormat.compact(totalChants), label: 'Total Chants')),
              const SizedBox(width: 6),
              Expanded(child: _Kpi(value: '$longestStreak', label: 'Current Streak')),
              const SizedBox(width: 6),
              Expanded(child: _Kpi(value: '${programs.where((p) => p.totalProgress > 0).length}/5', label: 'Milestones')),
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
                  decoration: BoxDecoration(color: Colors.white, borderRadius: KvlRadius.brSM),
                  alignment: Alignment.center,
                  child: const Icon(Icons.star_rounded, color: KvlColors.gold, size: 18),
                ),
                const SizedBox(width: KvlSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REWARD POINTS',
                          style: KvlText.caption(10).copyWith(color: const Color(0xFF8a6900), fontWeight: FontWeight.w700)),
                      Text(IndianNumberFormat.format(points),
                          style: KvlText.bigNumber(18).copyWith(color: const Color(0xFF5a4400))),
                    ],
                  ),
                ),
                KvlButton(
                  size: KvlButtonSize.tiny,
                  expand: false,
                  label: 'Visit Store',
                  onPressed: () => context.go(KvlRoute.store),
                ),
              ],
            ),
          ),

          SettingsSection(
            title: 'FAMILY & COMMUNITY',
            children: [
              SettingRow(
                icon: Icons.group_outlined,
                label: 'Family Members',
                onTap: () => context.push(KvlRoute.addFamily),
              ),
              SettingRow(
                icon: Icons.person_add_alt_1_outlined,
                label: 'Invite Friends',
                onTap: () => context.push(KvlRoute.inviteFriends),
              ),
            ],
          ),

          SettingsSection(
            title: 'PRACTICE SETTINGS',
            children: [
              SettingRow(
                icon: Icons.alarm_rounded,
                label: 'Reminder Time',
                value: settings.reminderTime.format(context),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: settings.reminderTime);
                  if (t != null) await settingsRepo.setReminderTime(t);
                },
              ),
              SettingRow(
                icon: Icons.music_note_rounded,
                label: 'Notification Sound',
                value: settings.notificationSound,
                onTap: () => _pickFromList(
                  context,
                  title: 'Notification Sound',
                  options: const ['Bell', 'Conch', 'Bowl', 'Chime', 'None'],
                  current: settings.notificationSound,
                  onPicked: settingsRepo.setNotificationSound,
                ),
              ),
            ],
          ),

          SettingsSection(
            title: 'VOICE SETTINGS',
            children: [
              SettingRow(
                icon: Icons.mic_rounded,
                label: 'Re-train Voice',
                onTap: () {
                  final recent = programs.isEmpty ? null : programs.first.mantraId;
                  if (recent != null) context.push('${KvlRoute.voiceTraining}/$recent');
                },
              ),
              SettingRow(
                icon: Icons.tune_rounded,
                label: 'Microphone Sensitivity',
                value: settings.micSensitivity.label,
                onTap: () => _pickFromList(
                  context,
                  title: 'Microphone Sensitivity',
                  options: MicSensitivity.values.map((m) => m.label).toList(),
                  current: settings.micSensitivity.label,
                  onPicked: (v) async {
                    final next = MicSensitivity.values.firstWhere((m) => m.label == v, orElse: () => MicSensitivity.medium);
                    await settingsRepo.setMicSensitivity(next);
                  },
                ),
              ),
            ],
          ),

          SettingsSection(
            title: 'DISPLAY',
            children: [
              SettingRow(
                icon: Icons.language_rounded,
                label: 'Language',
                value: switch (settings.languageCode) {
                  'hi' => 'हिन्दी',
                  'te' => 'తెలుగు',
                  'kn' => 'ಕನ್ನಡ',
                  _ => 'English',
                },
                onTap: () => _pickFromList(
                  context,
                  title: 'Language',
                  options: const ['English', 'हिन्दी', 'తెలుగు', 'ಕನ್ನಡ'],
                  current: settings.languageCode,
                  onPicked: (label) async {
                    final code = switch (label) {
                      'हिन्दी' => 'hi',
                      'తెలుగు' => 'te',
                      'ಕನ್ನಡ' => 'kn',
                      _ => 'en',
                    };
                    await settingsRepo.setLanguage(code);
                  },
                ),
              ),
              SettingRow(
                icon: Icons.brightness_6_rounded,
                label: 'Theme',
                value: switch (settings.themeMode) {
                  ThemeMode.light => 'Light',
                  ThemeMode.dark => 'Dark',
                  ThemeMode.system => 'System',
                },
                onTap: () => _pickFromList(
                  context,
                  title: 'Theme',
                  options: const ['System', 'Light', 'Dark'],
                  current: switch (settings.themeMode) {
                    ThemeMode.light => 'Light',
                    ThemeMode.dark => 'Dark',
                    ThemeMode.system => 'System',
                  },
                  onPicked: (label) async {
                    await settingsRepo.setThemeMode(switch (label) {
                      'Light' => ThemeMode.light,
                      'Dark' => ThemeMode.dark,
                      _ => ThemeMode.system,
                    });
                  },
                ),
              ),
              SettingRow(
                icon: Icons.text_fields_rounded,
                label: 'Font Size',
                value: settings.fontScale == 1.0
                    ? 'Default'
                    : '${(settings.fontScale * 100).round()}%',
                onTap: () => _pickFromList(
                  context,
                  title: 'Font Size',
                  options: const ['Small (90%)', 'Default (100%)', 'Large (115%)', 'Extra Large (130%)'],
                  current: settings.fontScale == 1.0 ? 'Default (100%)' : null,
                  onPicked: (label) async {
                    final scale = switch (label) {
                      'Small (90%)' => 0.9,
                      'Large (115%)' => 1.15,
                      'Extra Large (130%)' => 1.3,
                      _ => 1.0,
                    };
                    await settingsRepo.setFontScale(scale);
                  },
                ),
              ),
            ],
          ),

          SettingsSection(
            title: 'LINK SOCIAL',
            children: [
              SettingRow(
                icon: Icons.facebook_rounded,
                label: 'Link Facebook',
                trailing: KvlSwitch(value: settings.linkFacebook, onChanged: settingsRepo.setLinkFacebook),
              ),
              SettingRow(
                icon: Icons.chat_bubble_rounded,
                label: 'Link WhatsApp',
                trailing: KvlSwitch(value: settings.linkWhatsApp, onChanged: settingsRepo.setLinkWhatsApp),
              ),
              SettingRow(
                icon: Icons.camera_alt_rounded,
                label: 'Link Instagram',
                trailing: KvlSwitch(value: settings.linkInstagram, onChanged: settingsRepo.setLinkInstagram),
              ),
            ],
          ),

          SettingsSection(
            title: 'SUPPORT & PRIVACY',
            children: [
              SettingRow(icon: Icons.help_outline_rounded, label: 'Help & FAQs', onTap: () => _openInfo(context, 'help')),
              SettingRow(icon: Icons.flag_outlined, label: 'Report Issue', onTap: () => _openInfo(context, 'report')),
              SettingRow(icon: Icons.feedback_outlined, label: 'Share Feedback', onTap: () => _openInfo(context, 'feedback')),
              SettingRow(icon: Icons.lock_outline_rounded, label: 'Privacy Policy', onTap: () => _openInfo(context, 'privacy')),
              SettingRow(
                icon: Icons.cloud_download_outlined,
                label: 'Download Your Data',
                onTap: () => _downloadData(ref),
              ),
              SettingRow(icon: Icons.info_outline_rounded, label: 'About App', onTap: () => _openInfo(context, 'about')),
            ],
          ),

          const SizedBox(height: KvlSpacing.lg),
          KvlButton(
            variant: KvlButtonVariant.outlineDanger,
            label: 'Logout',
            onPressed: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: KvlSpacing.sm),
          KvlButton(
            variant: KvlButtonVariant.danger,
            label: 'Delete Account',
            onPressed: () => _confirmDelete(context, ref),
          ),
          const SizedBox(height: KvlSpacing.sm),
          Center(child: Text('Version 0.1.0', style: KvlText.muted(10))),
        ],
      ),
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
                trailing: o == current ? const Icon(Icons.check_rounded, color: KvlColors.primary) : null,
                onTap: () => Navigator.of(context).pop(o),
              ),
            const SizedBox(height: KvlSpacing.sm),
          ],
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
    final dump = {
      'exportedAt': DateTime.now().toIso8601String(),
      'session': session == null ? null : {'mobile': session.mobile, 'username': session.username, 'language': session.language},
      'profile': profile == null ? null : {'name': profile.name, 'relation': profile.relation.name},
      'settings': {
        'languageCode': settings.languageCode,
        'themeMode': settings.themeMode.name,
        'fontScale': settings.fontScale,
        'reminderTime': '${settings.reminderTime.hour}:${settings.reminderTime.minute}',
        'notificationSound': settings.notificationSound,
        'micSensitivity': settings.micSensitivity.name,
      },
      'programs': [
        for (final p in programs)
          {
            'mantraId': p.mantraId,
            'targetWritings': p.targetWritings,
            'targetDays': p.targetDays,
            'totalChants': p.totalChants,
            'startedAt': p.startedAt.toIso8601String(),
            'status': p.status.name,
          },
      ],
    };
    final text = const JsonEncoder.withIndent('  ').convert(dump);
    await SharePlus.instance.share(ShareParams(text: text, subject: 'KVL data export'));
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Your local data stays on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
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
        title: const Text('Delete account?'),
        content: const Text('This wipes all programs, sessions, rewards, and profiles on this device. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: KvlColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;

    final db = ref.read(appDatabaseProvider);
    await db.delete(db.sessions).go();
    await db.delete(db.programs).go();
    await db.delete(db.rewardEvents).go();
    // Wipe Hive boxes.
    final boxes = [profilesBox(), settingsBox(), cacheBox()];
    for (final b in boxes) {
      await b.clear();
    }
    await ref.read(authRepositoryProvider).logout();
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) {
    return KvlCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: KvlSpacing.sm),
      child: Column(
        children: [
          Text(value, style: KvlText.bigNumber(15)),
          Text(label, style: KvlText.muted(9.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
