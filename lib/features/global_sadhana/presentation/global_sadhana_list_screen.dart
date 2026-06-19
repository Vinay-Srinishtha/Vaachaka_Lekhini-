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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KvlSpacing.lg, KvlSpacing.lg, KvlSpacing.lg, KvlSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Global Sadhana',
                          style: KvlText.ui(22, FontWeight.w800),
                        ),
                        Text(
                          'Join a collective practice with devotees worldwide',
                          style: KvlText.caption(13)
                              .copyWith(color: KvlColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: sadhanasAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorView(onRetry: () => ref.refresh(activeGlobalSadhanaProvider)),
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
                          horizontal: KvlSpacing.lg, vertical: KvlSpacing.sm),
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
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image banner
            if (sadhana.imageUrl != null)
              CachedNetworkImage(
                imageUrl: sadhana.imageUrl!,
                height: 140,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _PlaceholderBanner(sadhana: sadhana),
              )
            else
              _PlaceholderBanner(sadhana: sadhana),

            Padding(
              padding: const EdgeInsets.all(KvlSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sponsored badge
                  if (sadhana.isSponsored)
                    Container(
                      margin: const EdgeInsets.only(bottom: KvlSpacing.xs),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: KvlColors.gold.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              size: 12, color: KvlColors.gold),
                          const SizedBox(width: 4),
                          Text(
                            'Sponsored',
                            style: KvlText.caption(11).copyWith(
                                color: KvlColors.gold,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),

                  Text(
                    sadhana.title,
                    style: KvlText.ui(16, FontWeight.w800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sadhana.description,
                    style: KvlText.caption(13)
                        .copyWith(color: KvlColors.muted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KvlSpacing.sm),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: sadhana.progress,
                      minHeight: 6,
                      backgroundColor:
                          KvlColors.primary.withValues(alpha: .12),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(KvlColors.primary),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${IndianNumberFormat.format(sadhana.currentCount)} / ${IndianNumberFormat.format(sadhana.targetCount)} chants',
                          style: KvlText.caption(12)
                              .copyWith(color: KvlColors.muted),
                        ),
                      ),
                      Text(
                        '${sadhana.participantCount} devotees',
                        style: KvlText.caption(12)
                            .copyWith(color: KvlColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: KvlSpacing.md),

                  // Join / Continue button
                  SizedBox(
                    width: double.infinity,
                    child: isEnrolled
                        ? OutlinedButton.icon(
                            onPressed: () => context.push(
                                '${KvlRoute.globalSadhana}/${sadhana.id}'),
                            icon: const Icon(Icons.play_arrow_rounded,
                                size: 18),
                            label: const Text('Continue'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: KvlColors.primary,
                              side: BorderSide(color: KvlColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: () => context.push(
                                '${KvlRoute.globalSadhana}/${sadhana.id}'),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Join Sadhana'),
                            style: FilledButton.styleFrom(
                              backgroundColor: KvlColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
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

class _PlaceholderBanner extends StatelessWidget {
  const _PlaceholderBanner({required this.sadhana});
  final GlobalSadhana sadhana;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [KvlColors.primary, KvlColors.primaryDeep],
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
