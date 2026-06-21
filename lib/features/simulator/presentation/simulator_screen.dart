import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/simulator_engine.dart';

/// Developer load-testing tool: drives N simulated accounts against the backend
/// at a configurable chant rate, in real-time or bulk mode, and offers a
/// one-tap way to wipe the generated data.
class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  final _engine = SimulatorEngine();
  final _users = TextEditingController(text: '1000');
  final _rate = TextEditingController(text: '40');
  final _duration = TextEditingController(text: '5');
  SimMode _mode = SimMode.bulk;
  String _modality = 'voice';

  @override
  void initState() {
    super.initState();
    _engine.addListener(_onChange);
  }

  @override
  void dispose() {
    _engine.removeListener(_onChange);
    _engine.dispose();
    _users.dispose();
    _rate.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  int _int(TextEditingController c, int fallback) =>
      int.tryParse(c.text.trim()) ?? fallback;

  void _start() {
    FocusScope.of(context).unfocus();
    _engine.start(
      SimConfig(
        userCount: _int(_users, 1000).clamp(1, 100000),
        chantsPerMin: _int(_rate, 40).clamp(1, 100000),
        durationMin: _int(_duration, 5).clamp(1, 1440),
        mode: _mode,
        modality: _modality,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = _engine;
    final busy = e.isBusy;
    return KvlScaffold(
      title: 'Load Simulator',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.sm),
          _targetBanner(e.baseUrl),
          const SizedBox(height: KvlSpacing.md),

          _SectionCard(
            title: 'Configuration',
            children: [
              _numberField('Users', _users, busy),
              _numberField('Chants / minute (per user)', _rate, busy),
              _numberField('Duration (minutes)', _duration, busy),
              const SizedBox(height: KvlSpacing.sm),
              _modeRow(busy),
              const SizedBox(height: KvlSpacing.sm),
              _modalityRow(busy),
              const SizedBox(height: KvlSpacing.sm),
              _projection(),
            ],
          ),

          const SizedBox(height: KvlSpacing.md),
          KvlButton(
            label: busy ? 'Stop' : 'Start simulation',
            variant: busy ? KvlButtonVariant.danger : KvlButtonVariant.primary,
            icon: busy ? Icons.stop_rounded : Icons.play_arrow_rounded,
            onPressed: busy ? e.requestStop : _start,
          ),

          if (e.phase != SimPhase.idle) ...[
            const SizedBox(height: KvlSpacing.md),
            _progressCard(e),
          ],

          const SizedBox(height: KvlSpacing.md),
          _SectionCard(
            title: 'Cleanup',
            children: [
              Text(
                'Generates SQL to delete every simulated account '
                '(mobiles ${SimApiRange.lo}–${SimApiRange.hi}) and their '
                'programs, sessions and reward events. Run it against your '
                'local dev Postgres.',
                style: KvlText.caption(11).copyWith(color: KvlColors.inkSoft),
              ),
              const SizedBox(height: KvlSpacing.sm),
              KvlButton(
                label: 'Clear all sim data…',
                variant: KvlButtonVariant.outlineDanger,
                icon: Icons.delete_sweep_outlined,
                onPressed: () => _showClearSql(e.clearDataSql()),
              ),
            ],
          ),

          if (e.logs.isNotEmpty) ...[
            const SizedBox(height: KvlSpacing.md),
            _logCard(e),
          ],
          const SizedBox(height: KvlSpacing.lg),
        ],
      ),
    );
  }

  Widget _targetBanner(String url) {
    return Container(
      padding: const EdgeInsets.all(KvlSpacing.sm),
      decoration: BoxDecoration(
        color: KvlColors.primaryGhost,
        borderRadius: KvlRadius.brSM,
        border: Border.all(color: KvlColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.dns_outlined, size: 16, color: KvlColors.primaryDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Target: $url',
              style: KvlText.caption(11).copyWith(color: KvlColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField(String label, TextEditingController c, bool disabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: KvlText.ui(12))),
          SizedBox(
            width: 96,
            child: TextField(
              controller: c,
              enabled: !disabled,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: KvlText.ui(13, FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: KvlColors.bg,
                border: OutlineInputBorder(
                  borderRadius: KvlRadius.brSM,
                  borderSide: const BorderSide(color: KvlColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: KvlRadius.brSM,
                  borderSide: const BorderSide(color: KvlColors.border),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeRow(bool disabled) {
    return Row(
      children: [
        Expanded(child: Text('Mode', style: KvlText.ui(12))),
        _pill('Bulk', _mode == SimMode.bulk, disabled,
            () => setState(() => _mode = SimMode.bulk)),
        const SizedBox(width: 6),
        _pill('Real-time', _mode == SimMode.realtime, disabled,
            () => setState(() => _mode = SimMode.realtime)),
      ],
    );
  }

  Widget _modalityRow(bool disabled) {
    return Row(
      children: [
        Expanded(child: Text('Modality', style: KvlText.ui(12))),
        for (final m in const ['voice', 'manual', 'handwriting']) ...[
          _pill(m, _modality == m, disabled,
              () => setState(() => _modality = m)),
          if (m != 'handwriting') const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _pill(String label, bool selected, bool disabled, VoidCallback onTap) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: KvlRadius.brSM,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? KvlColors.primary : KvlColors.bg,
          borderRadius: KvlRadius.brSM,
          border: Border.all(
            color: selected ? KvlColors.primary : KvlColors.border,
          ),
        ),
        child: Text(
          label,
          style: KvlText.ui(11.5, FontWeight.w600).copyWith(
            color: selected ? Colors.white : KvlColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _projection() {
    final users = _int(_users, 0);
    final rate = _int(_rate, 0);
    final dur = _int(_duration, 0);
    final total = users * rate * dur;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KvlSpacing.sm),
      decoration: BoxDecoration(
        color: KvlColors.bg,
        borderRadius: KvlRadius.brSM,
      ),
      child: Text(
        'Projected: ${_fmt(total)} chants across ${_fmt(users)} users '
        'over $dur min.',
        style: KvlText.caption(11).copyWith(color: KvlColors.inkSoft),
      ),
    );
  }

  Widget _progressCard(SimulatorEngine e) {
    return _SectionCard(
      title: 'Progress · ${e.phase.name}',
      children: [
        _bar('Provisioning', e.provisionFraction,
            '${e.provisioned}/${e.totalUsers}'),
        if (e.config.mode == SimMode.realtime) ...[
          const SizedBox(height: 8),
          _bar('Time', e.timeFraction, '${e.elapsedSec}s / ${e.targetSec}s'),
        ],
        const SizedBox(height: KvlSpacing.sm),
        Wrap(
          spacing: KvlSpacing.md,
          runSpacing: 8,
          children: [
            _stat('Sessions', _fmt(e.sessionsPosted)),
            _stat('Chants', _fmt(e.chantsWritten)),
            _stat('Errors', _fmt(e.errors)),
          ],
        ),
        if (e.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(e.errorMessage!,
              style: KvlText.caption(11).copyWith(color: KvlColors.danger)),
        ],
      ],
    );
  }

  Widget _bar(String label, double frac, String trailing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: KvlText.caption(11))),
            Text(trailing,
                style: KvlText.caption(11).copyWith(color: KvlColors.inkSoft)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: frac.clamp(0, 1),
            minHeight: 6,
            backgroundColor: KvlColors.border,
            color: KvlColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: KvlText.ui(15, FontWeight.w700)),
        Text(label,
            style: KvlText.caption(10).copyWith(color: KvlColors.muted)),
      ],
    );
  }

  Widget _logCard(SimulatorEngine e) {
    return _SectionCard(
      title: 'Log',
      children: [
        Container(
          height: 160,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: KvlColors.bg,
            borderRadius: KvlRadius.brSM,
          ),
          child: ListView.builder(
            reverse: true,
            itemCount: e.logs.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                e.logs[i],
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  color: KvlColors.inkSoft,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showClearSql(String sql) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KvlColors.surface,
        title: Text('Clear sim data', style: KvlText.ui(15, FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              sql,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: sql));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SQL copied to clipboard')),
              );
            },
            child: const Text('Copy SQL'),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}

/// Exposes the reserved mobile range to the UI without leaking the engine impl.
abstract final class SimApiRange {
  static const int lo = 9900000000;
  static const int hi = 9900999999;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 2),
          child: Text(
            title.toUpperCase(),
            style: KvlText.muted(10)
                .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.6),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(KvlSpacing.md),
          decoration: BoxDecoration(
            color: KvlColors.surface,
            borderRadius: KvlRadius.brLG,
            border: Border.all(color: KvlColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}
