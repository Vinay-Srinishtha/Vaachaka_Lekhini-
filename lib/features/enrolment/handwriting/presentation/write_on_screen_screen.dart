import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
import '../../../../core/navigation/back_navigation.dart';
import '../../../../core/remote_config/remote_config.dart';
import '../../../../core/remote_config/remote_config_keys.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/indian_number_format.dart';
import '../../../programs/domain/session.dart';
import '../../../settings/domain/settings_repository.dart';
import '../domain/handwriting_asset.dart';
import '../../../../l10n/l10n.dart';

class WriteOnScreenScreen extends ConsumerStatefulWidget {
  const WriteOnScreenScreen({
    super.key,
    required this.mantraId,
    this.programId,
  });

  final String mantraId;
  final String? programId;

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

      // ── Run pixel-grid comparison ──────────────────────────────────────────
      final refBytes = await refFile.readAsBytes();
      final score = await HandwritingComparator.compare(png, refBytes);

      // Threshold from RemoteConfig — default 40 (= 40%)
      final cfg = ref.read(remoteConfigProvider).value ?? RemoteConfig.empty;
      final thresholdPct =
          cfg.intFlag(RemoteConfigKeys.minHandwritingAccuracy, fallback: 40);
      final threshold = thresholdPct / 100.0;

      if (score >= threshold) {
        // ── Accept ────────────────────────────────────────────────────────────
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

  /// Shown when no enrolled handwriting sample exists for this mantra.
  void _showNoReferenceBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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
      ),
    );
  }

  /// Shown when the writing scores below the acceptance threshold.
  void _showRejectedFeedback(double score, int thresholdPct) {
    final got = (score * 100).toStringAsFixed(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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
      ),
    );
  }

  /// Brief green toast when a marginal-but-passing score is achieved (40–60%).
  /// Silent on clearly good scores to avoid interrupting the practice flow.
  void _showAcceptedFeedback(double score, double threshold) {
    if (score < threshold + 0.20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1400),
          backgroundColor: KvlColors.success,
          behavior: SnackBarBehavior.floating,
          content: Text(
            '✓  ${(score * 100).toStringAsFixed(0)}% — accepted',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_writingCount == 0 && _controller.isEmpty) return;
    // Count any pending unsaved drawing
    final total = _writingCount + (_controller.isEmpty ? 0 : 1);
    setState(() => _saving = true);
    final png = await _controller.toPngBytes();
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null) {
      setState(() => _saving = false);
      return;
    }
    if (png != null && _controller.isNotEmpty) {
      await ref
          .read(handwritingRepositoryProvider)
          .savePng(
            profileId: profile.id,
            mode: HandwritingMode.writeOnScreen,
            bytes: png,
            mantraId: widget.mantraId,
          );
    }
    if (!mounted) return;
    final programId = widget.programId;
    if (programId != null) {
      final repo = ref.read(programRepositoryProvider);
      final activeProfile = ref.read(activeProfileProvider).value;
      final session = await repo.startSession(
        programId: programId,
        memberId: activeProfile?.id ?? '',
        modality: SessionModality.handwriting,
        // usedHandwriting removed — modality==handwriting covers it
      );
      await repo.incrementSession(session.id, by: total);
      await repo.finishSession(session.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: Text(context.l10n.handwritingSaved(total)),
          backgroundColor: KvlColors.accent,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '✕',
            textColor: Colors.white,
            onPressed: () => ScaffoldMessenger.of(context).clearSnackBars(),
          ),
        ),
      );
      context.go('${KvlRoute.practice}/$programId');
      return;
    }
    context.go('${KvlRoute.setTargetWritings}/${widget.mantraId}');
  }

  @override
  Widget build(BuildContext context) {
    final mantra = ref.watch(mantraByIdProvider(widget.mantraId));
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final guide = mantra?.name.displayForLanguage(settings.languageCode) ?? '';
    final guideScript =
        mantra?.name.scriptForLanguage(settings.languageCode) ??
        settings.languageCode.mantraScriptForLanguage;
    if (widget.programId != null) {
      final programs = ref.watch(programsForActiveProfileProvider).value ?? [];
      final progress = programs
          .where((p) => p.id == widget.programId)
          .fold<int>(0, (total, p) => total + p.totalProgress);
      return _ProtoWriteScaffold(
        controller: _controller,
        guide: guide,
        guideScript: guideScript,
        saving: _saving,
        currentCount: progress,
        writingCount: _writingCount,
        onBack: () => context.popOrGo(KvlRoute.practice),
        onAdd: _submitOne,
        onFinish: _saving ? null : _save,
        onClear: _controller.clear,
        onUndo: _controller.undo,
        onRedo: _controller.redo,
        penColor: _penColor,
        onColorSelected: _setPenColor,
      );
    }
    return _SampleLandscapeWriteScaffold(
      controller: _controller,
      guide: guide,
      guideScript: guideScript,
      saving: _saving,
      onBack: () =>
          context.popOrGo('${KvlRoute.handwritingSubmit}/${widget.mantraId}'),
      onSave: _saving ? null : _save,
      onClear: _controller.clear,
      onUndo: _controller.undo,
      onRedo: _controller.redo,
      penColor: _penColor,
      onColorSelected: _setPenColor,
    );
  }
}

