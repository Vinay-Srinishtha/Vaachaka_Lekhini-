import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/sim_api.dart';

enum SimPhase { idle, provisioning, running, stopping, done, error }

enum SimMode { realtime, bulk }

/// User-editable knobs for a simulation run.
@immutable
class SimConfig {
  const SimConfig({
    this.userCount = 1000,
    this.chantsPerMin = 40,
    this.durationMin = 5,
    this.mode = SimMode.bulk,
    this.modality = 'voice',
  });

  final int userCount;
  final int chantsPerMin;
  final int durationMin;
  final SimMode mode;
  final String modality;

  SimConfig copyWith({
    int? userCount,
    int? chantsPerMin,
    int? durationMin,
    SimMode? mode,
    String? modality,
  }) => SimConfig(
    userCount: userCount ?? this.userCount,
    chantsPerMin: chantsPerMin ?? this.chantsPerMin,
    durationMin: durationMin ?? this.durationMin,
    mode: mode ?? this.mode,
    modality: modality ?? this.modality,
  );

  /// Total chants the whole run will write if it completes.
  int get projectedChants => userCount * chantsPerMin * durationMin;
}

/// Drives the load simulation against the backend and exposes live progress.
///
/// Owns its own [SimApi] (interceptor-free) so it never touches the real
/// logged-in user's session. Pure [ChangeNotifier] — the screen listens
/// directly, no Riverpod wiring needed.
class SimulatorEngine extends ChangeNotifier {
  SimulatorEngine({SimApi? api}) : _api = api ?? SimApi();

  final SimApi _api;

  // How many requests to keep in flight at once during provisioning / posting.
  static const int _concurrency = 20;
  // Real-time tick granularity. Smaller = smoother fill, more requests.
  static const int _tickSeconds = 15;
  static const int _maxLogLines = 250;

  SimPhase phase = SimPhase.idle;
  SimConfig config = const SimConfig();

  int provisioned = 0;
  int totalUsers = 0;
  int sessionsPosted = 0;
  int chantsWritten = 0;
  int errors = 0;

  int elapsedSec = 0;
  int targetSec = 0;

  String? errorMessage;
  String? mantraId;
  String? mantraName;

  final List<String> logs = [];

  bool _stopRequested = false;
  final List<SimUser> _users = [];

  String get baseUrl => _api.baseUrl;
  bool get isBusy =>
      phase == SimPhase.provisioning ||
      phase == SimPhase.running ||
      phase == SimPhase.stopping;

  double get provisionFraction =>
      totalUsers == 0 ? 0 : provisioned / totalUsers;
  double get timeFraction => targetSec == 0 ? 0 : (elapsedSec / targetSec).clamp(0, 1);

  void _log(String msg) {
    logs.insert(0, msg);
    if (logs.length > _maxLogLines) logs.removeRange(_maxLogLines, logs.length);
  }

  void requestStop() {
    if (!isBusy) return;
    _stopRequested = true;
    phase = SimPhase.stopping;
    _log('Stop requested — finishing in-flight requests…');
    notifyListeners();
  }

  /// Kick off a run. Safe to call only when idle/done/error.
  Future<void> start(SimConfig cfg) async {
    if (isBusy) return;
    config = cfg;
    _stopRequested = false;
    _users.clear();
    provisioned = 0;
    totalUsers = cfg.userCount;
    sessionsPosted = 0;
    chantsWritten = 0;
    errors = 0;
    elapsedSec = 0;
    targetSec = cfg.durationMin * 60;
    errorMessage = null;
    logs.clear();
    phase = SimPhase.provisioning;
    _log('Starting: ${cfg.userCount} users · ${cfg.chantsPerMin}/min · '
        '${cfg.durationMin} min · ${cfg.mode.name} · ${cfg.modality}');
    notifyListeners();

    try {
      await _ensureMantra();
      await _provisionUsers();
      if (_stopRequested) return _finish('Stopped during provisioning.');
      if (_users.isEmpty) {
        throw StateError('No users could be provisioned — check the backend.');
      }

      phase = SimPhase.running;
      _log('Provisioned ${_users.length} users. Generating chants…');
      notifyListeners();

      if (cfg.mode == SimMode.bulk) {
        await _runBulk();
      } else {
        await _runRealtime();
      }
      _finish(_stopRequested ? 'Stopped.' : 'Run complete.');
    } catch (e) {
      phase = SimPhase.error;
      errorMessage = e.toString();
      _log('ERROR: $e');
      notifyListeners();
    }
  }

  void _finish(String msg) {
    phase = SimPhase.done;
    _log(msg);
    notifyListeners();
  }

  Future<void> _ensureMantra() async {
    final mantras = await _api.fetchMantras();
    if (mantras.isEmpty) {
      throw StateError('No mantras returned by /api/v1/mantras.');
    }
    final m = mantras.first;
    // Prefer slug — the programs endpoint accepts slug or cuid.
    mantraId = (m['slug']?.isNotEmpty ?? false) ? m['slug'] : m['id'];
    mantraName = m['name'];
    _log('Using mantra: $mantraName');
    notifyListeners();
  }

