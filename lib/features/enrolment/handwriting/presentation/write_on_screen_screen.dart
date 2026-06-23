import 'dart:async';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/providers.dart';
import '../../../../app/router.dart';
import '../../../../core/handwriting/handwriting_recognizer.dart';
import '../../../../core/i18n/language_options.dart';
import '../../../../core/phone/phone_mode_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/indian_number_format.dart';
import '../../../practice/application/practice_controller.dart';
import '../../../programs/domain/session.dart';
import '../../../settings/domain/settings_repository.dart';
import '../domain/handwriting_asset.dart';
import '../../../../l10n/l10n.dart';
import '../../../../core/widgets/kvl_toast.dart';
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
      const Duration(milliseconds: 900),
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
    KvlToast.show(
      context,
      'Write clearly in the guide area — each writing is accepted automatically',
      icon: Icons.edit_note_rounded,
      iconColor: KvlColors.primary,
      duration: const Duration(seconds: 4),
    );
    await prefs.setBool('tip_writing_v1', true);
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

  /// Tesseract language code for an app language code.
  static String _tessLang(String code) => switch (code) {
        'hi' => 'hin',
        'te' => 'tel',
        'kn' => 'kan',
        _ => 'eng',
      };

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

      final mantra = ref.read(mantraByIdProvider(widget.mantraId));
      if (mantra == null) {
        setState(() => _checking = false);
        return;
      }
      final settings =
          ref.read(settingsProvider).value ?? KvlSettings.fallback;
      final langCode = _writingLangCode ?? settings.mantraLanguageCode;

      // Verify offline (bundled Tesseract): accept only if the writing reads as
      // the expected mantra in its native script OR as the roman spelling.
      final candidates = <ExpectedWriting>[
        ExpectedWriting(
          tessLang: _tessLang(langCode),
          text: mantra.name.displayForLanguage(langCode),
        ),
        if (langCode != 'en')
          ExpectedWriting(tessLang: 'eng', text: mantra.name.roman),
      ];
      final result = await HandwritingRecognizer.instance.check(
        pngBytes: png,
        candidates: candidates,
      );

      if (!result.accepted) {
        setState(() => _checking = false);
        if (mounted) _showRejectedFeedback(result);
        return;
      }

      // Accepted — save into the rolling pool (keeps the writing book/PDF
      // working) and count it.
      await ref.read(handwritingRepositoryProvider).savePngCapped(
            profileId: profile.id,
            mantraId: widget.mantraId,
            bytes: png,
          );
      // Invalidate book provider immediately so the count pill and book sheet
      // reflect the new writing without waiting for session completion.
      ref.invalidate(bookAssetsProvider(widget.mantraId));
      await _creditHandwritingSample(profile.id);
      setState(() {
        _writingCount++;
        _checking = false;
      });
      _controller.clear();
    } catch (_) {
      setState(() => _checking = false);
    }
  }

  /// Shown when the writing doesn't read as the expected mantra.
  void _showRejectedFeedback(HandwritingResult result) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.orange.shade700,
      behavior: SnackBarBehavior.floating,
      content: Text(
        result.recognized.trim().isEmpty
            ? "Couldn't read that — write the mantra clearly and try again."
            : 'That looked like "${result.recognized.trim()}". Write the mantra and try again.',
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      action: SnackBarAction(
        label: '✕',
        textColor: Colors.white,
        onPressed: messenger.clearSnackBars,
      ),
    ));
  }

  /// Increments handwritingSamples on the VoiceEnrolment record so that
  /// both voice and handwriting count toward the combined enrollment total.
  Future<void> _creditHandwritingSample(String profileId) async {
    final repo = ref.read(voiceEnrolmentRepositoryProvider);
    final existing = await repo.get(profileId, widget.mantraId);
    final langCode = _writingLangCode ??
        (ref.read(settingsProvider).value?.mantraLanguageCode ?? 'hi');
    final updated = (existing ??
            VoiceEnrolment(
              profileId: profileId,
              mantraId: widget.mantraId,
              samples: 0,
              trainedAt: DateTime.now(),
            ))
        .copyWith(
      handwritingSamples: (existing?.handwritingSamples ?? 0) + 1,
      trainedLanguageCode: langCode,
    );
    await repo.save(updated);
  }

  Future<void> _save() async {
    // No manual ADD: if there's still ink on the canvas, run it through the
    // same automatic recognition first — it only counts if it passes.
    if (_controller.isNotEmpty && !_checking) {
      await _validateAndSubmit();
    }
    if (!mounted) return;
    // All counted writings were already saved via savePngCapped on accept.
    final total = _writingCount;
    setState(() => _saving = true);
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null) {
      setState(() => _saving = false);
      return;
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
      // Optimistically credit any enrolled global sadhana for this mantra so
      // the count/percentage/contribution update instantly.
      if (total > 0) {
        final bumped = await ref
            .read(globalSadhanaRepositoryProvider)
            .applyLocalContribution(mantraId: widget.mantraId, count: total);
        if (bumped && mounted) {
          ref.invalidate(activeGlobalSadhanaProvider);
          ref.invalidate(globalSadhanaEnrollmentProvider);
        }
      }
      if (!mounted) return;
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
      // Skip the goal screen — start practising right away. The target (if
      // any) is set on Finish; otherwise it stays a Bonus Chants bucket.
      final repo = ref.read(programRepositoryProvider);
      final program = await repo.createOpen(
        memberId: profile.id,
        mantraId: widget.mantraId,
      );
      // Roll the writings done during enrolment into this program so they
      // count toward the program/bonus and the global tally.
      if (total > 0) {
        final session = await repo.startSession(
          programId: program.id,
          memberId: profile.id,
          modality: SessionModality.handwriting,
        );
        await repo.incrementSession(session.id, by: total);
        await repo.finishSession(session.id);
        final bumped = await ref
            .read(globalSadhanaRepositoryProvider)
            .applyLocalContribution(mantraId: widget.mantraId, count: total);
        if (bumped && mounted) {
          ref.invalidate(activeGlobalSadhanaProvider);
          ref.invalidate(globalSadhanaEnrollmentProvider);
        }
      }
      if (!mounted) return;
      context.go('${KvlRoute.practice}/${program.id}');
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
      // If enrolled in an active Global Sadhana for this mantra, show that
      // programme's live progress; otherwise fall back to the community total.
      final globalStats = ref.watch(globalStatsProvider(widget.mantraId)).value;
      final sadhanas = ref.watch(activeGlobalSadhanaProvider).value ?? const [];
      final gsRepo = ref.read(globalSadhanaRepositoryProvider);
      int? enrolledGlobalCount;
      for (final gs in sadhanas) {
        if (gs.mantraId == widget.mantraId &&
            gsRepo.cachedEnrollment(gs.id) != null) {
          enrolledGlobalCount = gs.currentCount;
          break;
        }
      }
      final globalBase =
          enrolledGlobalCount ?? (globalStats?.globalChantCount ?? 0);
      final globalCount = globalBase + _writingCount;
      return _ProtoWriteScaffold(
        controller: _controller,
        guide: guide,
        guideScript: guideScript,
        saving: _saving,
        currentCount: progress,
        globalCount: globalCount,
        writingCount: _writingCount,
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
        selectedLangLabel: KvlLanguage.byCode(effectiveLangCode).label,
        onPickLanguage: () => unawaited(_showLanguagePicker()),
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
  // Keep alive across reads — otherwise the autoDispose provider tears down
  // right after the tap (it's only read, never watched) and playback stops.
  ref.keepAlive();
  final player = AudioPlayer();
  player.setReleaseMode(ReleaseMode.loop);
  player.setVolume(0.5); // 50% background — never overpowers the practice
  // Mix with any mic capture instead of grabbing audio focus.
  player.setAudioContext(AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playAndRecord,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  ));
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
    required this.onFinish,
    required this.onClear,
    required this.onUndo,
    required this.onRedo,
    required this.penColor,
    required this.onColorSelected,
    required this.onSwitchToVoice,
    required this.mantraId,
    required this.selectedLangLabel,
    required this.onPickLanguage,
    this.targetCount = 0,
  });

  final SignatureController controller;
  final String guide;
  final MantraScript guideScript;
  final bool saving;
  final int currentCount;
  final int globalCount;
  final int writingCount;
  final VoidCallback? onFinish;
  final VoidCallback onClear;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final Color penColor;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback? onSwitchToVoice;
  final String mantraId;
  final String selectedLangLabel;
  final VoidCallback onPickLanguage;
  final int targetCount;

  @override
  ConsumerState<_ProtoWriteScaffold> createState() => _ProtoWriteScaffoldState();
}