class _SampleLandscapeWriteScaffold extends StatelessWidget {
  const _SampleLandscapeWriteScaffold({
    required this.controller,
    required this.guide,
    required this.guideScript,
    required this.saving,
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
  final VoidCallback onBack;
  final VoidCallback? onSave;
  final VoidCallback onClear;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final Color penColor;
  final ValueChanged<Color> onColorSelected;

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
                  controller: controller,
                  guide: guide,
                  guideScript: guideScript,
                  compact: compact,
                ),
              ),
              Positioned(
                left: 14,
                top: topInset,
                child: IconButton(
                  onPressed: onBack,
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
                  saving: saving,
                  compact: compact,
                  onSave: onSave,
                  onPen: onClear,
                  penColor: penColor,
                  onColorSelected: onColorSelected,
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
                      onTap: onClear,
                    ),
                    SizedBox(width: compact ? 8 : 10),
                    _SampleFloatingTool(
                      icon: Icons.undo_rounded,
                      tooltip: context.l10n.undoTooltip,
                      onTap: onUndo,
                    ),
                    SizedBox(width: compact ? 8 : 10),
                    _SampleFloatingTool(
                      icon: Icons.redo_rounded,
                      tooltip: context.l10n.redoTooltip,
                      onTap: onRedo,
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
  });

