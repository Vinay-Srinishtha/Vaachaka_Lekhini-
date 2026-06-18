import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../auth/auth_service.dart';
import '../storage/storage_keys.dart';
import 'sync_outbox.dart';

/// Drains the outbox + pulls /api/v1/me at the right moments:
///   • on auth (sign-in)
///   • on app foreground (resume)
///   • on connectivity restore
///
/// Per-feature write sites use [enqueue] to push mutations through;
/// they never await network IO themselves.
class SyncEngine with WidgetsBindingObserver {
  SyncEngine({
    required ApiClient api,
    required AuthService auth,
    required SyncOutbox outbox,
  })  : _api = api,
        _auth = auth,
        _outbox = outbox {
    WidgetsBinding.instance.addObserver(this);
    _watchAuth();
    _watchConnectivity();
    _startPoll();
  }

  final ApiClient _api;
  final AuthService _auth;
  final SyncOutbox _outbox;
  final _pullController = StreamController<Map<String, Object?>>.broadcast();

  StreamSubscription<dynamic>? _connSub;
  StreamSubscription<dynamic>? _authSub;
  Timer? _pollTimer;
  bool _draining = false;

  /// Emits the latest /api/v1/me payload after each successful pull.
  Stream<Map<String, Object?>> get snapshots => _pullController.stream;

  Future<void> enqueue(String kind, Map<String, Object?> payload) async {
    await _outbox.enqueue(kind, payload);
    // Try to flush right away. If offline / unauth this is a cheap no-op.
    unawaited(drain());
  }

  /// Force a one-shot pull + drain. Safe to call from anywhere.
  Future<void> syncNow() async {
    await drain();
    await pull();
  }

  /// Pull the full account snapshot. Updates ledger / member balances /
  /// programs view in one round trip. Idempotent; failures are silent.
  Future<Map<String, Object?>?> pull() async {
    if (!_auth.isAuthenticated) return null;
    try {
      final res = await _api.dio.get<Map<String, Object?>>('/api/v1/me');
      final body = res.data;
      if (body != null) _pullController.add(body);
      return body;
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('[sync] pull failed: ${e.message}');
      return null;
    }
  }

  /// Walk the outbox FIFO and POST each item. Stops on the first failure
  /// (so writes stay ordered per-resource).
  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      final pending = await _outbox.peekAll();
      for (final item in pending) {
        final spec = _specFor(item.kind);
        if (spec == null) {
          // Unknown kind — drop so we don't loop forever.
          await _outbox.remove(item.id);
          continue;
        }
        // Wrap the payload in the array envelope the server expects.
        // devices.upsert is the only endpoint that takes a bare object.
        final body = spec.wrapKey != null
            ? {spec.wrapKey!: [item.payload]}
            : item.payload;
        try {
          final route = spec.isDelete
              ? '${spec.route}/${item.payload['id']}'
              : spec.route;
          if (spec.isDelete) {
            await _api.dio.delete<Map<String, Object?>>(route);
          } else {
            await _api.dio.post<Map<String, Object?>>(route, data: body);
          }
          await _outbox.remove(item.id);
          if (kDebugMode) debugPrint('[sync] pushed ${item.kind} → ${spec.route}');
        } on DioException catch (e) {
          final status = e.response?.statusCode ?? 0;
          final respBody = e.response?.data?.toString() ?? '';
          final msg = '${e.message ?? 'unknown'} | status=$status | $respBody';
          await _outbox.markFailure(item, msg);
          if (kDebugMode) debugPrint('[sync] push ${spec.route} FAILED: $msg');
          // 4xx = bad payload (won't get better) — drop after 3 attempts.
          // 5xx / network = transient — keep retrying indefinitely.
          if (status >= 400 && status < 500 && item.attempts >= 3) {
            if (kDebugMode) debugPrint('[sync] dropping ${item.kind} after ${item.attempts} 4xx failures');
            await _outbox.remove(item.id);
            continue;
          }
          break; // preserve FIFO ordering
        }
      }
    } finally {
      _draining = false;
    }
  }

  _SyncSpec? _specFor(String kind) => switch (kind) {
        'members.upsert'       => const _SyncSpec('/api/v1/members',      'members'),
        'members.delete'       => const _SyncSpec('/api/v1/members',      null, isDelete: true),
        'programs.upsert'      => const _SyncSpec('/api/v1/programs',     'programs'),
        'sessions.append'      => const _SyncSpec('/api/v1/sessions',     'sessions'),
        'reward_events.append' => const _SyncSpec('/api/v1/reward-events','events'),
        'devices.upsert'       => const _SyncSpec('/api/v1/devices',      null),
        _                      => null,
      };

  Future<String> _stableDeviceId() async {
    final box = Hive.box<dynamic>(KvlBoxes.session);
    String? id = box.get(KvlKeys.deviceId) as String?;
    if (id == null) {
      id = const Uuid().v4();
      await box.put(KvlKeys.deviceId, id);
    }
    return id;
  }

  Future<void> _registerDevice() async {
    final deviceId = await _stableDeviceId();
    final platform = Platform.isAndroid ? 'android' : 'ios';
    await enqueue('devices.upsert', {
      'id': deviceId,
      'platform': platform,
      'app_version': null,
    });
  }

  void _watchAuth() {
    // Real JWT sign-in (fires when AuthService gets a token)
    _authSub = _auth.accountStream.listen((account) {
      if (account != null) {
        unawaited(_registerDevice());
        unawaited(syncNow());
      }
    });
    // Kick an immediate drain on startup so any outbox items queued
    // during a previous session (even with dummy auth) are flushed.
    unawaited(drain());
    // If bootstrap() already completed before we subscribed (broadcast stream
    // does not replay), we still need to pull the latest server snapshot so
    // programs, reward balances and the leaderboard reflect real DB data.
    if (_auth.isAuthenticated) {
      unawaited(syncNow());
    }
  }

  void _watchConnectivity() {
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      if (hasNet) unawaited(drain());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncNow());
    }
  }

  void _startPoll() {
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_auth.isAuthenticated) unawaited(pull());
    });
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    await _connSub?.cancel();
    await _authSub?.cancel();
    await _pullController.close();
  }
}

class _SyncSpec {
  const _SyncSpec(this.route, this.wrapKey, {this.isDelete = false});
  final String route;
  /// The JSON key to wrap the payload array in, e.g. "sessions".
  /// Null means send the payload object directly (no wrapping).
  final String? wrapKey;
  /// When true, send `DELETE route/id` instead of POST.
  final bool isDelete;
}
