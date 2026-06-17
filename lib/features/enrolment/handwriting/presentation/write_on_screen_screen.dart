import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';

import '../../../../app/providers.dart';
import '../../../../app/router.dart';
import '../../../../core/handwriting/handwriting_comparator.dart';
import '../../../../core/i18n/language_options.dart';
import '../../../../core/phone/phone_mode_service.dart';
import '../../../../core/remote_config/remote_config.dart';
import '../../../../core/remote_config/remote_config_keys.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/indian_number_format.dart';
import '../../../practice/application/practice_controller.dart';
import '../../../programs/domain/session.dart';
import '../../../settings/domain/settings_repository.dart';
import '../domain/handwriting_asset.dart';
import '../../../../l10n/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../programs/presentation/daily_progress_screen.dart';

class WriteOnScreenScreen extends ConsumerStatefulWidget {
  const WriteOnScreenScreen({
    super.key,
    required this.mantraId,
    this.programId,
    this.isRetrain = false,
  });

  final String mantraId;
  final String? programId;
  /// When true: after saving, pop back instead of going to setTargetWritings.
  final bool isRetrain;

  @override
  ConsumerState<WriteOnScreenScreen> createState() =>
      _WriteOnScreenScreenState();
}

class _WriteOnScreenScreenState extends ConsumerState<WriteOnScreenScreen> {
  late SignatureController _controller = _newController(KvlColors.ink);

  bool _saving = false;
  bool _checking = false; // true while running handwriting comparison
  Color _penColor = KvlColors.ink;
  int _writingCount = 0;

  /// Language the user chose for this writing session.
  /// null = not yet chosen (picker not completed).
  String? _writingLangCode;

  SignatureController _newController(Color color, {List<Point>? points}) {
    return SignatureController(
      points: points,
      penStrokeWidth: 4,
      penColor: color,
      exportBackgroundColor: Colors.transparent,
    );
  }