class _ProtoWriteScaffoldState extends ConsumerState<_ProtoWriteScaffold> {
  double _guideScale = 1.0;
  bool _guideVisible = true;
  AudioPlayer? _ambientPlayer;

  static const double _scaleMin = 0.5;
  static const double _scaleMax = 2.0;
  static const double _scaleStep = 0.25;

  @override
  void initState() {
    super.initState();
    _ambientPlayer = ref.read(_ambientPlayerProvider);
  }

  @override
  void dispose() {
    _ambientPlayer?.stop(); // don't let ambient bleed into other screens
    super.dispose();
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
              // Top: unified bar — tools + info pills + palette all inline
              Positioned(
                left: compact ? 8 : 12,
                right: compact ? 60 : 70,
                top: topInset,
                child: _LandscapeTopBar(
                  compact: compact,
                  ringerMode: ringerMode,
                  onCycleRinger: () => RingerModeService().cycle(),
                  guideVisible: _guideVisible,
                  onGuideToggle: () =>
                      setState(() => _guideVisible = !_guideVisible),
                  selectedLangLabel: widget.selectedLangLabel,
                  onPickLanguage: widget.onPickLanguage,
                  onSwitchToVoice: widget.onSwitchToVoice,
                  penColor: widget.penColor,
                  onColorSelected: widget.onColorSelected,
                  globalCount: globalCount,
                  yours: yours,
                  increment: widget.writingCount,
                  mantraId: widget.mantraId,
                ),
              ),
              // Bottom-right: Complete button
              Positioned(
                right: compact ? 10 : 16,
                bottom: bottomStripH + (compact ? 6 : 10),
                child: _MergedActionButton(
                  saving: widget.saving,
                  onTap: widget.onFinish,
                  compact: compact,
                ),
              ),
              // Right rail: canvas tools — start just below top bar
              Positioned(
                right: compact ? 10 : 16,
                top: topInset,
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
                  ],
                ),
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
    // Scale the entire canvas (guide + ink) together so strokes stay in sync
    // with the reference when the user zooms in or out.
    return ClipRect(
      child: Transform.scale(
        scale: guideScale,
        alignment: Alignment.center,
        child: Stack(
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
                      fontSize: baseSize,
                      opacity: .50,
                    ),
                  ),
                ),
              ),
            Signature(controller: controller, backgroundColor: Colors.transparent),
          ],
        ),
      ),
    );
  }
}

