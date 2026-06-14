import 'dart:async';

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
  Stream<int> watchBalance(String memberId) {
    // Balance = chant/writing progress + gifted/reconciled extras − spends.
    //
    // Three streams combined:
    //   progTotal   — sum of totalChants+totalWritings across all programs
    //   extrasTotal — gift / milestone / refund / server_sync events (positive credits
    //                 not derived from program progress, e.g. admin gifts)
    //   spentTotal  — spend events (the only debit kind clients can submit)
    final controller = StreamController<int>();
    int progTotal = 0;
    int extrasTotal = 0;
    int spentTotal = 0;
    bool progReady = false;
    bool extrasReady = false;
    bool spentReady = false;

    void emit() {
      if (!progReady || !extrasReady || !spentReady) return;
      final credits = progTotal + extrasTotal;
      controller.add((credits - spentTotal).clamp(0, credits));
    }

    final progSub = (_db.select(_db.programs)
          ..where((t) => t.memberId.equals(memberId)))
        .watch()
        .map((rows) => rows.fold<int>(0, (a, r) => a + r.totalChants + r.totalWritings))
        .listen((v) { progTotal = v; progReady = true; emit(); });

    // Gift / milestone / refund events + server_sync reconciliation bridging.
    // These are credits that exist outside program progress (admin gifts, etc.).
    final extrasSub = (_db.select(_db.rewardEvents)
          ..where(
            (t) =>
                t.memberId.equals(memberId) &
                (t.kind.isIn(['gift', 'milestone', 'refund']) |
                    (t.kind.equals('earn') & t.source.equals('server_sync'))),
          ))
        .watch()
        .map((rows) => rows.fold<int>(0, (a, r) => a + r.amount))
        .listen((v) { extrasTotal = v; extrasReady = true; emit(); });

    final spentSub = (_db.select(_db.rewardEvents)
          ..where((t) => t.memberId.equals(memberId) & t.kind.equals('spend')))
        .watch()
        .map((rows) => rows.fold<int>(0, (a, r) => a + r.amount))
        .listen((v) { spentTotal = v; spentReady = true; emit(); });

    controller.onCancel = () {
      progSub.cancel();
      extrasSub.cancel();
      spentSub.cancel();
    };

    return controller.stream;
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
    // Note: earn events are NOT pushed to the server outbox.
    // The server generates earn events server-side when sessions sync,
    // and blocks client-submitted earn events (kind:'earn' returns 403).
    // The local row is kept for offline balance display only;
    // reconcileFromServer() corrects any divergence on next pull.
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
  Stream<Set<String>> watchRedeemedItemIds(String memberId) {
    return (_db.select(_db.rewardEvents)
          ..where(
            (t) =>
                t.memberId.equals(memberId) &
                t.kind.equals('spend') &
                t.storeItemId.isNotNull(),
          ))
        .watch()
        .map((rows) => rows.map((r) => r.storeItemId!).toSet());
  }

  @override
  Future<void> seedRedemption({
    required String id,
    required String memberId,
    required String storeItemId,
    required int amount,
    required String source,
    required DateTime occurredAt,
  }) async {
    await _db.into(_db.rewardEvents).insertOnConflictUpdate(
          RewardEventsCompanion.insert(
            id: id,
            memberId: memberId,
            kind: 'spend',
            amount: amount,
            source: source,
            occurredAt: occurredAt,
            storeItemId: Value(storeItemId),
          ),
        );
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