  void _setPenColor(Color color) {
    if (_penColor == color) return;
    final points = List<Point>.from(_controller.value);
    final oldController = _controller;
    setState(() {
      _penColor = color;
      _controller = _newController(color, points: points);
    });
    oldController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setScreenOrientation();
    // Auto-open language picker on sample-collection screen (no programId).
    if (widget.programId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showLanguagePicker();
      });
    }
  }

  Future<void> _showLanguagePicker() async {
    final mantra = ref.read(mantraByIdProvider(widget.mantraId));
    final langs = mantra != null
        ? KvlLanguage.availableFor([mantra])
        : KvlLanguage.all;
    final settings = ref.read(settingsProvider).value ?? KvlSettings.fallback;
    final current = _writingLangCode ?? settings.mantraLanguageCode;
    final result = await showModalBottomSheet<String>(
      context: context,
      isDismissible: _writingLangCode != null,
      enableDrag: _writingLangCode != null,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LanguagePickerSheet(
        languages: langs,
        selectedCode: current,
      ),
    );
    if (result != null && mounted) {
      setState(() => _writingLangCode = result);
      await ref.read(settingsRepositoryProvider).setMantraLanguage(result);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _setScreenOrientation() {
    return SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // ── Handwriting validation ─────────────────────────────────────────────────

  /// Called from the SUBMIT button. Fires async validation and stays sync
  /// so it satisfies the VoidCallback contract.
  void _submitOne() {
    if (_controller.isEmpty || _checking) return;
    unawaited(_validateAndSubmit());
  }

  Future<void> _validateAndSubmit() async {
    // Export what the user just wrote
    final png = await _controller.toPngBytes();
    if (png == null) return;

    setState(() => _checking = true);

    try {
      final profile = ref.read(activeProfileProvider).value;
      if (profile == null) {
        setState(() => _checking = false);
        return;
      }

      // Find the most recent enrolled reference for this mantra
      final assets = await ref
          .read(handwritingRepositoryProvider)
          .listForProfile(profile.id);

      final candidates = assets
          .where((a) =>
              a.mantraId == widget.mantraId &&
              a.filePath != null &&
              a.mode != HandwritingMode.useDefaultFont)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // ── No reference sample stored ─────────────────────────────────────────
      if (candidates.isEmpty) {
        if (mounted) _showNoReferenceBanner();
        setState(() => _checking = false);
        return;
      }

      // Reference file might have been deleted (reinstall / storage clear)
      final refFile = File(candidates.first.filePath!);
      if (!refFile.existsSync()) {
        if (mounted) _showNoReferenceBanner();
        setState(() => _checking = false);
        return;
      }

      // ── Pick a random reference from the pool ─────────────────────────────
      final validCandidates = candidates
          .where((a) => File(a.filePath!).existsSync())
          .toList();
      if (validCandidates.isEmpty) {
        if (mounted) _showNoReferenceBanner();
        setState(() => _checking = false);
        return;
      }
      final ref_ = validCandidates[Random().nextInt(validCandidates.length)];
      final refBytes = await File(ref_.filePath!).readAsBytes();
      final score = await HandwritingComparator.compare(png, refBytes);

      // Threshold from RemoteConfig — default 20 (= 20%)
      final cfg = ref.read(remoteConfigProvider).value ?? RemoteConfig.empty;
      final thresholdPct =
          cfg.intFlag(RemoteConfigKeys.minHandwritingAccuracy, fallback: 20);
      final threshold = thresholdPct / 100.0;

      if (score >= threshold) {
        // ── Accept: save immediately into the rolling pool ────────────────────
        await ref
            .read(handwritingRepositoryProvider)
            .savePngCapped(
              profileId: profile.id,
              mantraId: widget.mantraId,
              bytes: png,
            );
        setState(() {
          _writingCount++;
          _checking = false;
        });
        _controller.clear();
        if (mounted) _showAcceptedFeedback(score, threshold);
      } else {
        // ── Reject ───────────────────────────────────────────────────────────
        setState(() => _checking = false);
        if (mounted) _showRejectedFeedback(score, thresholdPct);
      }
    } catch (_) {
      setState(() => _checking = false);
    }
  }

  /// Dismiss any current snackbar then show [snackBar].
  /// Prevents queueing — each new alert instantly replaces the previous one.
  void _showSnack(SnackBar snackBar) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(snackBar);
  }

  /// Shown when no enrolled handwriting sample exists for this mantra.
  void _showNoReferenceBanner() {
    _showSnack(SnackBar(
      duration: const Duration(seconds: 4),
      backgroundColor: KvlColors.danger,
      behavior: SnackBarBehavior.floating,
      content: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No handwriting sample found for this mantra.\n'
              'Please complete handwriting setup first.',
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: '✕',
        textColor: Colors.white,
        onPressed: () => ScaffoldMessenger.of(context).clearSnackBars(),
      ),
    ));
  }

  /// Shown when the writing scores below the acceptance threshold.
  void _showRejectedFeedback(double score, int thresholdPct) {
    final got = (score * 100).toStringAsFixed(0);
    _showSnack(SnackBar(
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.orange.shade700,
      behavior: SnackBarBehavior.floating,
      content: Text(
        'Writing matched $got% — needs $thresholdPct%. Try again.',
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      action: SnackBarAction(
        label: '✕',
        textColor: Colors.white,
        onPressed: () => ScaffoldMessenger.of(context).clearSnackBars(),
      ),
    ));
  }

  /// Brief green toast when a marginal-but-passing score is achieved.
  void _showAcceptedFeedback(double score, double threshold) {
    // No per-stroke snackbar — the session summary shows totals on finish.
  }

  Future<void> _save() async {
    // All accepted writings were already saved via savePngCapped on accept.
    // Only count any drawing still on canvas that hasn't been submitted yet.
    final total = _writingCount + (_controller.isEmpty ? 0 : 1);
    setState(() => _saving = true);
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null) {
      setState(() => _saving = false);
      return;
    }
    // If there's an unsubmitted drawing on canvas, save it too.
    if (_controller.isNotEmpty) {
      final png = await _controller.toPngBytes();
      if (png != null) {
        await ref
            .read(handwritingRepositoryProvider)
            .savePngCapped(
              profileId: profile.id,
              mantraId: widget.mantraId,
              bytes: png,
            );
      }
    }
    if (!mounted) return;
    final programId = widget.programId;
    if (programId != null) {
      final repo = ref.read(programRepositoryProvider);
      final activeProfile = ref.read(activeProfileProvider).value;
      if (total > 0) {
        final session = await repo.startSession(
          programId: programId,
          memberId: activeProfile?.id ?? '',
          modality: SessionModality.handwriting,
        );
        await repo.incrementSession(session.id, by: total);
        await repo.finishSession(session.id);
      }
      if (!mounted) return;
      // Refresh the practice controller so the counter shows updated DB counts.
      await ref.read(practiceControllerProvider(programId).notifier).reloadProgram();
      if (!mounted) return;
      ref.invalidate(globalStatsProvider(widget.mantraId));
      ref.read(sessionCompletedProvider.notifier).increment();
      // Check if target was reached — show dedication dialog before leaving.
      final practiceState = ref
          .read(practiceControllerProvider(programId))
          .value;
      final targetReached = practiceState?.targetReached ?? false;
      if (targetReached && mounted) {
        await _showDedicationDialog(programId);
        return;
      }
      if (!mounted) return;
      // Show session summary snackbar.
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 2500),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF15803D),
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: KvlRadius.brMD),
            content: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 19),
                ),
                const SizedBox(width: KvlSpacing.sm),
                Expanded(
                  child: Text(
                    '${IndianNumberFormat.format(total)} writings completed this session',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KvlText.ui(13, FontWeight.w600)
                        .copyWith(color: Colors.white),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: messenger.clearSnackBars,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        );
      if (!mounted) return;
      context.pop();
      return;
    }
    if (widget.isRetrain) {
      // Pop back through: write screen → submit screen → profile.
      // Two pops: write → submit, submit → profile.
      context.pop();
      if (mounted && context.canPop()) context.pop();
    } else {
      context.push('${KvlRoute.setTargetWritings}/${widget.mantraId}');
    }
  }

  Future<void> _showDedicationDialog(String programId) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DedicationDialog(
        onDedicate: () async {
          Navigator.of(context).pop();
          final mantraId = widget.mantraId;
          ref.invalidate(globalStatsProvider(mantraId));
          final program = ref
              .read(programsForActiveProfileProvider)
              .value
              ?.where((p) => p.id == programId)
              .firstOrNull;
          if (program != null && !program.isCompleted) {
            await ref
                .read(programRepositoryProvider)
                .update(program.copyWith(completedAt: DateTime.now()));
          }
          if (!mounted) return;
          final mantraName =
              ref.read(mantraByIdProvider(mantraId))?.name.devanagari ?? '';
          await DedicateSheet.show(
            context,
            programId: programId,
            mantraName: mantraName,
          );
          if (!mounted) return;
          context.go(KvlRoute.programs);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mantra = ref.watch(mantraByIdProvider(widget.mantraId));
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final effectiveLangCode = _writingLangCode ?? settings.mantraLanguageCode;
    final guide = mantra?.name.displayForLanguage(effectiveLangCode) ?? '';
    final guideScript =
        mantra?.name.scriptForLanguage(effectiveLangCode) ??
        effectiveLangCode.mantraScriptForLanguage;
    if (widget.programId != null) {
      final programs = ref.watch(programsForActiveProfileProvider).value ?? [];
      final progress = programs
          .where((p) => p.id == widget.programId)
          .fold<int>(0, (total, p) => total + p.totalProgress);
      // Real global count: community DB total + unsaved session writings.
      final globalStats = ref.watch(globalStatsProvider(widget.mantraId)).value;
      final globalCount =
          (globalStats?.globalChantCount ?? 0) + _writingCount;
      return _ProtoWriteScaffold(
        controller: _controller,
        guide: guide,
        guideScript: guideScript,
        saving: _saving,
        currentCount: progress,
        globalCount: globalCount,
        writingCount: _writingCount,
        onAdd: _submitOne,
        onFinish: _save,
        onClear: _controller.clear,
        onUndo: _controller.undo,
        onRedo: _controller.redo,
        penColor: _penColor,
        onColorSelected: _setPenColor,
        targetCount: programs
            .where((p) => p.id == widget.programId)
            .fold<int>(0, (_, p) => p.targetWritings),
      );
    }
    final selectedLang = KvlLanguage.byCode(effectiveLangCode);
    return _SampleLandscapeWriteScaffold(
      controller: _controller,
      guide: guide,
      guideScript: guideScript,
      saving: _saving,
      selectedLangLabel: selectedLang.label,
      onPickLanguage: _showLanguagePicker,
      onBack: () => context.canPop() ? context.pop() : context.go('/'),
      onSave: _saving ? null : _save,
      onClear: _controller.clear,
      onUndo: _controller.undo,
      onRedo: _controller.redo,
      penColor: _penColor,
      onColorSelected: _setPenColor,
    );
  }
}

