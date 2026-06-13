import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// One row per program — mirrors Prisma `Program` table exactly.
/// [memberId] = Prisma Member.id (was profileId in v2).
/// [completedAt] replaces the old `status` text column — null = active/paused,
/// non-null = completed (matches Prisma's nullable completedAt timestamp).
/// [currentStreak] / [longestStreak] are maintained locally and synced;
/// the backend is the authoritative source on pull.
/// [dailyTarget] is a local computed field (targetWritings / targetDays) — not
/// in Prisma but kept here so the UI doesn't recompute on every render.
@DataClassName('ProgramRow')
class Programs extends Table {
  TextColumn get id => text()();
  // CHANGED: profileId → memberId (Prisma field name)
  TextColumn get memberId => text()();
  TextColumn get mantraId => text()();
  IntColumn get targetWritings => integer()();
  IntColumn get targetDays => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  // Local helper — not in Prisma, kept for UI convenience
  IntColumn get dailyTarget => integer()();
  // CHANGED: status text → completedAt nullable (matches Prisma)
  DateTimeColumn get completedAt => dateTime().nullable()();
  // ADDED: streak fields (Prisma tracks these on the Program row)
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastActiveDate => dateTime().nullable()();
  // totalChants kept locally so voice vs writing is distinguishable in the UI;
  // only totalWritings (= chants + writings) is sent to Prisma.
  IntColumn get totalChants => integer().withDefault(const Constant(0))();
  IntColumn get totalWritings => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One row per practice session — mirrors Prisma `Session` table.
/// [countAdded] was `count` in v2 (Prisma calls it countAdded).
/// [memberId] added so we can post to Prisma without a join.
/// [durationSec] added (Prisma tracks session length).
/// [usedHandwriting] removed — modality == 'handwriting' covers it.
@DataClassName('SessionRow')
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get programId => text().customConstraint('NOT NULL REFERENCES programs(id) ON DELETE CASCADE')();
  // ADDED: memberId (Prisma Session has memberId directly)
  TextColumn get memberId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  // CHANGED: count → countAdded (Prisma field name)
  IntColumn get countAdded => integer().withDefault(const Constant(0))();
  // ADDED: session length in seconds (Prisma field)
  IntColumn get durationSec => integer().withDefault(const Constant(0))();
  /// 'voice' | 'manual' | 'handwriting'
  TextColumn get modality => text()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One line in the reward ledger — mirrors Prisma `RewardEvent` table.
/// [memberId] was profileId in v2.
/// [occurredAt] was createdAt in v2 (Prisma field name).
/// [storeItemId] added (nullable FK to StoreItem in Prisma).
@DataClassName('RewardEventRow')
class RewardEvents extends Table {
  TextColumn get id => text()();
  // CHANGED: profileId → memberId (Prisma field name)
  TextColumn get memberId => text()();
  // ADDED: nullable link to the store item that was redeemed
  TextColumn get storeItemId => text().nullable()();
  /// 'earn' | 'spend'
  TextColumn get kind => text()();
  IntColumn get amount => integer()();
  TextColumn get source => text()();
  // CHANGED: createdAt → occurredAt (Prisma field name)
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One row per active (unsaved) practice session — survives app kills.
/// Deleted when the user finishes the session or discards the draft.
@DataClassName('DraftRow')
class PracticeSessionDrafts extends Table {
  TextColumn get programId => text()();
  IntColumn get sessionCount => integer()();
  TextColumn get modality => text()();
  IntColumn get savedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {programId};
}

@DriftDatabase(tables: [Programs, Sessions, RewardEvents, PracticeSessionDrafts])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  /// In-memory ctor for tests.
  AppDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2→v3: column renames + new columns across all 3 tables.
          // SQLite cannot rename columns, so we drop and recreate.
          if (from < 3) {
            await m.drop(sessions);
            await m.drop(rewardEvents);
            await m.drop(programs);
            await m.createAll();
            return;
          }
          // v3→v4: add practice_session_drafts table (non-destructive).
          if (from < 4) {
            await m.createTable(practiceSessionDrafts);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> saveDraft({
    required String programId,
    required int count,
    required String modality,
  }) =>
      into(practiceSessionDrafts).insertOnConflictUpdate(
        PracticeSessionDraftsCompanion.insert(
          programId: programId,
          sessionCount: count,
          modality: modality,
          savedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  Future<DraftRow?> getDraft(String programId) =>
      (select(practiceSessionDrafts)
            ..where((d) => d.programId.equals(programId)))
          .getSingleOrNull();

  Future<void> deleteDraft(String programId) =>
      (delete(practiceSessionDrafts)
            ..where((d) => d.programId.equals(programId)))
          .go();

  static QueryExecutor _open() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'kvl.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
