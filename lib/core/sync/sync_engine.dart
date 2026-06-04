import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../api/api_client.dart';
import '../auth/auth_service.dart';
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
  }

  final ApiClient _api;
  final AuthService _auth;
  final SyncOutbox _outbox;
  final _pullController = StreamController<Map<String, Object?>>.broadcast();

  StreamSubscription<dynamic>? _connSub;
  StreamSubscription<dynamic>? _authSub;
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
    if (!_auth.isAuthenticated) return;
    _draining = true;
    try {
      final pending = await _outbox.peekAll();
      for (final item in pending) {
        final route = _routeFor(item.kind);
        if (route == null) {
          // Unknown kind — drop so we don't loop forever.
          await _outbox.remove(item.id);
          continue;
        }
        try {
          await _api.dio.post<Map<String, Object?>>(route, data: item.payload);
          await _outbox.remove(item.id);
        } on DioException catch (e) {
          await _outbox.markFailure(item, e.message ?? 'unknown');
          if (kDebugMode) debugPrint('[sync] push $route failed: ${e.message}');
          break; // preserve FIFO ordering
        }
      }
    } finally {
      _draining = false;
    }
  }

  String? _routeFor(String kind) {
    switch (kind) {
      case 'members.upsert':
        return '/api/v1/members';
      case 'programs.upsert':
        return '/api/v1/programs';
      case 'sessions.append':
        return '/api/v1/sessions';
      case 'reward_events.append':
        return '/api/v1/reward-events';
      case 'devices.upsert':
        return '/api/v1/devices';
      default:
        return null;
    }
  }

  void _watchAuth() {
    _authSub = _auth.accountStream.listen((account) {
      if (account != null) {
        unawaited(syncNow());
      }
    });
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

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _connSub?.cancel();
    await _authSub?.cancel();
    await _pullController.close();
  }
}
