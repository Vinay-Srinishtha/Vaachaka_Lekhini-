import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/repository.dart';
import '../../../core/sync/sync_outbox.dart';
import '../domain/reward_event.dart';
import '../domain/reward_repository.dart';

class RewardRepositoryDrift implements RewardRepository {
  RewardRepositoryDrift(this._db, this._outbox, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  // ADDED: outbox so earn/spend are queued to Prisma automatically
  final SyncOutbox _outbox;
  final Uuid _uuid;

  RewardEvent _toEvent(RewardEventRow row) => RewardEvent(
        id: row.id,
        memberId: row.memberId,       // was profileId
        kind: RewardKind.fromName(row.kind),
        amount: row.amount,
        source: row.source,
        occurredAt: row.occurredAt,   // was createdAt
        storeItemId: row.storeItemId, // ADDED
      );

  SimpleSelectStatement<$RewardEventsTable, RewardEventRow> _historyQuery(
    String memberId, {
    RewardKind? filter,
  }) {
    final stmt = _db.select(_db.rewardEvents)
      ..where((t) => t.memberId.equals(memberId)); // was profileId
    if (filter != null) {
      stmt.where((t) => t.kind.equals(filter.name));
    }
    stmt.orderBy([(t) => OrderingTerm.desc(t.occurredAt)]); // was createdAt
    return stmt;
  }

  @override
  Future<int> totalPoints(String memberId) async {
    final rows = await _historyQuery(memberId).get();
    return rows.fold<int>(0, (a, r) => a + _toEvent(r).signedAmount);
  }

  @override
  Stream<int> watchTotalPoints(String memberId) {
    return _historyQuery(memberId)
        .watch()
        .map((rows) => rows.fold<int>(0, (a, r) => a + _toEvent(r).signedAmount));
  }

  @override
  Future<List<RewardEvent>> history(String memberId, {RewardKind? filter}) async {
    final rows = await _historyQuery(memberId, filter: filter).get();
    return rows.map(_toEvent).toList();
  }

  @override
  Stream<List<RewardEvent>> watchHistory(String memberId, {RewardKind? filter}) {
    return _historyQuery(memberId, filter: filter)
        .watch()
        .map((rs) => rs.map(_toEvent).toList());
  }

  @override
  Future<void> earn({
    required String memberId,   // was profileId
    required int amount,
    required String source,
    String? storeItemId,        // ADDED optional
  }) async {
    if (amount <= 0) return;
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.rewardEvents).insert(
          RewardEventsCompanion.insert(
            id: id,
            memberId: memberId,
            kind: 'earn',
            amount: amount,
            source: source,
            occurredAt: now,      // was createdAt
            storeItemId: Value(storeItemId),
          ),
        );
    // Queue to Prisma — field names match Prisma RewardEvent exactly
    await _outbox.enqueue('reward_events.append', {
      'id': id,
      'member_id': memberId,
      'store_item_id': storeItemId,
      'kind': 'earn',
      'amount': amount,
      'source': source,
      'occurred_at': now.toUtc().toIso8601String(),
    });
  }

  @override
  Future<Result<void>> spend({
    required String memberId,   // was profileId
    required int amount,
    required String source,
    String? storeItemId,        // ADDED optional
  }) async {
    if (amount <= 0) return const Ok(null);
    final have = await totalPoints(memberId);
    if (have < amount) return Err(RewardFailure.insufficient(amount, have));
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.rewardEvents).insert(
          RewardEventsCompanion.insert(
            id: id,
            memberId: memberId,
            kind: 'spend',
            amount: amount,
            source: source,
            occurredAt: now,
            storeItemId: Value(storeItemId),
          ),
        );
    await _outbox.enqueue('reward_events.append', {
      'id': id,
      'member_id': memberId,
      'store_item_id': storeItemId,
      'kind': 'spend',
      'amount': amount,
      'source': source,
      'occurred_at': now.toUtc().toIso8601String(),
    });
    return const Ok(null);
  }

  @override
  Future<void> reconcileFromServer(String memberId, int serverBalance) async {
    final local = await totalPoints(memberId);
    final diff = serverBalance - local;
    if (diff <= 0) return;
    // Write a local-only earn event to bridge the gap — no outbox enqueue.
    await _db.into(_db.rewardEvents).insert(
      RewardEventsCompanion.insert(
        id: _uuid.v4(),
        memberId: memberId,
        kind: 'earn',
        amount: diff,
        source: 'server_sync',
        occurredAt: DateTime.now(),
      ),
    );
  }
}
