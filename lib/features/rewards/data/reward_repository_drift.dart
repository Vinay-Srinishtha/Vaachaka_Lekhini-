import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/repository.dart';
import '../domain/reward_event.dart';
import '../domain/reward_repository.dart';

class RewardRepositoryDrift implements RewardRepository {
  RewardRepositoryDrift(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();
  final AppDatabase _db;
  final Uuid _uuid;

  RewardEvent _toEvent(RewardEventRow row) => RewardEvent(
        id: row.id,
        profileId: row.profileId,
        kind: RewardKind.fromName(row.kind),
        amount: row.amount,
        source: row.source,
        createdAt: row.createdAt,
      );

  @override
  Future<int> totalPoints(String profileId) async {
    final rows = await _historyQuery(profileId).get();
    return rows.fold<int>(0, (a, r) => a + _toEvent(r).signedAmount);
  }

  @override
  Stream<int> watchTotalPoints(String profileId) {
    return _historyQuery(profileId).watch().map((rows) {
      return rows.fold<int>(0, (a, r) => a + _toEvent(r).signedAmount);
    });
  }

  SimpleSelectStatement<$RewardEventsTable, RewardEventRow> _historyQuery(String profileId, {RewardKind? filter}) {
    final stmt = _db.select(_db.rewardEvents)..where((t) => t.profileId.equals(profileId));
    if (filter != null) {
      stmt.where((t) => t.kind.equals(filter.name));
    }
    stmt.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return stmt;
  }

  @override
  Future<List<RewardEvent>> history(String profileId, {RewardKind? filter}) async {
    final rows = await _historyQuery(profileId, filter: filter).get();
    return rows.map(_toEvent).toList();
  }

  @override
  Stream<List<RewardEvent>> watchHistory(String profileId, {RewardKind? filter}) {
    return _historyQuery(profileId, filter: filter).watch().map((rs) => rs.map(_toEvent).toList());
  }

  @override
  Future<void> earn({required String profileId, required int amount, required String source}) async {
    if (amount <= 0) return;
    await _db.into(_db.rewardEvents).insert(RewardEventsCompanion.insert(
          id: _uuid.v4(),
          profileId: profileId,
          kind: 'earn',
          amount: amount,
          source: source,
          createdAt: DateTime.now(),
        ));
  }

  @override
  Future<Result<void>> spend({required String profileId, required int amount, required String source}) async {
    if (amount <= 0) return const Ok(null);
    final have = await totalPoints(profileId);
    if (have < amount) return Err(RewardFailure.insufficient(amount, have));
    await _db.into(_db.rewardEvents).insert(RewardEventsCompanion.insert(
          id: _uuid.v4(),
          profileId: profileId,
          kind: 'spend',
          amount: amount,
          source: source,
          createdAt: DateTime.now(),
        ));
    return const Ok(null);
  }
}
