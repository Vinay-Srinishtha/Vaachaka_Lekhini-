import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

/// One pending mutation waiting to be pushed to the server. Stored as a
/// map in the Hive `kvl_outbox` box so it survives app restarts.
class OutboxItem {
  OutboxItem({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  /// Stable id, also the Hive map key.
  final String id;

  /// Logical op — e.g. 'members.upsert', 'sessions.append',
  /// 'reward_events.append', 'devices.upsert', 'programs.upsert'.
  final String kind;

  /// The full request body to POST.
  final Map<String, Object?> payload;

  final DateTime createdAt;
  int attempts;
  String? lastError;

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'attempts': attempts,
        'last_error': lastError,
      };

  factory OutboxItem.fromJson(Map<dynamic, dynamic> json) {
    final payload = json['payload'];
    return OutboxItem(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      payload: payload is Map ? Map<String, Object?>.from(payload) : {},
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      attempts: (json['attempts'] as int?) ?? 0,
      lastError: json['last_error'] as String?,
    );
  }
}

/// Append-only FIFO of pending mutations, persisted to Hive.
///
/// The [SyncEngine] drains this on connectivity events. Adders are
/// fire-and-forget: write site enqueues, sync handles delivery.
class SyncOutbox {
  SyncOutbox(this._box);

  final Box<dynamic> _box;
  static const _uuid = Uuid();

  /// Hive sub-key prefix so the outbox can share `kvl_outbox` with other
  /// future bookkeeping if needed.
  static const _prefix = 'item:';

  Future<void> enqueue(String kind, Map<String, Object?> payload) async {
    final id = _uuid.v4();
    final item = OutboxItem(
      id: id,
      kind: kind,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await _box.put('$_prefix$id', item.toJson());
    if (kDebugMode) debugPrint('[outbox] +$kind ($id)');
  }

  Future<List<OutboxItem>> peekAll({int limit = 100}) async {
    final keys = _box.keys.where((k) => k is String && k.startsWith(_prefix)).toList();
    keys.sort();
    final items = <OutboxItem>[];
    for (final k in keys.take(limit)) {
      final raw = _box.get(k);
      if (raw is! Map) continue;
      try {
        items.add(OutboxItem.fromJson(Map<dynamic, dynamic>.from(raw)));
      } catch (e) {
        if (kDebugMode) debugPrint('[outbox] corrupt item $k — dropping: $e');
        await _box.delete(k);
      }
    }
    return items;
  }

  Future<void> remove(String id) async {
    await _box.delete('$_prefix$id');
  }

  Future<void> markFailure(OutboxItem item, String error) async {
    item.attempts += 1;
    item.lastError = error;
    await _box.put('$_prefix${item.id}', item.toJson());
  }

  Future<int> size() async {
    return _box.keys.where((k) => k is String && k.startsWith(_prefix)).length;
  }
}