  Future<void> _provisionUsers() async {
    final indices = List.generate(config.userCount, (i) => i);
    await _forEachConcurrent<int>(indices, (i) async {
      if (_stopRequested) return;
      try {
        final user = await _api.provisionUser(i);
        await _api.createProgram(user, mantraId!);
        _users.add(user);
      } catch (e) {
        errors++;
        if (errors <= 10) _log('provision #$i failed: ${_short(e)}');
      } finally {
        provisioned++;
        if (provisioned % 25 == 0 || provisioned == totalUsers) {
          notifyListeners();
        }
      }
    });
    notifyListeners();
  }

  /// Bulk: each user gets one session per simulated minute, timestamps spread
  /// backward across the window ending now. One batched request per user.
  Future<void> _runBulk() async {
    final now = DateTime.now();
    final per = config.chantsPerMin;
    final mins = config.durationMin;
    await _forEachConcurrent<SimUser>(_users, (user) async {
      if (_stopRequested) return;
      final sessions = <({DateTime start, DateTime end, int count})>[
        for (var m = 0; m < mins; m++)
          (
            start: now.subtract(Duration(minutes: mins - m)),
            end: now.subtract(Duration(minutes: mins - m - 1)),
            count: per,
          ),
      ];
      try {
        final created = await _api.postSessions(
          user,
          sessions: sessions,
          modality: config.modality,
        );
        sessionsPosted += created;
        chantsWritten += per * mins;
      } catch (e) {
        errors++;
        if (errors <= 10) _log('bulk post failed: ${_short(e)}');
      }
      elapsedSec = targetSec; // bulk is instantaneous w.r.t. the window
      if (sessionsPosted % 200 < per) notifyListeners();
    });
    notifyListeners();
  }

  /// Real-time: paces writes over the real wall-clock duration. Every tick,
  /// each user posts one session covering [_tickSeconds] of activity at the
  /// configured rate (fractional chants carried over for exactness).
  Future<void> _runRealtime() async {
    final stopwatch = Stopwatch()..start();
    while (elapsedSec < targetSec && !_stopRequested) {
      final tickStart = DateTime.now();
      final remaining = targetSec - elapsedSec;
      final tick = remaining < _tickSeconds ? remaining : _tickSeconds;

      await _forEachConcurrent<SimUser>(_users, (user) async {
        if (_stopRequested) return;
        final exact = config.chantsPerMin * tick / 60.0 + user.carry;
        final count = exact.floor();
        user.carry = exact - count;
        if (count <= 0) return;
        final end = DateTime.now();
        try {
          final created = await _api.postSessions(
            user,
            sessions: [
              (start: end.subtract(Duration(seconds: tick)), end: end, count: count),
            ],
            modality: config.modality,
          );
          sessionsPosted += created;
          chantsWritten += count;
        } catch (e) {
          errors++;
          if (errors <= 10) _log('tick post failed: ${_short(e)}');
        }
      });

      elapsedSec += tick;
      _log('t+${elapsedSec}s · $sessionsPosted sessions · $chantsWritten chants');
      notifyListeners();

      // Pace to real time: sleep out the remainder of this tick.
      final spent = DateTime.now().difference(tickStart).inMilliseconds;
      final sleepMs = tick * 1000 - spent;
      if (sleepMs > 0 && !_stopRequested) {
        await Future.delayed(Duration(milliseconds: sleepMs));
      }
    }
    stopwatch.stop();
  }

  /// Run [task] over [items] with a bounded number of concurrent futures.
  Future<void> _forEachConcurrent<T>(
    List<T> items,
    Future<void> Function(T) task,
  ) async {
    var next = 0;
    Future<void> worker() async {
      while (true) {
        if (_stopRequested) return;
        final i = next++;
        if (i >= items.length) return;
        await task(items[i]);
      }
    }

    final workers = List.generate(
      _concurrency.clamp(1, items.isEmpty ? 1 : items.length),
      (_) => worker(),
    );
    await Future.wait(workers);
  }

  String _short(Object e) {
    final s = e.toString();
    return s.length > 120 ? '${s.substring(0, 120)}…' : s;
  }

  /// SQL to remove every simulator-created row from the (local) Postgres DB.
  /// Targets the reserved mobile range so real accounts are never touched.
  String clearDataSql() {
    final lo = SimApi.mobileBase;
    final hi = SimApi.mobileBase + 999999; // generous upper bound
    return '''
-- Delete all simulator accounts (mobile range $lo..$hi) and their data.
-- Children first to respect FKs; run against your LOCAL dev database only.
DELETE FROM "Session" WHERE "memberId" IN (
  SELECT m.id FROM "Member" m JOIN "Account" a ON a.id = m."accountId"
  WHERE a.mobile BETWEEN '$lo' AND '$hi'
);
DELETE FROM "RewardEvent" WHERE "memberId" IN (
  SELECT m.id FROM "Member" m JOIN "Account" a ON a.id = m."accountId"
  WHERE a.mobile BETWEEN '$lo' AND '$hi'
);
DELETE FROM "Program" WHERE "memberId" IN (
  SELECT m.id FROM "Member" m JOIN "Account" a ON a.id = m."accountId"
  WHERE a.mobile BETWEEN '$lo' AND '$hi'
);
DELETE FROM "Member" WHERE "accountId" IN (
  SELECT id FROM "Account" WHERE mobile BETWEEN '$lo' AND '$hi'
);
DELETE FROM "Account" WHERE mobile BETWEEN '$lo' AND '$hi';
''';
  }
}
