import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// One row per program (per profile · per mantra · with a target).
/// `syncedAt` is null until the row has been pushed to the backend
/// (added in Phase 9) — useful for delta sync.
@DataClassName('ProgramRow')
class Programs extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get mantraId => text()();
  IntColumn get targetWritings => integer()();
  IntColumn get targetDays => integer()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get dailyTarget => integer()();

  /// 'active' | 'completed' | 'paused'
  TextColumn get status => text().withDefault(const Constant('active'))();

  IntColumn get totalChants => integer().withDefault(const Constant(0))();
  IntColumn get totalWritings => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One row per practice session. Sessions accumulate counts during their
/// lifetime; on Finish, [endedAt] is set and totals are rolled up into [Programs].
@DataClassName('SessionRow')
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get programId => text().customConstraint('NOT NULL REFERENCES programs(id) ON DELETE CASCADE')();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get count => integer().withDefault(const Constant(0))();

  /// 'voice' | 'manual' | 'handwriting'
  TextColumn get modality => text()();
  BoolColumn get usedHandwriting => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One line in the user's reward ledger. Earn rows store positive amounts;
/// spend rows store positive amounts with kind='spend' — the convention
/// lives in `RewardEvent.signedAmount`.
@DataClassName('RewardEventRow')
class RewardEvents extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();

  /// 'earn' | 'spend'
  TextColumn get kind => text()();
  IntColumn get amount => integer()();
  TextColumn get source => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Programs, Sessions, RewardEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  /// In-memory ctor for tests.
  AppDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(rewardEvents);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _open() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'kvl.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
