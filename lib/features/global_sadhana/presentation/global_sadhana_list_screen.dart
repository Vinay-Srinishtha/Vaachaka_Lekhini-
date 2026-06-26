import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../domain/global_sadhana.dart';

class GlobalSadhanaListScreen extends ConsumerStatefulWidget {
  const GlobalSadhanaListScreen({super.key});

  @override
  ConsumerState<GlobalSadhanaListScreen> createState() =>
      _GlobalSadhanaListScreenState();
}

class _GlobalSadhanaListScreenState
    extends ConsumerState<GlobalSadhanaListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(globalSadhanaRepositoryProvider).fetchActive();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sadhanasAsync = ref.watch(activeGlobalSadhanaProvider);
    final enrollments = ref.watch(activeProfileProvider).value;

    return Scaffold(
      backgroundColor: KvlColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                  KvlSpacing.lg, KvlSpacing.lg, KvlSpacing.lg, KvlSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF8EE), Color(0xFFFFF0D6)],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFE88A2E).withValues(alpha: .15),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9A3E), Color(0xFFE07020)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE07020).withValues(alpha: .30),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.public_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Global Sadhana',
                          style: KvlText.ui(20, FontWeight.w800),
                        ),
                        Text(
                          'Collective practice with devotees worldwide',
                          style: KvlText.caption(12)
                              .copyWith(color: KvlColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── List ──────────────────────────────────────────────────────────
            Expanded(
              child: sadhanasAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorView(
                    onRetry: () => ref.refresh(activeGlobalSadhanaProvider)),
                data: (sadhanas) {
                  final active = sadhanas
                      .where((s) => s.isActive)
                      .toList()
                    ..sort((a, b) {
                      if (a.isSponsored != b.isSponsored) {
                        return a.isSponsored ? -1 : 1;
                      }
                      return b.currentCount.compareTo(a.currentCount);
                    });
                  if (active.isEmpty) {
                    return const _EmptyView();
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.refresh(activeGlobalSadhanaProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: KvlSpacing.lg, vertical: KvlSpacing.md),
                      itemCount: active.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: KvlSpacing.md),
                      itemBuilder: (_, i) => _SadhanaCard(
                        sadhana: active[i],
                        memberId: enrollments?.id,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sadhana card
// ─────────────────────────────────────────────────────────────────────────────

class _SadhanaCard extends ConsumerWidget {
  const _SadhanaCard({required this.sadhana, this.memberId});

  final GlobalSadhana sadhana;
  final String? memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentAsync = memberId != null
        ? ref.watch(globalSadhanaEnrollmentProvider(sadhana.id))
        : null;
    final isEnrolled = enrollmentAsync?.value != null;

    return GestureDetector(
      onTap: () => context.push('${KvlRoute.globalSadhana}/${sadhana.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: KvlColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B4513).withValues(alpha: .10),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: .8),
              blurRadius: 0,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image banner ────────────────────────────────────────────────
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: sadhana.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: sadhana.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              _PlaceholderBanner(sadhana: sadhana),
                        )
                      : _PlaceholderBanner(sadhana: sadhana),
                ),
                // Gradient overlay at bottom of image
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: .45),
                        ],
                      ),
                    ),
                  ),
                ),
                // Badges overlay
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    children: [
                      if (sadhana.isSponsored)
                        _Badge(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFE8A020)],
                          ),
                          icon: Icons.star_rounded,
                          label: 'Sponsored',
                        ),
                      if (sadhana.isSponsored && isEnrolled)
                        const SizedBox(width: 6),
                      if (isEnrolled)
                        _Badge(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                          ),
                          icon: Icons.check_circle_rounded,
                          label: 'You\'re in',
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Info ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  KvlSpacing.md, KvlSpacing.md, KvlSpacing.md, KvlSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    sadhana.title,
                    style: KvlText.ui(16, FontWeight.w800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sadhana.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      sadhana.description,
                      style:
                          KvlText.caption(12).copyWith(color: KvlColors.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: KvlSpacing.sm),

                  // Progress bar — gradient fill
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 7,
                      child: Stack(
                        children: [
                          Container(
                            color: KvlColors.primary.withValues(alpha: .12),
                          ),
                          FractionallySizedBox(
                            widthFactor: sadhana.progress.clamp(0.0, 1.0),
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
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
                  const SizedBox(height: 7),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${IndianNumberFormat.format(sadhana.currentCount)} / ${IndianNumberFormat.format(sadhana.targetCount)}',
                          style: KvlText.caption(12)
                              .copyWith(color: KvlColors.muted),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.people_outline_rounded,
                              size: 13, color: KvlColors.muted),
                          const SizedBox(width: 3),
                          Text(
                            '${IndianNumberFormat.format(sadhana.participantCount)} joined',
                            style: KvlText.caption(12)
                                .copyWith(color: KvlColors.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: KvlSpacing.sm),

                  // CTA button
                  isEnrolled
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF16A34A)
                                    .withValues(alpha: .30),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => context.push(
                                  '${KvlRoute.globalSadhana}/${sadhana.id}'),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 13),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'You\'re a Part of This',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9A3E), Color(0xFFE07020)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE07020)
                                    .withValues(alpha: .30),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => context.push(
                                  '${KvlRoute.globalSadhana}/${sadhana.id}'),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 13),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Join Sadhana',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.gradient,
    required this.icon,
    required this.label,
  });
  final LinearGradient gradient;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderBanner extends StatelessWidget {
  const _PlaceholderBanner({required this.sadhana});
  final GlobalSadhana sadhana;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF8C42), Color(0xFFE07020)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.public_rounded, color: Colors.white54, size: 40),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.public_off_rounded,
              size: 52, color: KvlColors.muted),
          const SizedBox(height: 16),
          Text('No active sadhanas right now',
              style: KvlText.ui(15, FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Check back soon',
              style: KvlText.caption(13).copyWith(color: KvlColors.muted)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 44, color: KvlColors.muted),
          const SizedBox(height: 12),
          Text('Could not load sadhanas',
              style: KvlText.ui(14, FontWeight.w600)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