// ── Dotted-boundary tracing guide ────────────────────────────────────────────
// Strategy: render the text with the real font to an offscreen image at ¼ scale,
// scan boundary pixels (glyph edge ↔ transparent), place a dot per cell.
// Result: dots follow actual glyph curves — no SVG, no separate shapes.

bool _suravaramFontLoaded = false;

class _DottedGuideText extends StatefulWidget {
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
  State<_DottedGuideText> createState() => _DottedGuideTextState();
}

class _DottedGuideTextState extends State<_DottedGuideText> {
  List<Offset>? _dots;
  bool _computing = false;
  // Cache the key used to compute current _dots so we can detect changes.
  String _computedKey = '';

  @override
  void didUpdateWidget(_DottedGuideText old) {
    super.didUpdateWidget(old);
    // If text or script changed, discard cached dots and recompute.
    if (old.text != widget.text || old.script != widget.script) {
      _dots = null;
      _computing = false;
      _computedKey = '';
    }
  }

  Future<void> _compute(double canvasW, double canvasH) async {
    if (_computing) return;
    _computing = true;

    // Ensure Suravaram asset font is registered in the Flutter engine.
    if (widget.script == MantraScript.telugu && !_suravaramFontLoaded) {
      final data = await rootBundle.load('assets/fonts/Suravaram-Regular.ttf');
      final loader = FontLoader('Suravaram')..addFont(Future.value(data));
      await loader.load();
      _suravaramFontLoaded = true;
      await Future.delayed(Duration.zero);
    }

    // Render at ½ scale using the exact same font as the app's mantra display.
    const scale = 0.5;
    final scaledFontSize = widget.fontSize * scale;
    final scaledW = (canvasW * scale).ceil();
    final scaledH = (canvasH * scale).ceil();

    // KvlText.mantraByScript gives the identical TextStyle the UI uses.
    final baseStyle = KvlText.mantraByScript(widget.script, scaledFontSize)
        .copyWith(color: Colors.black, fontWeight: FontWeight.w700);

    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: baseStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: canvasW * scale);

