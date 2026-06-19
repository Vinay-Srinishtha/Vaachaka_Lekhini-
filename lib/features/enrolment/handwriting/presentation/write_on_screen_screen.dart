import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import '../../../../core/audio/reward_sound_service.dart';
import '../../../enrolment/voice/domain/voice_enrolment.dart';
import '../../../programs/data/writings_pdf_service.dart';
import '../../../programs/presentation/book_preview_sheet.dart';
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
  bool _checking = false;
  Color _penColor = KvlColors.ink;
  int _writingCount = 0;
  Timer? _idleTimer;

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
    _controller.addListener(_onCanvasChanged);
    oldController.dispose();
  }

  // ── Auto-submit idle timer ─────────────────────────────────────────────────

  void _onCanvasChanged() {
    _idleTimer?.cancel();
    if (_controller.isEmpty || _checking || _saving) return;
    _idleTimer = Timer(
      const Duration(milliseconds: 1500),
      _submitOne,
    );
  }

  static const _kWritingLangSet = 'writing_lang_set';

  @override
  void initState() {
    super.initState();
    _setScreenOrientation();
    _controller.addListener(_onCanvasChanged);
    if (widget.programId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (widget.isRetrain) {
          // Retrain flow: always offer language change at the start.
          unawaited(_showLanguagePicker());
        } else {
          final prefs = await SharedPreferences.getInstance();
          final alreadySet = prefs.getBool(_kWritingLangSet) == true;
          if (!alreadySet && mounted) {
            unawaited(_showLanguagePicker(isFirstTime: true));
          }
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_maybeShowWritingTip());
    });
  }

  Future<void> _maybeShowWritingTip() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('tip_writing_v1') == true) return;
    if (!mounted) return;
    var dontShowAgain = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _TipSheet(
        title: 'Writing Tips',
        bullets: const [
          '• Write clearly within the dotted guide area',
          '• Tap ADD after each character to record it',
          '• Tap DONE / Complete Session when finished',
        ],
        initialDontShowAgain: dontShowAgain,
        onChanged: (v) => dontShowAgain = v,
      ),
    );
    if (dontShowAgain) {
      await prefs.setBool('tip_writing_v1', true);
    }
  }

  Future<void> _showLanguagePicker({bool isFirstTime = false}) async {
    final mantra = ref.read(mantraByIdProvider(widget.mantraId));
    final langs = mantra != null
        ? KvlLanguage.availableFor([mantra])
        : KvlLanguage.all;
    final settings = ref.read(settingsProvider).value ?? KvlSettings.fallback;
    final current = _writingLangCode ?? settings.mantraLanguageCode;
    final result = await showModalBottomSheet<String>(
      context: context,
      isDismissible: !isFirstTime,
      enableDrag: !isFirstTime,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LanguagePickerSheet(
        languages: langs,
        selectedCode: current,
        isFirstTime: isFirstTime,
      ),
    );
    if (result != null && mounted) {
      setState(() => _writingLangCode = result);
      await ref.read(settingsRepositoryProvider).setMantraLanguage(result);
      if (isFirstTime) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kWritingLangSet, true);
      }
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
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

  // Minimum match score for any sample (reference or compare phase).
  static const double _minMatchScore = 0.80;

  Future<void> _validateAndSubmit() async {
    final png = await _controller.toPngBytes();
    if (png == null) return;

    setState(() => _checking = true);

    try {
      final profile = ref.read(activeProfileProvider).value;
      if (profile == null) {
        setState(() => _checking = false);
        return;
      }

      final cfg = ref.read(remoteConfigProvider).value ?? RemoteConfig.empty;
      final sampleN = cfg.intFlag(RemoteConfigKeys.handwritingSampleCount, fallback: 3);

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

      final validCandidates = candidates
          .where((a) => File(a.filePath!).existsSync())
          .toList();

      // ── Sampling phase: first N writings become reference samples ──────────
      // The very first sample is accepted automatically (it becomes the reference).
      // Every subsequent reference sample must score ≥ 80 % against the first one.
      if (validCandidates.length < sampleN) {
        if (validCandidates.isEmpty) {
          // First sample — accept unconditionally as the reference baseline.
          await ref.read(handwritingRepositoryProvider).savePng(
            profileId: profile.id,
            mantraId: widget.mantraId,
            bytes: png,
            mode: HandwritingMode.writeOnScreen,
          );
          await _creditHandwritingSample(profile.id);
          final saved = 1;
          setState(() => _checking = false);
          _controller.clear();
          if (mounted) _showSampleSavedFeedback(saved, sampleN);
        } else {
          // Subsequent reference samples — must match the first reference at ≥ 80 %.
          final refBytes = await File(validCandidates.last.filePath!).readAsBytes();
          final score = await HandwritingComparator.compare(png, refBytes);
          if (score >= _minMatchScore) {
            await ref.read(handwritingRepositoryProvider).savePng(
              profileId: profile.id,
              mantraId: widget.mantraId,
              bytes: png,
              mode: HandwritingMode.writeOnScreen,
            );
            await _creditHandwritingSample(profile.id);
            final saved = validCandidates.length + 1;
            setState(() => _checking = false);
            _controller.clear();
            if (mounted) _showSampleSavedFeedback(saved, sampleN);
          } else {
            setState(() => _checking = false);
            if (mounted) _showRejectedFeedback(score, (_minMatchScore * 100).round());
          }
        }
        return;
      }

      // ── Compare phase: score against a random sample from the pool ─────────
      final ref_ = validCandidates[Random().nextInt(validCandidates.length)];
      final refBytes = await File(ref_.filePath!).readAsBytes();
      final score = await HandwritingComparator.compare(png, refBytes);

      if (score >= _minMatchScore) {
        // ── Accept: save immediately into the rolling pool ────────────────────
        await ref
            .read(handwritingRepositoryProvider)
            .savePngCapped(
              profileId: profile.id,
              mantraId: widget.mantraId,
              bytes: png,
            );
        await _creditHandwritingSample(profile.id);
        setState(() {
          _writingCount++;
          _checking = false;
        });
        _controller.clear();
        if (mounted) _showAcceptedFeedback(score, _minMatchScore);
      } else {
        // ── Reject ───────────────────────────────────────────────────────────
        setState(() => _checking = false);
        if (mounted) _showRejectedFeedback(score, (_minMatchScore * 100).round());
      }
    } catch (_) {
      setState(() => _checking = false);
    }
  }

  /// Increments handwritingSamples on the VoiceEnrolment record so that
  /// both voice and handwriting count toward the combined enrollment total.
  Future<void> _creditHandwritingSample(String profileId) async {
    final repo = ref.read(voiceEnrolmentRepositoryProvider);
    final existing = await repo.get(profileId, widget.mantraId);
    final updated = (existing ?? VoiceEnrolment(
      profileId: profileId,
      mantraId: widget.mantraId,
      samples: 0,
      trainedAt: DateTime.now(),
    )).copyWith(
      handwritingSamples: (existing?.handwritingSamples ?? 0) + 1,
    );
    await repo.save(updated);
  }

  /// Dismiss any current snackbar then show [snackBar].
  /// Prevents queueing — each new alert instantly replaces the previous one.
  void _showSnack(SnackBar snackBar) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(snackBar);
  }


  void _showSampleSavedFeedback(int saved, int total) {
    final isDone = saved >= total;
    _showSnack(SnackBar(
      duration: Duration(milliseconds: isDone ? 2500 : 1800),
      backgroundColor: isDone ? const Color(0xFF15803D) : KvlColors.primary,
      behavior: SnackBarBehavior.floating,
      content: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.edit_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isDone
                  ? 'Samples collected! Auto-checking your writing now.'
                  : 'Sample $saved/$total saved — keep writing to build your style.',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
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
      // Rebuild writing book PDF in the background.
      final pdfProfile = ref.read(activeProfileProvider).value;
      if (pdfProfile != null) {
        final allAssets = await ref
            .read(handwritingRepositoryProvider)
            .listForProfile(pdfProfile.id);
        final mantraAssets = allAssets
            .where((a) =>
                a.mantraId == widget.mantraId &&
                a.mode == HandwritingMode.writeOnScreen &&
                a.filePath != null)
            .toList();
        if (mantraAssets.isNotEmpty) {
          final mantra = ref.read(mantraByIdProvider(widget.mantraId));
          unawaited(WritingsPdfService.generate(
            profileId: pdfProfile.id,
            mantraId: widget.mantraId,
            mantraName: mantra?.name.roman ?? widget.mantraId,
            assets: mantraAssets,
          ));
        }
      }
      if (!mounted) return;
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
      context.go(KvlRoute.home);
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
        onSwitchToVoice: widget.programId != null
            ? () => context.go('${KvlRoute.practice}/${widget.programId}')
            : null,
        mantraId: widget.mantraId,
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
      onPickLanguage: () => unawaited(_showLanguagePicker()),
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
  bool _guideVisible = false;

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
    final size = compact ? 200.0 : 240.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (guideVisible)
          Positioned.fill(
            left: compact ? 8 : 12,
            right: compact ? 8 : 12,
            top: compact ? 28 : 36,
            bottom: compact ? 8 : 12,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: compact ? 1060 : 1180,
                  height: compact ? 380 : 420,
                  child: _DottedGuideText(
                    text: guide,
                    script: guideScript,
                    fontSize: size,
                    opacity: .50,
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

// Ambient sound — true = playing.
final _ambientOnProvider =
    NotifierProvider.autoDispose<_AmbientNotifier, bool>(_AmbientNotifier.new);

class _AmbientNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final _ambientPlayerProvider = Provider.autoDispose<AudioPlayer>((ref) {
  final player = AudioPlayer();
  player.setReleaseMode(ReleaseMode.loop);
  ref.onDispose(() {
    player.stop();
    player.dispose();
  });
  return player;
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
    required this.onSwitchToVoice,
    required this.mantraId,
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
  final VoidCallback? onSwitchToVoice;
  final String mantraId;
  final int targetCount;

  @override
  ConsumerState<_ProtoWriteScaffold> createState() => _ProtoWriteScaffoldState();
}

class _ProtoWriteScaffoldState extends ConsumerState<_ProtoWriteScaffold> {
  double _guideScale = 1.0;
  bool _canvasHasContent = false;
  bool _guideVisible = false;

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

          final h = constraints.maxHeight;
          final topInset = compact ? 13.0 : 18.0;
          final bottomStripH = compact ? 28.0 : 32.0;
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
                left: compact ? 18 : 28,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _WritingCounts(
                        globalCount: globalCount,
                        yours: yours,
                        increment: widget.writingCount,
                        compact: compact,
                      ),
                      const SizedBox(height: 6),
                      _PointsBadge(compact: compact),
                    ],
                  ),
                ),
              ),
              // Bottom-left: progress bar above ADD button
              // Top-right: merged SUBMIT / DONE button
              Positioned(
                right: compact ? 10 : 16,
                top: topInset,
                child: _MergedActionButton(
                  saving: widget.saving,
                  canvasHasContent: _canvasHasContent,
                  onTap: _canvasHasContent
                      ? () async {
                          widget.onAdd();
                          await Future.delayed(
                              const Duration(milliseconds: 120));
                          if (mounted) widget.onFinish?.call();
                        }
                      : widget.onFinish,
                  compact: compact,
                ),
              ),
              // Right rail: canvas tools
              Positioned(
                right: compact ? 10 : 16,
                top: h * .22,
                bottom: bottomStripH + (compact ? 6 : 10),
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ProtoPlainIcon(
                      icon: Icons.zoom_in_rounded,
                      onTap: _guideScale < _scaleMax ? _zoomIn : null,
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    _ProtoPlainIcon(
                      icon: Icons.zoom_out_rounded,
                      onTap: _guideScale > _scaleMin ? _zoomOut : null,
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    _ProtoRoundTool(
                      icon: Icons.backspace_rounded,
                      selected: false,
                      onTap: widget.onClear,
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    _ProtoRoundTool(
                      icon: Icons.undo_rounded,
                      selected: false,
                      onTap: widget.onUndo,
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    _ProtoRoundTool(
                      icon: Icons.redo_rounded,
                      selected: false,
                      onTap: widget.onRedo,
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    _ColorPaletteButton(
                      selectedColor: widget.penColor,
                      compact: compact,
                      onColorSelected: widget.onColorSelected,
                    ),
                  ],
                ),
                ),
              ),
              if (widget.onSwitchToVoice != null)
                Positioned(
                  right: compact ? 10 : 16,
                  bottom: bottomStripH + (compact ? 6 : 10),
                  child: GestureDetector(
                    onTap: widget.onSwitchToVoice,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: compact ? 10 : 13,
                          vertical: compact ? 5 : 7),
                      decoration: BoxDecoration(
                        color: KvlColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: KvlColors.border, width: 1.1),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_rounded,
                              size: compact ? 14 : 16,
                              color: KvlColors.accent),
                          const SizedBox(width: 5),
                          Text('Switch to Voice',
                              style: KvlText.ui(
                                      compact ? 11.5 : 12.5, FontWeight.w700)
                                  .copyWith(color: KvlColors.accent)),
                        ],
                      ),
                    ),
                  ),
                ),
              // Bottom-left: Preview My Book
              Positioned(
                left: compact ? 10 : 16,
                bottom: bottomStripH + (compact ? 6 : 10),
                child: BookPreviewButton(
                  compact: compact,
                  mantraId: widget.mantraId,
                ),
              ),
              // Bottom strip: Progress [bar] X/Y
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomStripH,
                child: _ProgressStrip(
                  currentCount: widget.currentCount + widget.writingCount,
                  targetCount: widget.targetCount,
                  compact: compact,
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
                height: compact ? 380 : 420,
                child: _DottedGuideText(
                  text: guide,
                  script: guideScript,
                  fontSize: size,
                  opacity: .50,
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
      MantraScript.telugu => 'Suravaram, Tiro Telugu, Noto Sans Telugu, serif',
      MantraScript.kannada => 'Tiro Kannada, Noto Sans Kannada, serif',
    };
    // flutter_svg ignores stroke-dasharray on <text> but supports <pattern>
    // fills and plain strokes. Strategy:
    //   Layer 1 — very light solid fill: shows the full glyph shape so the
    //             reader can see where each stroke belongs.
    //   Layer 2 — round-dot pattern fill: gives the "dotted guide" feel.
    //   Layer 3 — medium outline stroke: traces the exact glyph boundary,
    //             making every curve and connector clearly legible.
    final dotOpacity  = (opacity * 1.00).clamp(0.0, 1.0).toStringAsFixed(2);
    final fillOpacity = (opacity * 0.14).clamp(0.0, 1.0).toStringAsFixed(2);
    final rimOpacity  = (opacity * 0.70).clamp(0.0, 1.0).toStringAsFixed(2);
    final svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="420" viewBox="0 0 1400 420">
  <defs>
    <pattern id="dots" x="0" y="0" width="20" height="20" patternUnits="userSpaceOnUse">
      <circle cx="10" cy="10" r="5.5" fill="#CC6A2B" fill-opacity="$dotOpacity"/>
    </pattern>
  </defs>
  <!-- layer 1: ghost fill so character shape is always visible -->
  <text x="700" y="320" text-anchor="middle"
    font-family="$fontFamily"
    font-size="$fontSize"
    font-weight="600"
    fill="#CC6A2B"
    fill-opacity="$fillOpacity"
    stroke="none">$escapedText</text>
  <!-- layer 2: round-dot pattern fill -->
  <text x="700" y="320" text-anchor="middle"
    font-family="$fontFamily"
    font-size="$fontSize"
    font-weight="600"
    fill="url(#dots)"
    stroke="none">$escapedText</text>
  <!-- layer 3: crisp outline so every stroke edge is clear -->
  <text x="700" y="320" text-anchor="middle"
    font-family="$fontFamily"
    font-size="$fontSize"
    font-weight="600"
    fill="none"
    stroke="#CC6A2B"
    stroke-opacity="$rimOpacity"
    stroke-width="4"
    stroke-linejoin="round">$escapedText</text>
</svg>
''';
    return SvgPicture.string(svg, fit: BoxFit.contain);
  }
}

class _LandscapeTopBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final double iconSize = compact ? 28 : 32;
    final double labelSize = compact ? 10.5 : 11.5;
    final ambientOn = ref.watch(_ambientOnProvider);

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
          icon: guideVisible ? Icons.edit_rounded : Icons.auto_stories_rounded,
          label: guideVisible ? 'Own Writing' : 'Show Reference',
          onTap: onGuideToggle,
          iconColor: guideVisible ? KvlColors.ink : KvlColors.primary,
        ),
        const SizedBox(width: 20),
        item(
          icon: ambientOn ? Icons.music_note_rounded : Icons.music_off_rounded,
          label: 'Ambient',
          onTap: () async {
            ref.read(_ambientOnProvider.notifier).toggle();
            final isNowOn = ref.read(_ambientOnProvider);
            final player = ref.read(_ambientPlayerProvider);
            if (isNowOn) {
              await player.play(AssetSource('audio/ambient_loop.mp3'));
            } else {
              await player.stop();
            }
          },
          iconColor: ambientOn ? KvlColors.primary : KvlColors.ink,
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

class _PointsBadge extends ConsumerStatefulWidget {
  const _PointsBadge({required this.compact});
  final bool compact;

  @override
  ConsumerState<_PointsBadge> createState() => _PointsBadgeState();
}

class _PointsBadgeState extends ConsumerState<_PointsBadge>
    with SingleTickerProviderStateMixin {
  int? _prev;
  int _delta = 0;
  late final AnimationController _anim;
  late final Animation<double> _offsetAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _offsetAnim = Tween<double>(begin: 0, end: -28).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    _fadeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_anim);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onPoints(int points) {
    if (_prev != null && points > _prev!) {
      setState(() => _delta = points - _prev!);
      _anim.forward(from: 0);
      unawaited(RewardSoundService.instance.playBell());
    }
    _prev = points;
  }

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(rewardTotalProvider).value;
    if (points == null) return const SizedBox.shrink();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onPoints(points);
    });
    final compact = widget.compact;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 13,
            vertical: compact ? 4 : 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF3D8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8C04A), width: 1.1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: compact ? 13 : 15, color: KvlColors.gold),
              const SizedBox(width: 4),
              Text(
                '${IndianNumberFormat.format(points)} pts',
                style: KvlText.ui(compact ? 12 : 13, FontWeight.w700)
                    .copyWith(color: const Color(0xFF5a4400)),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            if (_anim.isDismissed) return const SizedBox.shrink();
            return Positioned(
              top: _offsetAnim.value,
              child: Opacity(opacity: _fadeAnim.value, child: child),
            );
          },
          child: Text(
            '+${IndianNumberFormat.format(_delta)} pts',
            style: KvlText.ui(compact ? 12 : 13, FontWeight.w800)
                .copyWith(color: const Color(0xFF16A34A)),
          ),
        ),
      ],
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
    this.isFirstTime = false,
  });

  final List<KvlLanguage> languages;
  final String selectedCode;
  final bool isFirstTime;

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
                      Expanded(
                        child: Text(
                          isFirstTime
                              ? 'Choose your writing script'
                              : 'Writing language',
                          style: KvlText.ui(15, FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (isFirstTime) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KvlColors.primaryGhost,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: KvlColors.primary.withValues(alpha: .3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This will be your default writing script for all mantras.',
                            style: KvlText.body(12.5).copyWith(
                              color: KvlColors.primaryDeep,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'To change your script later, go to Profile → Retrain Writing and submit 3 new samples.',
                            style: KvlText.caption(11.5)
                                .copyWith(color: KvlColors.inkSoft, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ] else
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
      message: visible ? 'Own Writing Mode' : 'Show Reference',
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          width: compact ? 36 : 42,
          height: compact ? 36 : 42,
          decoration: BoxDecoration(
            color: visible
                ? KvlColors.surface.withValues(alpha: .9)
                : KvlColors.primaryGhost,
            shape: BoxShape.circle,
            border: Border.all(
              color: visible
                  ? KvlColors.border
                  : KvlColors.primary.withValues(alpha: .4),
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
            visible ? Icons.edit_rounded : Icons.auto_stories_rounded,
            size: compact ? 17 : 20,
            color: visible ? KvlColors.inkSoft : KvlColors.primaryDeep,
          ),
        ),
      ),
    );
  }
}

class _MergedActionButton extends StatelessWidget {
  const _MergedActionButton({
    required this.saving,
    required this.canvasHasContent,
    required this.onTap,
    required this.compact,
  });

  final bool saving;
  final bool canvasHasContent;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = canvasHasContent ? 'ADD' : 'Complete Session';
    final icon = canvasHasContent ? Icons.add_rounded : Icons.check_rounded;
    final bgColor =
        canvasHasContent ? KvlColors.primary : const Color(0xFF16A34A);
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 8 : 11,
        ),
        decoration: BoxDecoration(
          color: saving ? KvlColors.muted : bgColor,
          borderRadius: KvlRadius.brPill,
          boxShadow: saving
              ? null
              : [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: compact ? 16 : 18),
                  SizedBox(width: compact ? 4 : 6),
                  Text(
                    label,
                    style: KvlText.ui(compact ? 12 : 14, FontWeight.w800)
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({
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
    final countText =
        '${IndianNumberFormat.format(currentCount)}/${IndianNumberFormat.format(targetCount)}';
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
      child: Row(
        children: [
          Text(
            'Progress',
            style: KvlText.ui(compact ? 9 : 10, FontWeight.w700)
                .copyWith(color: KvlColors.inkSoft),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fullWidth = constraints.maxWidth;
                const height = 6.0;
                final fillWidth = progress <= 0
                    ? 0.0
                    : (progress * fullWidth).clamp(height, fullWidth);
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: height,
                      width: fullWidth,
                      decoration: BoxDecoration(
                        color: KvlColors.primary.withValues(alpha: 0.12),
                        borderRadius: KvlRadius.brPill,
                      ),
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
                            blurRadius: 4,
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
          const SizedBox(width: 8),
          Text(
            countText,
            style: KvlText.ui(compact ? 9 : 10, FontWeight.w700)
                .copyWith(color: KvlColors.ink),
          ),
        ],
      ),
    );
  }
}

/// One-time tip bottom sheet with a "Don't show again" checkbox.
class _TipSheet extends StatefulWidget {
  const _TipSheet({
    required this.title,
    required this.bullets,
    required this.initialDontShowAgain,
    required this.onChanged,
  });

  final String title;
  final List<String> bullets;
  final bool initialDontShowAgain;
  final ValueChanged<bool> onChanged;

  @override
  State<_TipSheet> createState() => _TipSheetState();
}

class _TipSheetState extends State<_TipSheet> {
  late bool _dontShowAgain = widget.initialDontShowAgain;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: KvlColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: KvlColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_rounded,
                    color: KvlColors.primaryDeep, size: 22),
                const SizedBox(width: 8),
                Text(widget.title, style: KvlText.ui(16, FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    b,
                    style: KvlText.body(13.5)
                        .copyWith(height: 1.4, color: KvlColors.inkSoft),
                  ),
                )),
            const SizedBox(height: 6),
            InkWell(
              onTap: () {
                setState(() => _dontShowAgain = !_dontShowAgain);
                widget.onChanged(_dontShowAgain);
              },
              child: Row(
                children: [
                  Checkbox(
                    value: _dontShowAgain,
                    onChanged: (v) {
                      setState(() => _dontShowAgain = v ?? false);
                      widget.onChanged(_dontShowAgain);
                    },
                  ),
                  Text("Don't show again",
                      style: KvlText.body(13).copyWith(color: KvlColors.ink)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: KvlButton(
                label: 'Got it!',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
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
