import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/sharing/share_cache.dart';
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
  String? _cachedImagePath;
  bool _prefetchStarted = false;

  void _prefetchImage(String? url) {
    if (_prefetchStarted || url == null || url.isEmpty) return;
    _prefetchStarted = true;
    cachedShareImagePath(url).then((p) {
      if (mounted) setState(() => _cachedImagePath = p);
    });
  }

  Future<void> _startPractice(GlobalSadhana sadhana) async {
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null) return;
    setState(() => _startingPractice = true);
    try {
      final repo = ref.read(programRepositoryProvider);
      final all = await repo.listForProfile(profile.id);
      final existing = all
          .where((p) => p.mantraId == sadhana.mantraId && !p.isCompleted)
          .toList();

      if (existing.isNotEmpty) {
        if (mounted)
          context.push(
              '${KvlRoute.practice}/${existing.first.id}?global=1');
        return;
      }

      if (mounted) {
        context.push('${KvlRoute.setTargetWritings}/${sadhana.mantraId}');
      }
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

  String _enrollErrorMessage(Object e) {
    if (e is DioException) {
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
      final appLink = ref.read(appSettingsProvider).value?.effectiveAppLink ??
          'https://vaachika-lekhani.vercel.app';
      final current = IndianNumberFormat.format(sadhana.currentCount);
      final target = IndianNumberFormat.format(sadhana.targetCount);
      final msg = '🕉 Join the "${sadhana.title}" Global Sadhana!\n'
          'Together we have chanted $current of $target chants toward the divine goal.\n'
          'Be part of this sacred movement — join me on Vachika Lekhini 🙏\n$appLink';

      final imgPath =
          _cachedImagePath ?? await cachedShareImagePath(sadhana.imageUrl ?? '');
      if (imgPath != null) {
        final ext = imgPath.endsWith('.png') ? 'png' : 'jpg';
        await SharePlus.instance.share(ShareParams(
          text: msg,
          files: [XFile(imgPath, mimeType: 'image/$ext')],
        ));
      } else {
        await SharePlus.instance.share(ShareParams(text: msg));
      }
    } finally {
      _sharing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sadhanaAsync =
        ref.watch(globalSadhanaEnrollmentProvider(widget.sadhanaId));
    final allSadhanas = ref.watch(activeGlobalSadhanaProvider).value ?? [];
    final sadhana = allSadhanas.cast<GlobalSadhana?>().firstWhere(
          (s) => s?.id == widget.sadhanaId,
          orElse: () => null,
        );

    if (sadhana == null) {
      return KvlScaffold(
        title: 'Global Sadhana',
        onBack: () => context.canPop()
            ? context.pop()
            : context.go(KvlRoute.globalSadhanaList),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _prefetchImage(sadhana.imageUrl);

    final enrollment = sadhanaAsync.value;
    final isEnrolled = enrollment != null;
    final profile = ref.watch(activeProfileProvider).value;
    final mantra = ref.watch(mantraByIdProvider(sadhana.mantraId));

    return KvlScaffold(
      title: sadhana.title,
      scrollable: true,
      onBack: () => context.canPop()
          ? context.pop()
          : context.go(KvlRoute.globalSadhanaList),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Banner image ─────────────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: KvlRadius.brLG,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: sadhana.imageUrl != null
                      ? Image.network(
                          sadhana.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _BannerPlaceholder(sadhana: sadhana),
                        )
                      : _BannerPlaceholder(sadhana: sadhana),
                ),
              ),
              // Enrolled badge overlaid on image
              if (isEnrolled)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .20),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'You\'re Part of This',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: KvlSpacing.md),

          // ── Status banners ───────────────────────────────────────────────
          if (sadhana.isCompleted)
            _StatusBanner(
              color: const Color(0xFF6B48FF),
              icon: Icons.check_circle_rounded,
              text:
                  'This Global Sadhana has been completed. Thank you for your contribution! 🙏',
            )
          else if (sadhana.isPaused)
            _StatusBanner(
              color: const Color(0xFFD97706),
              icon: Icons.pause_circle_outline_rounded,
              text: 'This sadhana is currently paused.',
            ),

          const SizedBox(height: KvlSpacing.sm),

          // ── Title ────────────────────────────────────────────────────────
          Text(sadhana.title, style: KvlText.title(20)),
          const SizedBox(height: 4),
          if (mantra != null)
            Text(
              mantra.name.roman,
              style: KvlText.caption(13).copyWith(color: KvlColors.inkSoft),
            ),

          const SizedBox(height: KvlSpacing.md),

          // ── Progress card ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(KvlSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF8EE), Color(0xFFFFF0D6)],
              ),
              borderRadius: KvlRadius.brMD,
              border: Border.all(
                  color: const Color(0xFFE88A2E).withValues(alpha: .25)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE88A2E).withValues(alpha: .10),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _StatTile(
                      label: 'Completed',
                      value:
                          IndianNumberFormat.format(sadhana.currentCount),
                      valueColor: KvlColors.primary,
                    ),
                    Container(
                        width: 1, height: 40, color: const Color(0xFFE88A2E).withValues(alpha: .25)),
                    _StatTile(
                      label: 'Target',
                      value:
                          IndianNumberFormat.format(sadhana.targetCount),
                    ),
                    Container(
                        width: 1, height: 40, color: const Color(0xFFE88A2E).withValues(alpha: .25)),
                    _StatTile(
                      label: 'Remaining',
                      value: IndianNumberFormat.format(sadhana.remaining),
                    ),
                  ],
                ),
                const SizedBox(height: KvlSpacing.md),
                // Gradient progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: Stack(
                      children: [
                        Container(
                            color: KvlColors.primary.withValues(alpha: .15)),
                        FractionallySizedBox(
                          widthFactor: sadhana.progress,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFF9A3E),
                                  Color(0xFFE07020)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: KvlSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(sadhana.progress * 100).toStringAsFixed(1)}% complete',
                      style:
                          KvlText.caption(11).copyWith(color: KvlColors.inkSoft),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            size: 13, color: KvlColors.inkSoft),
                        const SizedBox(width: 4),
                        Text(
                          '${IndianNumberFormat.format(sadhana.participantCount)} participants',
                          style: KvlText.caption(11)
                              .copyWith(color: KvlColors.inkSoft),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Your contribution (if enrolled) ─────────────────────────────
          if (isEnrolled) ...[
            const SizedBox(height: KvlSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: KvlSpacing.md, vertical: KvlSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                ),
                borderRadius: KvlRadius.brMD,
                border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: .30)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: .08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: enrollment.myContribution > 0
                  ? Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF22C55E),
                                Color(0xFF16A34A)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.volunteer_activism_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: KvlSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your contribution',
                                  style: KvlText.caption(11)
                                      .copyWith(color: const Color(0xFF166534))),
                              Text(
                                '${IndianNumberFormat.format(enrollment.myContribution)} chants',
                                style: KvlText.ui(17, FontWeight.w800)
                                    .copyWith(color: const Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.favorite_rounded,
                            color: Color(0xFF22C55E), size: 20),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Color(0xFF22C55E), size: 20),
                        const SizedBox(width: KvlSpacing.sm),
                        Expanded(
                          child: Text(
                            'You\'re in! Every chant and writing session automatically counts toward this goal.',
                            style: KvlText.caption(12).copyWith(
                                color: const Color(0xFF166534), height: 1.4),
                          ),
                        ),
                      ],
                    ),
            ),
          ],

          const SizedBox(height: KvlSpacing.md),

          // ── Instructions ─────────────────────────────────────────────────
          if (sadhana.instructions != null &&
              sadhana.instructions!.isNotEmpty) ...[
            Text('Instructions', style: KvlText.title(14)),
            const SizedBox(height: KvlSpacing.xs),
            Container(
              padding: const EdgeInsets.all(KvlSpacing.md),
              decoration: BoxDecoration(
                color: KvlColors.surface,
                borderRadius: KvlRadius.brMD,
                border: Border.all(color: KvlColors.rule),
              ),
              child: Text(
                sadhana.instructions!,
                style: KvlText.caption(13).copyWith(
                  color: KvlColors.ink,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: KvlSpacing.lg),
          ],

          // ── CTA buttons ──────────────────────────────────────────────────
          if (sadhana.isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(KvlSpacing.md),
              decoration: BoxDecoration(
                color: KvlColors.surface,
                borderRadius: KvlRadius.brMD,
                border: Border.all(color: KvlColors.rule),
              ),
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
                  style: KvlText.caption(12)
                      .copyWith(color: KvlColors.inkSoft),
                ),
              ),
          ] else if (isEnrolled) ...[
            // Premium gradient Continue Practice button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9A3E), Color(0xFFE07020)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE07020).withValues(alpha: .35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _startingPractice
                      ? null
                      : () => _startPractice(sadhana),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🧘', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          _startingPractice
                              ? 'Starting…'
                              : 'Continue Practice',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                style:
                    KvlText.caption(12).copyWith(color: color, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.sm),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: KvlText.ui(16, FontWeight.w700)
                    .copyWith(color: valueColor ?? KvlColors.ink),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style:
                  KvlText.caption(11).copyWith(color: KvlColors.inkSoft),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
