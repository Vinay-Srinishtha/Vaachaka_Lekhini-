import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/global_sadhana.dart';

class GlobalSadhanaDetailScreen extends ConsumerStatefulWidget {
  const GlobalSadhanaDetailScreen({super.key, required this.sadhanaId});
  final String sadhanaId;

  @override
  ConsumerState<GlobalSadhanaDetailScreen> createState() =>
      _GlobalSadhanaDetailScreenState();
}

class _GlobalSadhanaDetailScreenState
    extends ConsumerState<GlobalSadhanaDetailScreen> {
  bool _enrolling = false;
  bool _startingPractice = false;

  Future<void> _startPractice(GlobalSadhana sadhana) async {
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null) return;
    setState(() => _startingPractice = true);
    try {
      final repo = ref.read(programRepositoryProvider);

      // Always do a fresh DB lookup to avoid race with provider loading state.
      final all = await repo.listForProfile(profile.id);
      final existing = all
          .where((p) => p.mantraId == sadhana.mantraId && !p.isCompleted)
          .toList();

      if (existing.isNotEmpty) {
        if (mounted) context.push('${KvlRoute.practice}/${existing.first.id}');
        return;
      }

      // No personal program — create an open one so the user can set their
      // own goal via "Build Your Program" after the first session.
      final program = await repo.createOpen(
        memberId: profile.id,
        mantraId: sadhana.mantraId,
      );
      ref.invalidate(programsForActiveProfileProvider);
      if (mounted) context.push('${KvlRoute.practice}/${program.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: KvlColors.danger,
          content: Text('Could not start practice. Please try again.',
              style: KvlText.caption(12).copyWith(color: Colors.white)),
        ));
      }
    } finally {
      if (mounted) setState(() => _startingPractice = false);
    }
  }

  Future<void> _enroll(GlobalSadhana sadhana) async {
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null) return;
    setState(() => _enrolling = true);
    try {
      final repo = ref.read(globalSadhanaRepositoryProvider);
      await repo.enroll(
        sadhanaId: sadhana.id,
        memberId: profile.id,
        voiceTrainingComplete: true,
        handwritingTrainingComplete: true,
      );

      if (!mounted) return;
      ref.invalidate(globalSadhanaEnrollmentProvider(sadhana.id));

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KvlColors.primary,
        content: Text(
          'You have joined the Global Sadhana! Your practice now counts toward the global goal.',
          style: KvlText.caption(12).copyWith(color: Colors.white),
        ),
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KvlColors.danger,
        content: Text(
          _enrollErrorMessage(e),
          style: KvlText.caption(12).copyWith(color: Colors.white),
        ),
      ));
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  /// Surface the actual server message where possible so failures are
  /// actionable instead of always reading "Could not join".
  String _enrollErrorMessage(Object e) {
    if (e is DioException) {
      // 401 = session expired / tokens missing. The interceptor logs the user
      // out and the router redirects to login; show a clear message instead of
      // the raw backend "Missing bearer token".
      if (e.response?.statusCode == 401) {
        return 'Your session has expired. Please log in again to join.';
      }
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
    }
    return 'Could not join. Please try again.';
  }

  bool _sharing = false;

  Future<void> _share(GlobalSadhana sadhana) async {
    if (_sharing) return;
    _sharing = true;
    try {
      final appLink = ref.read(appSettingsProvider).value?.effectiveAppLink
          ?? 'https://vaachika-lekhani.vercel.app';
      final msg = '🕉 Join the "${sadhana.title}" Global Sadhana!\n'
          'Together we chant toward ${IndianNumberFormat.format(sadhana.targetCount)} chants.\n'
          'Join me on Vachika Lekhini 🙏\n$appLink';
      final imageUrl = sadhana.imageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final tmpDir = await getTemporaryDirectory();
          final ext = imageUrl.contains('.png') ? 'png' : 'jpg';
          final file = File('${tmpDir.path}/sadhana_share.$ext');
          await Dio().download(imageUrl, file.path);
          await SharePlus.instance.share(ShareParams(
            text: msg,
            files: [XFile(file.path, mimeType: 'image/$ext')],
          ));
          return;
        } catch (_) {}
      }
      await SharePlus.instance.share(ShareParams(text: msg));
    } finally {
      _sharing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sadhanaAsync = ref.watch(globalSadhanaEnrollmentProvider(widget.sadhanaId));
    // Find sadhana from the active list provider.
    final allSadhanas = ref.watch(activeGlobalSadhanaProvider).value ?? [];
    final sadhana = allSadhanas.cast<GlobalSadhana?>().firstWhere(
          (s) => s?.id == widget.sadhanaId,
          orElse: () => null,
        );

    if (sadhana == null) {
      return KvlScaffold(
        title: 'Global Sadhana',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final enrollment = sadhanaAsync.value;
    final isEnrolled = enrollment != null;
    final profile = ref.watch(activeProfileProvider).value;
    final mantra = ref.watch(mantraByIdProvider(sadhana.mantraId));

    return KvlScaffold(
      title: sadhana.title,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner image
          ClipRRect(
            borderRadius: KvlRadius.brLG,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: sadhana.imageUrl != null
                  ? Image.network(
                      sadhana.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _BannerPlaceholder(sadhana: sadhana),
                    )
                  : _BannerPlaceholder(sadhana: sadhana),
            ),
          ),
          const SizedBox(height: KvlSpacing.md),

          // Status pill
          if (sadhana.isCompleted)
            _StatusBanner(
              color: const Color(0xFF6B48FF),
              icon: Icons.check_circle_rounded,
              text: 'This Global Sadhana has been completed. Thank you for your contribution! 🙏',
            )
          else if (sadhana.isPaused)
            _StatusBanner(
              color: const Color(0xFFD97706),
              icon: Icons.pause_circle_outline_rounded,
              text: 'This sadhana is currently paused.',
            ),

          const SizedBox(height: KvlSpacing.sm),

          // Title + mantra chip
          Text(sadhana.title, style: KvlText.title(20)),
          const SizedBox(height: 4),
          if (mantra != null)
            Text(
              mantra.name.roman,
              style: KvlText.caption(13).copyWith(color: KvlColors.inkSoft),
            ),

          const SizedBox(height: KvlSpacing.md),

          // Progress card
          KvlCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Completed',
                        value: IndianNumberFormat.format(sadhana.currentCount),
                        color: KvlColors.primary,
                      ),
                    ),
                    Container(width: 1, height: 40, color: KvlColors.rule),
                    Expanded(
                      child: _StatItem(
                        label: 'Target',
                        value: IndianNumberFormat.format(sadhana.targetCount),
                      ),
                    ),
                    Container(width: 1, height: 40, color: KvlColors.rule),
                    Expanded(
                      child: _StatItem(
                        label: 'Remaining',
                        value: IndianNumberFormat.format(sadhana.remaining),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KvlSpacing.md),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: sadhana.progress,
                    minHeight: 10,
                    backgroundColor: KvlColors.primarySoft,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(KvlColors.primary),
                  ),
                ),
                const SizedBox(height: KvlSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(sadhana.progress * 100).toStringAsFixed(1)}% complete',
                      style: KvlText.caption(11).copyWith(color: KvlColors.inkSoft),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            size: 13, color: KvlColors.inkSoft),
                        const SizedBox(width: 4),
                        Text(
                          '${IndianNumberFormat.format(sadhana.participantCount)} participants',
                          style:
                              KvlText.caption(11).copyWith(color: KvlColors.inkSoft),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Personal contribution (if enrolled)
          if (isEnrolled) ...[
            const SizedBox(height: KvlSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: KvlSpacing.md, vertical: KvlSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    KvlColors.primaryDeep.withValues(alpha: 0.07),
                    KvlColors.primary.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: KvlRadius.brMD,
                border: Border.all(
                    color: KvlColors.primary.withValues(alpha: 0.2)),
              ),
              child: enrollment.myContribution > 0
                  ? Row(
                      children: [
                        const Icon(Icons.volunteer_activism_rounded,
                            color: KvlColors.primary, size: 20),
                        const SizedBox(width: KvlSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your contribution',
                                  style: KvlText.caption(11).copyWith(
                                      color: KvlColors.inkSoft)),
                              Text(
                                IndianNumberFormat.format(
                                    enrollment.myContribution),
                                style: KvlText.ui(16, FontWeight.w800)
                                    .copyWith(color: KvlColors.primaryDeep),
                              ),
                            ],
                          ),
                        ),
                        Text('chants / writings',
                            style: KvlText.caption(11)
                                .copyWith(color: KvlColors.inkSoft)),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: KvlColors.primary, size: 18),
                        const SizedBox(width: KvlSpacing.sm),
                        Expanded(
                          child: Text(
                            'You\'re enrolled! Every chant and writing session automatically counts toward this goal.',
                            style: KvlText.caption(12).copyWith(
                                color: KvlColors.inkSoft, height: 1.4),
                          ),
                        ),
                      ],
                    ),
            ),
          ],

          const SizedBox(height: KvlSpacing.md),

          // Instructions
          if (sadhana.instructions != null &&
              sadhana.instructions!.isNotEmpty) ...[
            Text('Instructions', style: KvlText.title(14)),
            const SizedBox(height: KvlSpacing.xs),
            KvlCard(
              child: Text(
                sadhana.instructions!,
                style: KvlText.caption(13).copyWith(
                  color: KvlColors.ink,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: KvlSpacing.md),
          ],

          // Mode chips
          Wrap(
            spacing: KvlSpacing.xs,
            children: [
              if (sadhana.voiceAllowed)
                _ModeChip(
                  icon: Icons.mic_rounded,
                  label: 'Voice Chanting',
                ),
              if (sadhana.handwritingAllowed)
                _ModeChip(
                  icon: Icons.edit_rounded,
                  label: 'Handwriting',
                ),
            ],
          ),

          const SizedBox(height: KvlSpacing.lg),

          // CTA buttons
          if (sadhana.isCompleted) ...[
            KvlCard(
              child: Text(
                '🙏 This Global Sadhana has been completed. Thank you to all ${IndianNumberFormat.format(sadhana.participantCount)} participants!',
                textAlign: TextAlign.center,
                style: KvlText.caption(13).copyWith(
                  color: KvlColors.inkSoft,
                  height: 1.5,
                ),
              ),
            ),
          ] else if (!isEnrolled && profile != null) ...[
            KvlButton(
              label: _enrolling ? 'Joining…' : '🕉  Join Global Sadhana',
              onPressed: _enrolling || !sadhana.isActive
                  ? null
                  : () => _enroll(sadhana),
            ),
            if (!sadhana.isActive)
              Padding(
                padding: const EdgeInsets.only(top: KvlSpacing.xs),
                child: Text(
                  sadhana.isPaused
                      ? 'Enrollment is paused for this sadhana.'
                      : 'This sadhana is not yet open for enrollment.',
                  textAlign: TextAlign.center,
                  style:
                      KvlText.caption(12).copyWith(color: KvlColors.inkSoft),
                ),
              ),
          ] else if (isEnrolled) ...[
            KvlButton(
              label: _startingPractice ? 'Starting…' : '🧘 Continue Practice',
              onPressed: _startingPractice ? null : () => _startPractice(sadhana),
            ),
          ] else ...[
            KvlButton(
              label: 'Log in to Join',
              onPressed: () => context.go(KvlRoute.welcome),
            ),
          ],

          const SizedBox(height: KvlSpacing.sm),
          KvlButton(
            variant: KvlButtonVariant.ghost,
            label: 'Share this Sadhana',
            icon: Icons.share_rounded,
            onPressed: () => _share(sadhana),
          ),

          const SizedBox(height: KvlSpacing.md),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder({required this.sadhana});
  final GlobalSadhana sadhana;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C42), Color(0xFFE07020)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: KvlRadius.brLG,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.language_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          Text(
            sadhana.title,
            style: KvlText.title(16).copyWith(color: Colors.white),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.text,
  });
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: KvlSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: KvlSpacing.md,
        vertical: KvlSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: KvlRadius.brMD,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: KvlSpacing.sm),
          Expanded(
            child: Text(text,
                style: KvlText.caption(12).copyWith(color: color, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: KvlText.ui(16, FontWeight.w700)
                .copyWith(color: color ?? KvlColors.ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: KvlText.caption(11).copyWith(color: KvlColors.inkSoft),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: KvlColors.primaryGhost,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KvlColors.primarySoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: KvlColors.primaryDeep),
          const SizedBox(width: 5),
          Text(
            label,
            style: KvlText.caption(11.5)
                .copyWith(color: KvlColors.primaryDeep, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