  final SignatureController controller;
  final String guide;
  final MantraScript guideScript;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 210.0 : 250.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          left: compact ? 8 : 12,
          right: compact ? 8 : 12,
          top: compact ? 44 : 54,
          bottom: compact ? 8 : 12,
          child: Center(
            child: Transform.scale(
              scale: 1.0,
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

class _ProtoWriteScaffold extends StatefulWidget {
  const _ProtoWriteScaffold({
    required this.controller,
    required this.guide,
    required this.guideScript,
    required this.saving,
    required this.currentCount,
    required this.writingCount,
    required this.onBack,
    required this.onAdd,
    required this.onFinish,
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
  final int currentCount;
  final int writingCount;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final VoidCallback? onFinish;
  final VoidCallback onClear;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final Color penColor;
  final ValueChanged<Color> onColorSelected;

  @override
  State<_ProtoWriteScaffold> createState() => _ProtoWriteScaffoldState();
}

class _ProtoWriteScaffoldState extends State<_ProtoWriteScaffold> {
  double _guideScale = 1.0;
  bool _canvasHasContent = false;

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
    final globalCount = 10000000 + yours;
    return Scaffold(
      backgroundColor: KvlColors.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 390;
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final topInset = compact ? 13.0 : 18.0;
          return Stack(
            children: [
              Positioned.fill(
                child: _ProtoWritingCanvas(
                  controller: widget.controller,
                  guide: widget.guide,
                  guideScript: widget.guideScript,
                  compact: compact,
                  guideScale: _guideScale,
                ),
              ),
              Positioned(
                left: compact ? 72 : w * .10,
                right: compact ? 160 : 200,
                top: topInset,
                child: _LandscapeTopBar(
                  globalCount: globalCount,
                  compact: compact,
                ),

              ),
              Positioned(
                right: compact ? 12 : 18,
                top: topInset,
                child: Padding(
                  padding: EdgeInsets.only(top: compact ? 4 : 6),
                  child: _YoursPill(
                    yours: yours,
                    increment: widget.writingCount,
                    compact: compact,
                  ),
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
                top: h * .39,
                child: _ProtoPlainIcon(
                  icon: Icons.zoom_in_rounded,
                  onTap: _guideScale < _scaleMax ? _zoomIn : null,
                ),
              ),
              Positioned(
                right: compact ? 20 : 30,
                top: h * .59,
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
  });

  final SignatureController controller;
  final String guide;
  final MantraScript guideScript;
  final bool compact;
  final double guideScale;

  @override
  Widget build(BuildContext context) {
    final baseSize = compact ? 200.0 : 240.0;
    final size = baseSize * guideScale;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.zero,
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
    final svg =
        '''
<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="340" viewBox="0 0 1400 340">
  <text x="700" y="260" text-anchor="middle"
    font-family="$fontFamily"
    font-size="$fontSize"
    font-weight="500"
    fill="none"
    stroke="#25211D"
    stroke-opacity="$opacity"
    stroke-width="2.4"
    stroke-linecap="round"
    stroke-linejoin="round"
    fill="white"
    fill-opacity="1"
    paint-order="fill stroke"
    stroke-dasharray="3 7">$escapedText</text>
</svg>
''';
    return SvgPicture.string(svg, fit: BoxFit.contain);
  }
}

class _LandscapeTopBar extends StatelessWidget {
  const _LandscapeTopBar({
    required this.globalCount,
    required this.compact,
  });

  final int globalCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: _LandscapeModeItem(
            icon: Icons.notifications_off_outlined,
            label: context.l10n.phoneMode,
            iconColor: KvlColors.ink,
            compact: compact,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          fit: FlexFit.loose,
          child: _LandscapeModeItem(
            icon: Icons.music_note_rounded,
            label: context.l10n.ambienceSound,
            iconColor: KvlColors.ink,
            compact: compact,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          fit: FlexFit.loose,
          child: _LandscapeModeItem(
            icon: Icons.gesture_rounded,
            label: context.l10n.ownWritingModeLabel,
            iconColor: KvlColors.primary,
            compact: compact,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 16),
          Flexible(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                context.l10n.countDisplay(IndianNumberFormat.format(globalCount)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KvlText.ui(14, FontWeight.w500)
                    .copyWith(color: KvlColors.ink),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LandscapeModeItem extends StatelessWidget {
  const _LandscapeModeItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 24 : 30, color: iconColor),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: KvlText.caption(
              compact ? 8.8 : 10.5,
            ).copyWith(color: KvlColors.inkSoft),
          ),
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

class _YoursPill extends StatelessWidget {
  const _YoursPill({
    required this.yours,
    required this.increment,
    required this.compact,
  });

  final int yours;
  final int increment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 7 : 10,
      ),
      decoration: BoxDecoration(
        color: KvlColors.bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KvlColors.danger, width: 1.4),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            text: context.l10n.yoursDisplay,
            children: [
              TextSpan(
                text: IndianNumberFormat.format(yours),
                style: const TextStyle(color: KvlColors.danger),
              ),
              const TextSpan(text: ' + '),
              TextSpan(
                text: IndianNumberFormat.format(increment),
                style: const TextStyle(color: KvlColors.success),
              ),
            ],
          ),
          maxLines: 1,
          style: KvlText.ui(compact ? 15 : 17, FontWeight.w700),
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