    // Centre text in scaled canvas.
    final tx = ((scaledW - tp.width) / 2).roundToDouble();
    final ty = ((scaledH - tp.height) / 2).roundToDouble();

    final recorder = ui.PictureRecorder();
    tp.paint(Canvas(recorder), Offset(tx, ty));
    final img = await recorder.endRecording().toImage(scaledW, scaledH);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();

    if (byteData == null || !mounted) { _computing = false; return; }

    // 3. Boundary scan: pixel is a boundary if it has alpha AND a transparent
    //    neighbour. Subsample into cells so dots are evenly spaced.
    const cellSize = 3; // px at ½ scale → ~6 px spacing at full scale = tighter dots
    const alphaThr = 30;
    final cells = <String>{};
    final dots = <Offset>[];

    for (var y = 0; y < scaledH; y++) {
      for (var x = 0; x < scaledW; x++) {
        final idx = (y * scaledW + x) * 4;
        if (byteData.getUint8(idx + 3) <= alphaThr) continue;

        // Check 8-connected neighbours.
        bool boundary = false;
        outer:
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final nx = x + dx;
            final ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= scaledW || ny >= scaledH) {
              boundary = true; break outer;
            }
            if (byteData.getUint8((ny * scaledW + nx) * 4 + 3) <= alphaThr) {
              boundary = true; break outer;
            }
          }
        }
        if (!boundary) continue;

        // One dot per grid cell to avoid dense overlap.
        final key = '${x ~/ cellSize},${y ~/ cellSize}';
        if (cells.add(key)) {
          // Convert from scaled → full-canvas coordinates.
          dots.add(Offset((x + 0.5) / scale, (y + 0.5) / scale));
        }
      }
    }

    _dots = dots;
    _computing = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.trim().isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      if (_dots == null && !_computing) _compute(w, h);
      if (_dots == null) return const SizedBox.shrink();
      return CustomPaint(
        painter: _BoundaryDotsPainter(dots: _dots!, opacity: widget.opacity),
      );
    });
  }
}

class _BoundaryDotsPainter extends CustomPainter {
  const _BoundaryDotsPainter({required this.dots, required this.opacity});
  final List<Offset> dots;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF888888).withValues(alpha: (opacity * 0.65).clamp(0, 1))
      ..style = PaintingStyle.fill;
    for (final dot in dots) {
      canvas.drawCircle(dot, 2.2, paint);
    }
  }

  @override
  bool shouldRepaint(_BoundaryDotsPainter old) =>
      old.opacity != opacity || old.dots != dots;
}

class _LandscapeTopBar extends ConsumerWidget {
  const _LandscapeTopBar({
    required this.compact,
    required this.ringerMode,
    required this.onCycleRinger,
    required this.guideVisible,
    required this.onGuideToggle,
    required this.selectedLangLabel,
    required this.onPickLanguage,
    required this.penColor,
    required this.onColorSelected,
    required this.globalCount,
    required this.yours,
    required this.increment,
    required this.mantraId,
    this.onSwitchToVoice,
  });

  final bool compact;
  final RingerMode ringerMode;
  final VoidCallback onCycleRinger;
  final bool guideVisible;
  final VoidCallback onGuideToggle;
  final String selectedLangLabel;
  final VoidCallback onPickLanguage;
  final Color penColor;
  final ValueChanged<Color> onColorSelected;
  final int globalCount;
  final int yours;
  final int increment;
  final String mantraId;
  final VoidCallback? onSwitchToVoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double iconSize = compact ? 26 : 28;
    final double labelSize = compact ? 10.0 : 11.0;
    final double pillFs = compact ? 12.5 : 13.5;
    final double pillIconSz = compact ? 13.0 : 15.0;
    final double gap = compact ? 14.0 : 18.0;
    final ambientOn = ref.watch(_ambientOnProvider);
    final points = ref.watch(rewardTotalProvider).value ?? 0;
    final bookCount = ref.watch(bookAssetsProvider(mantraId)).value?.length ?? 0;
    final globalBase = (globalCount - yours).clamp(0, globalCount);