class _SampleLandscapeWriteScaffold extends StatefulWidget {
  const _SampleLandscapeWriteScaffold({
    required this.controller,
    required this.guide,
    required this.guideScript,
    required this.saving,
    required this.selectedLangLabel,
    required this.onPickLanguage,
    required this.onBack,
    required this.onSave,
    required this.onClear,
    required this.onUndo,
    required this.onRedo,
    required this.penColor,
    required this.onColorSelected,
  });

  final SignatureController controller;
  final String guide;
  final MantraScript guideScript;
  final bool saving;
  final String selectedLangLabel;
  final VoidCallback onPickLanguage;
  final VoidCallback onBack;
  final VoidCallback? onSave;
  final VoidCallback onClear;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final Color penColor;
  final ValueChanged<Color> onColorSelected;

  @override
  State<_SampleLandscapeWriteScaffold> createState() =>
      _SampleLandscapeWriteScaffoldState();
}

class _SampleLandscapeWriteScaffoldState
    extends State<_SampleLandscapeWriteScaffold> {
  bool _guideVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KvlColors.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 390;
          final topInset = compact ? 12.0 : 18.0;
          return Stack(
            children: [
              Positioned.fill(
                child: _SampleLandscapeCanvas(
                  controller: widget.controller,
                  guide: widget.guide,
                  guideScript: widget.guideScript,
                  compact: compact,
                  guideVisible: _guideVisible,
                ),
              ),
              Positioned(
                left: 14,
                top: topInset,
                child: IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  iconSize: compact ? 28 : 32,
                  color: KvlColors.ink,
                ),
              ),
              Positioned(
                left: 86,
                right: compact ? 230 : 280,
                top: topInset + 2,
                child: Center(
                  child: Text(
                    context.l10n.writeOnScreenInstruction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KvlText.ui(
                      compact ? 20 : 24,
                      FontWeight.w700,
                    ).copyWith(color: KvlColors.ink),
                  ),
                ),
              ),
              Positioned(
                right: compact ? 12 : 18,
                top: topInset + 2,
                child: _SampleTopTools(
                  saving: widget.saving,
                  compact: compact,
                  onSave: widget.onSave,
                  onPen: widget.onClear,
                  penColor: widget.penColor,
                  onColorSelected: widget.onColorSelected,
                ),
              ),
              // Language chip — bottom left, next to guide toggle
              Positioned(
                left: compact ? 14 : 20,
                bottom: compact ? 12 : 18,
                child: Row(
                  children: [
                    _GuideToggleButton(
                      visible: _guideVisible,
                      compact: compact,
                      onToggle: () => setState(() => _guideVisible = !_guideVisible),
                    ),
                    SizedBox(width: compact ? 8 : 10),
                    GestureDetector(
                      onTap: widget.onPickLanguage,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 10 : 13,
                          vertical: compact ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: KvlColors.primaryGhost,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: KvlColors.primary.withValues(alpha: .35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.language_rounded,
                                size: compact ? 13 : 15,
                                color: KvlColors.primaryDeep),
                            SizedBox(width: compact ? 4 : 5),
                            Text(
                              widget.selectedLangLabel,
                              style: KvlText.ui(compact ? 11 : 12.5, FontWeight.w600)
                                  .copyWith(color: KvlColors.primaryDeep),
                            ),
                            SizedBox(width: compact ? 3 : 4),
                            Icon(Icons.expand_more_rounded,
                                size: compact ? 13 : 15,
                                color: KvlColors.primaryDeep),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: compact ? 16 : 22,
                bottom: compact ? 12 : 18,
                child: Row(
                  children: [
                    _SampleFloatingTool(
                      icon: Icons.cleaning_services_rounded,
                      tooltip: context.l10n.clearTooltip,
                      onTap: widget.onClear,
                    ),
                    SizedBox(width: compact ? 8 : 10),
                    _SampleFloatingTool(
                      icon: Icons.undo_rounded,
                      tooltip: context.l10n.undoTooltip,
                      onTap: widget.onUndo,
                    ),
                    SizedBox(width: compact ? 8 : 10),
                    _SampleFloatingTool(
                      icon: Icons.redo_rounded,
                      tooltip: context.l10n.redoTooltip,
                      onTap: widget.onRedo,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SampleLandscapeCanvas extends StatelessWidget {
  const _SampleLandscapeCanvas({
    required this.controller,
    required this.guide,
    required this.guideScript,
    required this.compact,
    this.guideVisible = true,
  });

  final SignatureController controller;
  final String guide;
  final MantraScript guideScript;
  final bool compact;
  final bool guideVisible;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 210.0 : 250.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (guideVisible)
          Positioned.fill(
            left: compact ? 8 : 12,
            right: compact ? 8 : 12,
            top: compact ? 44 : 54,
            bottom: compact ? 8 : 12,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: compact ? 1060 : 1180,
                  height: compact ? 320 : 340,
                  child: _DottedGuideText(
                    text: guide,
                    script: guideScript,
                    fontSize: size,
                    opacity: .64,
                  ),
                ),
              ),
            ),
          ),
        Signature(controller: controller, backgroundColor: Colors.transparent),
      ],
    );
  }
}

class _SampleTopTools extends StatelessWidget {
  const _SampleTopTools({
    required this.saving,
    required this.compact,
    required this.onSave,
    required this.onPen,
    required this.penColor,
    required this.onColorSelected,
  });

  final bool saving;
  final bool compact;
  final VoidCallback? onSave;
  final VoidCallback onPen;
  final Color penColor;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KvlColors.surface.withValues(alpha: .76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: KvlColors.border.withValues(alpha: .6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 5 : 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SampleToolChip(
              icon: Icons.draw_rounded,
              selected: true,
              compact: compact,
              onTap: onPen,
            ),
            SizedBox(width: compact ? 4 : 6),
            _ColorPaletteButton(
              selectedColor: penColor,
              compact: compact,
              onColorSelected: onColorSelected,
            ),
            SizedBox(width: compact ? 6 : 8),
            _SampleSaveButton(
              label: saving ? context.l10n.savingButton : context.l10n.saveLabel,
              compact: compact,
              onTap: onSave,
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleSaveButton extends StatelessWidget {
  const _SampleSaveButton({
    required this.label,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: compact ? 34 : 38,
        constraints: BoxConstraints(minWidth: compact ? 74 : 88),
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
        decoration: BoxDecoration(
          gradient: onTap == null ? null : KvlColors.primaryGradient,
          color: onTap == null
              ? KvlColors.primary.withValues(alpha: .45)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: KvlColors.primary.withValues(alpha: .22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: KvlText.ui(
            compact ? 13.5 : 15,
            FontWeight.w700,
          ).copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _SampleToolChip extends StatelessWidget {
  const _SampleToolChip({
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 38.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected ? KvlColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? KvlColors.primary.withValues(alpha: .35)
                : KvlColors.border.withValues(alpha: .55),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: compact ? 19 : 21,
          color: selected ? KvlColors.primaryDeep : KvlColors.inkSoft,
        ),
      ),
    );
  }
}

class _ColorPaletteButton extends StatelessWidget {
  const _ColorPaletteButton({
    required this.selectedColor,
    required this.compact,
    required this.onColorSelected,
  });

  static const _colors = <Color>[
    KvlColors.ink,
    KvlColors.primary,
    KvlColors.accent,
    KvlColors.danger,
    Color(0xFF1D4ED8),
    Color(0xFF111827),
  ];

  final Color selectedColor;
  final bool compact;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 42.0;
    return PopupMenuButton<Color>(
      tooltip: context.l10n.penColorTooltip,
      onSelected: onColorSelected,
      color: KvlColors.surface,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: KvlRadius.brMD),
      itemBuilder: (context) => [
        for (final color in _colors)
          PopupMenuItem<Color>(
            value: color,
            height: 42,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: color == selectedColor
                          ? KvlColors.primaryDeep
                          : KvlColors.border,
                      width: color == selectedColor ? 2.2 : 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _labelForColor(color, context),
                  style: KvlText.caption(12).copyWith(color: KvlColors.ink),
                ),
                const Spacer(),
                if (color == selectedColor)
                  const Icon(
                    Icons.check_rounded,
                    color: KvlColors.primaryDeep,
                    size: 18,
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: KvlColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: KvlColors.border.withValues(alpha: .7)),
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.palette_outlined,
              size: compact ? 20 : 25,
              color: KvlColors.ink,
            ),
            Positioned(
              right: compact ? 5 : 6,
              bottom: compact ? 5 : 6,
              child: Container(
                width: compact ? 7 : 8,
                height: compact ? 7 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedColor,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _labelForColor(Color color, BuildContext context) {
    if (color == KvlColors.ink) return context.l10n.penColorBrown;
    if (color == KvlColors.primary) return context.l10n.penColorOrange;
    if (color == KvlColors.accent) return context.l10n.penColorTeal;
    if (color == KvlColors.danger) return context.l10n.penColorRed;
    if (color == const Color(0xFF1D4ED8)) return context.l10n.penColorBlue;
    return context.l10n.penColorBlack;
  }
}

class _SampleFloatingTool extends StatelessWidget {
  const _SampleFloatingTool({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .68),
            shape: BoxShape.circle,
            border: Border.all(color: KvlColors.border.withValues(alpha: .58)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 21, color: KvlColors.ink),
        ),
      ),
    );
  }
}

final _ringerModeProvider = StreamProvider.autoDispose<RingerMode>((ref) {
  return RingerModeService().watch();
});

class _ProtoWriteScaffold extends ConsumerStatefulWidget {
  const _ProtoWriteScaffold({
    required this.controller,
    required this.guide,
    required this.guideScript,
    required this.saving,
    required this.currentCount,
    required this.globalCount,
    required this.writingCount,
    required this.onAdd,
    required this.onFinish,
    required this.onClear,
    required this.onUndo,
    required this.onRedo,
    required this.penColor,
    required this.onColorSelected,
    this.targetCount = 0,
  });

  final SignatureController controller;
  final String guide;
  final MantraScript guideScript;
  final bool saving;
  final int currentCount;
  final int globalCount;
  final int writingCount;
  final VoidCallback onAdd;
  final VoidCallback? onFinish;
  final VoidCallback onClear;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final Color penColor;
  final ValueChanged<Color> onColorSelected;
  final int targetCount;

  @override
  ConsumerState<_ProtoWriteScaffold> createState() => _ProtoWriteScaffoldState();
}

class _ProtoWriteScaffoldState extends ConsumerState<_ProtoWriteScaffold> {
  double _guideScale = 1.0;
  bool _canvasHasContent = false;
  bool _guideVisible = true;

  static const double _scaleMin = 0.5;
  static const double _scaleMax = 2.0;
  static const double _scaleStep = 0.25;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCanvasChanged);
  }

  @override
  void didUpdateWidget(_ProtoWriteScaffold old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onCanvasChanged);
      widget.controller.addListener(_onCanvasChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCanvasChanged);
    super.dispose();
  }

  void _onCanvasChanged() {
    final hasContent = widget.controller.isNotEmpty;
    if (hasContent != _canvasHasContent) {
      setState(() => _canvasHasContent = hasContent);
    }
  }

  void _zoomIn() {
    setState(() {
      _guideScale = (_guideScale + _scaleStep).clamp(_scaleMin, _scaleMax);
    });
  }

  void _zoomOut() {
    setState(() {
      _guideScale = (_guideScale - _scaleStep).clamp(_scaleMin, _scaleMax);
    });
  }

  @override
  Widget build(BuildContext context) {
    final yours = widget.currentCount;
    final globalCount = widget.globalCount;
    final ringerMode =
        ref.watch(_ringerModeProvider).value ?? RingerMode.unknown;
    return Scaffold(
      backgroundColor: KvlColors.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 390;
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final topInset = compact ? 13.0 : 18.0;
          // Bottom button row height so progress bar sits just above it.
          final bottomBtnH = compact ? 60.0 : 72.0;
          final bottomPad = compact ? 8.0 : 14.0;
          return Stack(
            children: [
              Positioned.fill(
                child: _ProtoWritingCanvas(
                  controller: widget.controller,
                  guide: widget.guide,
                  guideScript: widget.guideScript,
                  compact: compact,
                  guideScale: _guideScale,
                  guideVisible: _guideVisible,
                ),
              ),
              // Top-left: Phone Mode + Own writing mode (2 items only)
              Positioned(
                left: compact ? 10 : 16,
                top: topInset,
                child: _LandscapeTopBar(
                  compact: compact,
                  ringerMode: ringerMode,
                  onCycleRinger: () => RingerModeService().cycle(),
                  guideVisible: _guideVisible,
                  onGuideToggle: () =>
                      setState(() => _guideVisible = !_guideVisible),
                ),
              ),
              // Top-center: Global + Yours counter
              Positioned(
                left: 0,
                right: 0,
                top: topInset,
                child: Center(
                  child: _WritingCounts(
                    globalCount: globalCount,
                    yours: yours,
                    increment: widget.writingCount,
                    compact: compact,
                  ),
                ),
              ),
              // Bottom-left: progress bar above ADD button
              Positioned(
                left: compact ? 10 : 16,
                right: compact ? 200 : 240,
                bottom: bottomPad + bottomBtnH + (compact ? 6 : 8),
                child: _WritingProgressBar(
                  currentCount: widget.currentCount + widget.writingCount,
                  targetCount: widget.targetCount,
                  compact: compact,
                ),
              ),
              Positioned(
                left: (w - (compact ? 250 : 280)) / 2,
                bottom: compact ? 8 : 14,
                child: _LandscapeActionButtons(
                  saving: widget.saving,
                  compact: compact,
                  canvasHasContent: _canvasHasContent,
                  onAdd: widget.onAdd,
                  onFinish: widget.onFinish,
                ),
              ),
              Positioned(
                right: compact ? 12 : 18,
                bottom: compact ? 11 : 18,
                child: Row(
                  children: [
                    _ProtoRoundTool(
                      icon: Icons.backspace_rounded,
                      selected: false,
                      onTap: widget.onClear,
                    ),
                    SizedBox(width: compact ? 6 : 10),
                    _ProtoRoundTool(
                      icon: Icons.undo_rounded,
                      selected: false,
                      onTap: widget.onUndo,
                    ),
                    SizedBox(width: compact ? 6 : 10),
                    _ProtoRoundTool(
                      icon: Icons.redo_rounded,
                      selected: false,
                      onTap: widget.onRedo,
                    ),
                    SizedBox(width: compact ? 6 : 10),
                    _ColorPaletteButton(
                      selectedColor: widget.penColor,
                      compact: compact,
                      onColorSelected: widget.onColorSelected,
                    ),
                  ],
                ),
              ),
              Positioned(
                right: compact ? 20 : 30,
                top: h * .38,
                child: _ProtoPlainIcon(
                  icon: Icons.zoom_in_rounded,
                  onTap: _guideScale < _scaleMax ? _zoomIn : null,
                ),
              ),
              Positioned(
                right: compact ? 20 : 30,
                top: h * .57,
                child: _ProtoPlainIcon(
                  icon: Icons.zoom_out_rounded,
                  onTap: _guideScale > _scaleMin ? _zoomOut : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProtoWritingCanvas extends StatelessWidget {
  const _ProtoWritingCanvas({
    required this.controller,
    required this.guide,
    required this.guideScript,
    required this.compact,
    this.guideScale = 1.0,
    this.guideVisible = true,
  });

  final SignatureController controller;
  final String guide;
  final MantraScript guideScript;
  final bool compact;
  final double guideScale;
  final bool guideVisible;

  @override
  Widget build(BuildContext context) {
    final baseSize = compact ? 200.0 : 240.0;
    final size = baseSize * guideScale;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (guideVisible)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: compact ? 1180 : 1320,
                height: compact ? 320 : 340,
                child: _DottedGuideText(
                  text: guide,
                  script: guideScript,
                  fontSize: size,
                  opacity: .66,
                ),
              ),
            ),
          ),
        Signature(controller: controller, backgroundColor: Colors.transparent),
      ],
    );
  }
}

class _DottedGuideText extends StatelessWidget {
  const _DottedGuideText({
    required this.text,
    required this.script,
    required this.fontSize,
    required this.opacity,
  });

  final String text;
  final MantraScript script;
  final double fontSize;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    final escapedText = const HtmlEscape().convert(text);
    final fontFamily = switch (script) {
      MantraScript.latin => 'Lexend, Arial, sans-serif',
      MantraScript.devanagari =>
        'Tiro Devanagari Hindi, Noto Sans Devanagari, serif',
      MantraScript.telugu => 'Tiro Telugu, Noto Sans Telugu, serif',
      MantraScript.kannada => 'Tiro Kannada, Noto Sans Kannada, serif',
    };
    // flutter_svg renders <text> via Flutter's native text engine which
    // ignores stroke-dasharray. Workaround: use a dash <pattern> masked to
    // the text stroke shape — both <mask> and <pattern> on <rect> DO work.
    // Diagonal pill shapes at ~40° create dashes that visually follow curves.
    final svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="340" viewBox="0 0 1400 340">
  <defs>
    <pattern id="dashes" x="0" y="0" width="22" height="14" patternUnits="userSpaceOnUse">
      <rect x="2" y="4" width="16" height="6" rx="3" fill="#25211D" fill-opacity="${(opacity * 1.4).clamp(0.0, 1.0).toStringAsFixed(2)}"/>
    </pattern>
    <mask id="textMask">
      <text x="700" y="260" text-anchor="middle"
        font-family="$fontFamily"
        font-size="$fontSize"
        font-weight="500"
        fill="none"
        stroke="white"
        stroke-width="18">$escapedText</text>
    </mask>
  </defs>
  <rect x="0" y="0" width="1400" height="340" fill="url(#dashes)" mask="url(#textMask)"/>
</svg>
''';
    return SvgPicture.string(svg, fit: BoxFit.contain);
  }
}

class _LandscapeTopBar extends StatelessWidget {
  const _LandscapeTopBar({
    required this.compact,
    required this.ringerMode,
    required this.onCycleRinger,
    required this.guideVisible,
    required this.onGuideToggle,
  });

  final bool compact;
  final RingerMode ringerMode;
  final VoidCallback onCycleRinger;
  final bool guideVisible;
  final VoidCallback onGuideToggle;

  @override
  Widget build(BuildContext context) {
    final double iconSize = compact ? 28 : 32;
    final double labelSize = compact ? 10.5 : 11.5;

    Widget item({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color? iconColor,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: iconColor ?? KvlColors.ink),
            const SizedBox(height: 2),
            Text(
              label,
              style: KvlText.caption(labelSize).copyWith(color: KvlColors.inkSoft),
            ),
          ],
        ),
      );
    }

    final (ringerIcon, ringerLabel) = switch (ringerMode) {
      RingerMode.silent  => (Icons.notifications_off_rounded,    'Silent'),
      RingerMode.vibrate => (Icons.vibration_rounded,             'Vibrate'),
      RingerMode.normal  => (Icons.notifications_active_rounded,  'Ring'),
      RingerMode.unknown => (Icons.notifications_none_rounded,    'Ringer'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        item(icon: ringerIcon, label: ringerLabel, onTap: onCycleRinger),
        const SizedBox(width: 20),
        item(
          icon: guideVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          label: context.l10n.ownWritingModeLabel,
          onTap: onGuideToggle,
          iconColor: guideVisible ? KvlColors.primary : KvlColors.muted,
        ),
      ],
    );
  }
}

class _LandscapeActionButtons extends StatelessWidget {
  const _LandscapeActionButtons({
    required this.saving,
    required this.compact,
    required this.canvasHasContent,
    required this.onAdd,
    required this.onFinish,
  });

  final bool saving;
  final bool compact;
  final bool canvasHasContent;
  final VoidCallback onAdd;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RailButton(
          label: canvasHasContent ? 'SUBMIT' : 'ADD',
          color: canvasHasContent ? KvlColors.primaryDeep : KvlColors.primary,
          compact: compact,
          onTap: canvasHasContent ? onAdd : null,
        ),
        SizedBox(width: compact ? 14 : 20),
        _RailButton(
          label: saving ? context.l10n.savingButton : context.l10n.finishButton,
          color: KvlColors.accent,
          compact: compact,
          onTap: onFinish,
        ),
      ],
    );
  }
}

class _WritingCounts extends StatelessWidget {
  const _WritingCounts({
    required this.globalCount,
    required this.yours,
    required this.increment,
    required this.compact,
  });

  final int globalCount;
  final int yours;
  final int increment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final globalBase = (globalCount - yours).clamp(0, globalCount);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF1E2)],
        ),
        border: Border.all(
          color: KvlColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: KvlColors.primary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.public_rounded,
              size: compact ? 16 : 19,
              color: KvlColors.primaryDeep,
            ),
            const SizedBox(width: 6),
            Text(
              'Global  ',
              style: KvlText.ui(compact ? 13 : 14, FontWeight.w600)
                  .copyWith(color: KvlColors.inkSoft),
            ),
            Text(
              IndianNumberFormat.format(globalBase),
              style: KvlText.ui(compact ? 17 : 20, FontWeight.w800)
                  .copyWith(color: const Color(0xFFCC6A2B)),
            ),
            Text(
              '  +  ',
              style: KvlText.ui(compact ? 17 : 20, FontWeight.w600)
                  .copyWith(color: const Color(0xFF9A8678)),
            ),
            TweenAnimationBuilder<double>(
              key: ValueKey(increment),
              tween: Tween(begin: increment > 0 ? 1.14 : 1.0, end: 1.0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(
                IndianNumberFormat.format(increment),
                style: KvlText.ui(compact ? 17 : 20, FontWeight.w800)
                    .copyWith(color: const Color(0xFF16A34A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.label,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: compact ? 112 : 132,
        height: compact ? 44 : 52,
        decoration: BoxDecoration(
          color: onTap == null ? color.withValues(alpha: .48) : color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .22),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          style: KvlText.ui(
            compact ? 15 : 17,
            FontWeight.w600,
          ).copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _ProtoRoundTool extends StatelessWidget {
  const _ProtoRoundTool({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? KvlColors.primarySoft : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 27, color: KvlColors.ink),
      ),
    );
  }
}

class _ProtoPlainIcon extends StatelessWidget {
  const _ProtoPlainIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(
          icon,
          size: 27,
          color: enabled ? Colors.black : Colors.black26,
        ),
      ),
    );
  }
}

// ── Language picker bottom sheet ───────────────────────────────────────────────

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({
    required this.languages,
    required this.selectedCode,
  });

  final List<KvlLanguage> languages;
  final String selectedCode;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — fixed, never scrolls off screen
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language_rounded,
                          size: 20, color: KvlColors.primaryDeep),
                      const SizedBox(width: 8),
                      Text('Writing language',
                          style: KvlText.ui(15, FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick the script for the tracing guide.',
                    style: KvlText.caption(11.5)
                        .copyWith(color: KvlColors.inkSoft),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Language options — scrollable when height is tight (landscape)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: languages.map((lang) {
                    final selected = lang.code == selectedCode;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(lang.code),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? KvlColors.primaryGhost
                                : KvlColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? KvlColors.primary
                                  : KvlColors.border,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(lang.label,
                                        style: KvlText.ui(13, FontWeight.w600)
                                            .copyWith(
                                          color: selected
                                              ? KvlColors.primaryDeep
                                              : KvlColors.ink,
                                        )),
                                    const SizedBox(width: 8),
                                    Text('·  ${lang.nativeLabel}',
                                        style: KvlText.caption(12).copyWith(
                                          color: selected
                                              ? KvlColors.primary
                                              : KvlColors.inkSoft,
                                        )),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(Icons.check_circle_rounded,
                                    color: KvlColors.primary, size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideToggleButton extends StatelessWidget {
  const _GuideToggleButton({
    required this.visible,
    required this.onToggle,
    this.compact = false,
  });

  final bool visible;
  final VoidCallback onToggle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: visible ? 'Hide guide' : 'Show guide',
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          width: compact ? 36 : 42,
          height: compact ? 36 : 42,
          decoration: BoxDecoration(
            color: visible
                ? KvlColors.primaryGhost
                : KvlColors.surface.withValues(alpha: .9),
            shape: BoxShape.circle,
            border: Border.all(
              color: visible
                  ? KvlColors.primary.withValues(alpha: .4)
                  : KvlColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            visible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            size: compact ? 17 : 20,
            color: visible ? KvlColors.primaryDeep : KvlColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _WritingProgressBar extends StatelessWidget {
  const _WritingProgressBar({
    required this.currentCount,
    required this.targetCount,
    required this.compact,
  });

  final int currentCount;
  final int targetCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (targetCount <= 0) return const SizedBox.shrink();
    final progress = (currentCount / targetCount).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Total Progress',
                maxLines: 1,
                style: KvlText.title(compact ? 11 : 13)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: KvlSpacing.sm),
            Text(
              '${IndianNumberFormat.format(currentCount)} / ${IndianNumberFormat.format(targetCount)}',
              style: KvlText.caption(compact ? 10 : 11)
                  .copyWith(color: KvlColors.inkSoft),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: KvlRadius.brPill,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const height = 9.0;
              final fullWidth = constraints.maxWidth;
              final fillWidth = progress <= 0
                  ? 0.0
                  : (progress * fullWidth).clamp(height, fullWidth);
              return Stack(
                children: [
                  Container(
                    height: height,
                    width: fullWidth,
                    color: KvlColors.primary.withValues(alpha: 0.12),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    height: height,
                    width: fillWidth,
                    decoration: BoxDecoration(
                      borderRadius: KvlRadius.brPill,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFB572),
                          KvlColors.primary,
                          KvlColors.primaryDeep,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: KvlColors.primary.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DedicationDialog extends StatelessWidget {
  const _DedicationDialog({required this.onDedicate});
  final VoidCallback onDedicate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: KvlRadius.brLG),
      child: Padding(
        padding: const EdgeInsets.all(KvlSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFB572), KvlColors.primary],
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.self_improvement_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: KvlSpacing.md),
            Text(
              'Program Complete!',
              style: KvlText.ui(20, FontWeight.w800).copyWith(color: KvlColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KvlSpacing.sm),
            Text(
              'You have completed your sankalpa.\nWould you like to dedicate this practice?',
              style: KvlText.caption(13.5)
                  .copyWith(color: KvlColors.inkSoft, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KvlSpacing.lg),
            KvlButton(label: 'Dedicate & Complete', onPressed: onDedicate),
          ],
        ),
      ),
    );
  }
}