    // Uniform icon+label button
    Widget btn({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color? iconColor,
      Widget? customIcon,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            customIcon ?? Icon(icon, size: iconSize, color: iconColor ?? KvlColors.ink),
            const SizedBox(height: 2),
            Text(label, style: KvlText.caption(labelSize).copyWith(color: KvlColors.inkSoft)),
          ],
        ),
      );
    }

    // Uniform pill widget
    Widget pill({required Widget child, Color bg = Colors.white, Color? border, VoidCallback? onTap}) {
      final w = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border ?? KvlColors.border, width: 1.1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: child,
      );
      if (onTap != null) return GestureDetector(onTap: onTap, child: w);
      return w;
    }

    // Divider between sections
    Widget divider() => Container(
      width: 1, height: compact ? 36 : 42,
      margin: EdgeInsets.symmetric(horizontal: gap * 0.6),
      color: KvlColors.border,
    );

    final (ringerIcon, ringerLabel) = switch (ringerMode) {
      RingerMode.silent  => (Icons.notifications_off_rounded, 'Silent'),
      RingerMode.vibrate => (Icons.vibration_rounded,          'Vibrate'),
      RingerMode.normal  => (Icons.notifications_active_rounded, 'Ring'),
      RingerMode.unknown => (Icons.notifications_none_rounded,   'Ringer'),
    };

    // Color palette as icon+label button
    final paletteBtn = btn(
      icon: Icons.palette_rounded,
      label: 'Colour',
      iconColor: penColor,
      onTap: () {
        showDialog<Color>(
          context: context,
          builder: (_) => _ColorPickerDialog(selectedColor: penColor),
        ).then((c) { if (c != null) onColorSelected(c); });
      },
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6, vertical: compact ? 4 : 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Tool buttons ──────────────────────────────────────────────
          btn(icon: ringerIcon, label: ringerLabel, onTap: onCycleRinger),
          SizedBox(width: gap),
          btn(
            icon: guideVisible ? Icons.auto_stories_rounded : Icons.edit_rounded,
            label: guideVisible ? 'Hide Ref' : 'Show Ref',
            onTap: onGuideToggle,
            iconColor: guideVisible ? KvlColors.primary : KvlColors.ink,
          ),
          SizedBox(width: gap),
          btn(
            icon: ambientOn ? Icons.music_note_rounded : Icons.music_off_rounded,
            label: 'Ambient',
            iconColor: ambientOn ? KvlColors.primary : KvlColors.ink,
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
          ),
          SizedBox(width: gap),
          btn(icon: Icons.translate_rounded, label: selectedLangLabel, onTap: onPickLanguage, iconColor: KvlColors.primaryDeep),
          if (onSwitchToVoice != null) ...[
            SizedBox(width: gap),
            btn(icon: Icons.mic_rounded, label: 'Voice Mode', onTap: onSwitchToVoice!, iconColor: KvlColors.accent),
          ],
          SizedBox(width: gap),
          paletteBtn,

          divider(),

          // ── Info pills — same height, inline ─────────────────────────
          // Global
          pill(
            bg: const Color(0xFFFFF4EC),
            border: KvlColors.primary.withValues(alpha: 0.3),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.public_rounded, size: pillIconSz, color: KvlColors.primaryDeep),
              const SizedBox(width: 4),
              Text(IndianNumberFormat.format(globalBase),
                  style: KvlText.ui(pillFs, FontWeight.w800).copyWith(color: const Color(0xFFCC6A2B))),
              Text('  +  ', style: KvlText.ui(pillFs, FontWeight.w500).copyWith(color: KvlColors.inkSoft)),
              TweenAnimationBuilder<double>(
                key: ValueKey(increment),
                tween: Tween(begin: increment > 0 ? 1.15 : 1.0, end: 1.0),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (_, s, child) => Transform.scale(scale: s, child: child),
                child: Text(IndianNumberFormat.format(increment),
                    style: KvlText.ui(pillFs, FontWeight.w800).copyWith(color: const Color(0xFF16A34A))),
              ),
            ]),
          ),
          const SizedBox(width: 6),
          // Points
          pill(
            bg: const Color(0xFFFBF3D8),
            border: const Color(0xFFE8C04A),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.star_rounded, size: pillIconSz, color: KvlColors.gold),
              const SizedBox(width: 4),
              Text(IndianNumberFormat.format(points),
                  style: KvlText.ui(pillFs, FontWeight.w800).copyWith(color: const Color(0xFF5a4400))),
            ]),
          ),
          if (bookCount > 0) ...[
            const SizedBox(width: 6),
            // Book
            pill(
              onTap: () => BookPreviewButton.openSheet(context, mantraId),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.menu_book_rounded, size: pillIconSz, color: KvlColors.primaryDeep),
                const SizedBox(width: 4),
                Text(IndianNumberFormat.format(bookCount),
                    style: KvlText.ui(pillFs, FontWeight.w800).copyWith(color: KvlColors.primaryDeep)),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

// Simple dialog wrapper so palette tap opens the existing color picker sheet.
class _ColorPickerDialog extends StatelessWidget {
  const _ColorPickerDialog({required this.selectedColor});
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    // Reuse the existing color picker sheet logic inline.
    final colors = [
      KvlColors.ink,
      KvlColors.primary,
      KvlColors.accent,
      KvlColors.danger,
      const Color(0xFF1D4ED8),
      Colors.black,
    ];
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pen Colour', style: KvlText.title(16)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: colors.map((c) => GestureDetector(
                onTap: () => Navigator.of(context).pop(c),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c == selectedColor ? KvlColors.primaryDeep : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact single-line info row ────────────────────────────────────────────
// Shows Global count + pts + book as minimal icon+number pills in one row.

class _CompactInfoRow extends ConsumerWidget {
  const _CompactInfoRow({
    required this.globalCount,
    required this.yours,
    required this.increment,
    required this.compact,
    required this.mantraId,
  });

  final int globalCount;
  final int yours;
  final int increment;
  final bool compact;
  final String mantraId;

  static Widget _pill({
    required Widget child,
    Color bg = Colors.white,
    Color border = const Color(0xFFE0D4C8),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalBase = (globalCount - yours).clamp(0, globalCount);
    final points = ref.watch(rewardTotalProvider).value ?? 0;
    final bookCount =
        ref.watch(bookAssetsProvider(mantraId)).value?.length ?? 0;
    final fs = compact ? 12.0 : 13.0;
    final iconSz = compact ? 13.0 : 15.0;
    final gap = compact ? 6.0 : 8.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Global: 🌐 base + session
        _pill(
          bg: const Color(0xFFFFF4EC),
          border: KvlColors.primary.withValues(alpha: 0.3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public_rounded, size: iconSz, color: KvlColors.primaryDeep),
              SizedBox(width: 5),
              Text(
                IndianNumberFormat.format(globalBase),
                style: KvlText.ui(fs, FontWeight.w800)
                    .copyWith(color: const Color(0xFFCC6A2B)),
              ),
              Text('  +  ',
                  style: KvlText.ui(fs, FontWeight.w500)
                      .copyWith(color: KvlColors.inkSoft)),
              TweenAnimationBuilder<double>(
                key: ValueKey(increment),
                tween: Tween(begin: increment > 0 ? 1.15 : 1.0, end: 1.0),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Text(
                  IndianNumberFormat.format(increment),
                  style: KvlText.ui(fs, FontWeight.w800)
                      .copyWith(color: const Color(0xFF16A34A)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: gap),
        // Points: ⭐ number
        _pill(
          bg: const Color(0xFFFBF3D8),
          border: const Color(0xFFE8C04A),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: iconSz, color: KvlColors.gold),
              const SizedBox(width: 4),
              Text(
                IndianNumberFormat.format(points),
                style: KvlText.ui(fs, FontWeight.w800)
                    .copyWith(color: const Color(0xFF5a4400)),
              ),
            ],
          ),
        ),
        SizedBox(width: gap),
        // Book: 📖 number
        if (bookCount > 0)
          GestureDetector(
            onTap: () => BookPreviewButton.openSheet(context, mantraId),
            child: _pill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded,
                      size: iconSz, color: KvlColors.primaryDeep),
                  const SizedBox(width: 4),
                  Text(
                    IndianNumberFormat.format(bookCount),
                    style: KvlText.ui(fs, FontWeight.w800)
                        .copyWith(color: KvlColors.primaryDeep),
                  ),
                ],
              ),
            ),
          ),
      ],
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
    required this.onTap,
    required this.compact,
  });

  final bool saving;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF16A34A);
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 11 : 14,
          vertical: compact ? 7 : 9,
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
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: compact ? 14 : 16),
                  SizedBox(width: compact ? 4 : 5),
                  Text(
                    'Complete',
                    style: KvlText.ui(compact ? 11 : 13, FontWeight.w800)
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
