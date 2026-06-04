import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/program.dart';
import '../domain/program_repository.dart';
import '../domain/session.dart';

class ProgramRepositoryDrift implements ProgramRepository {
  ProgramRepositoryDrift(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  // --- Programs ---

  Program _toProgram(ProgramRow row) => Program(
    id: row.id,
    profileId: row.profileId,
    mantraId: row.mantraId,
    targetWritings: row.targetWritings,
    targetDays: row.targetDays,
    dailyTarget: row.dailyTarget,
    startedAt: row.startedAt,
    status: ProgramStatus.fromName(row.status),
    totalChants: row.totalChants,
    totalWritings: row.totalWritings,
    updatedAt: row.updatedAt,
  );

  @override
  Stream<List<Program>> watchForProfile(String profileId) {
    return (_db.select(_db.programs)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(_toProgram).toList());
  }

  @override
  Future<List<Program>> listForProfile(String profileId) async {
    final rows =
        await (_db.select(_db.programs)
              ..where((t) => t.profileId.equals(profileId))
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .get();
    return rows.map(_toProgram).toList();
  }

  @override
  Future<Program?> getById(String id) async {
    final row = await (_db.select(
      _db.programs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toProgram(row);
  }

  @override
  Future<Program> create({
    required String profileId,
    required String mantraId,
    required int targetWritings,
    required int targetDays,
  }) async {
    final now = DateTime.now();
    final program = Program(
      id: _uuid.v4(),
      profileId: profileId,
      mantraId: mantraId,
      targetWritings: targetWritings,
      targetDays: targetDays,
      dailyTarget: ProgramRepository.computeDailyTarget(
        targetWritings,
        targetDays,
      ),
      startedAt: now,
      status: ProgramStatus.active,
      totalChants: 0,
      totalWritings: 0,
      updatedAt: now,
    );
    await _db
        .into(_db.programs)
        .insert(
          ProgramsCompanion.insert(
            id: program.id,
            profileId: program.profileId,
            mantraId: program.mantraId,
            targetWritings: program.targetWritings,
            targetDays: program.targetDays,
            dailyTarget: program.dailyTarget,
            startedAt: program.startedAt,
            updatedAt: program.updatedAt,
          ),
        );
    return program;
  }

  @override
  Future<void> update(Program program) async {
    await (_db.update(
      _db.programs,
    )..where((t) => t.id.equals(program.id))).write(
      ProgramsCompanion(
        targetWritings: Value(program.targetWritings),
        targetDays: Value(program.targetDays),
        dailyTarget: Value(program.dailyTarget),
        status: Value(program.status.name),
        totalChants: Value(program.totalChants),
        totalWritings: Value(program.totalWritings),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.programs)..where((t) => t.id.equals(id))).go();
  }

  // --- Sessions ---

  PracticeSession _toSession(SessionRow row) => PracticeSession(
    id: row.id,
    programId: row.programId,
    startedAt: row.startedAt,
    endedAt: row.endedAt,
    count: row.count,
    modality: SessionModality.fromName(row.modality),
    usedHandwriting: row.usedHandwriting,
    updatedAt: row.updatedAt,
  );

  @override
  Future<PracticeSession> startSession({
    required String programId,
    required SessionModality modality,
    bool usedHandwriting = false,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db
        .into(_db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: id,
            programId: programId,
            startedAt: now,
            modality: modality.name,
            usedHandwriting: Value(usedHandwriting),
            updatedAt: now,
          ),
        );
    return PracticeSession(
      id: id,
      programId: programId,
      startedAt: now,
      count: 0,
      modality: modality,
      usedHandwriting: usedHandwriting,
      updatedAt: now,
    );
  }

  @override
  Future<void> incrementSession(String sessionId, {int by = 1}) async {
    await _db.customStatement(
      'UPDATE sessions SET count = count + ?, updated_at = ? WHERE id = ?',
      [by, DateTime.now().millisecondsSinceEpoch ~/ 1000, sessionId],
    );
  }

  @override
  Future<PracticeSession> finishSession(String sessionId) async {
    final now = DateTime.now();
    await (_db.update(_db.sessions)..where((t) => t.id.equals(sessionId)))
        .write(SessionsCompanion(endedAt: Value(now), updatedAt: Value(now)));
    final row = await (_db.select(
      _db.sessions,
    )..where((t) => t.id.equals(sessionId))).getSingle();
    final session = _toSession(row);
    // Roll the count into the program's totals.
    final programRow = await (_db.select(
      _db.programs,
    )..where((t) => t.id.equals(session.programId))).getSingleOrNull();
    if (programRow != null) {
      final updates =
          session.modality == SessionModality.handwriting ||
              session.usedHandwriting
          ? ProgramsCompanion(
              totalWritings: Value(programRow.totalWritings + session.count),
              updatedAt: Value(now),
            )
          : ProgramsCompanion(
              totalChants: Value(programRow.totalChants + session.count),
              updatedAt: Value(now),
            );
      await (_db.update(
        _db.programs,
      )..where((t) => t.id.equals(session.programId))).write(updates);
    }
    return session;
  }

  @override
  Stream<List<PracticeSession>> watchSessionsForProgram(String programId) {
    return (_db.select(_db.sessions)
          ..where((t) => t.programId.equals(programId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch()
        .map((rows) => rows.map(_toSession).toList());
  }

  // --- Aggregates ---

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<Map<DateTime, int>> sessionCountsByDay({
    required String programId,
    required DateTime from,
    required DateTime to,
  }) async {
    final sessions =
        await (_db.select(_db.sessions)..where(
              (t) =>
                  t.programId.equals(programId) &
                  t.startedAt.isBiggerOrEqualValue(from) &
                  t.startedAt.isSmallerThanValue(
                    to.add(const Duration(days: 1)),
                  ),
            ))
            .get();
    final out = <DateTime, int>{};
    for (final s in sessions) {
      final day = _startOfDay(s.startedAt);
      out[day] = (out[day] ?? 0) + s.count;
    }
    return out;
  }

  @override
  Future<DailySummary> dailySummary(String programId, DateTime day) async {
    final program = await getById(programId);
    final start = _startOfDay(day);
    final end = start.add(const Duration(days: 1));
    final rows =
        await (_db.select(_db.sessions)..where(
              (t) =>
                  t.programId.equals(programId) &
                  t.startedAt.isBiggerOrEqualValue(start) &
                  t.startedAt.isSmallerThanValue(end),
            ))
            .get();
    final total = rows.fold<int>(0, (a, b) => a + b.count);
    final usedHandwriting = rows.any((r) => r.usedHandwriting);
    return DailySummary(
      day: start,
      dailyTarget: program?.dailyTarget ?? 0,
      actualAchieved: total,
      usedHandwriting: usedHandwriting,
    );
  }

  @override
  Future<int> currentStreak(String programId) async {
    final rows =
        await (_db.select(_db.sessions)
              ..where((t) => t.programId.equals(programId))
              ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
            .get();
    if (rows.isEmpty) return 0;
    final today = _startOfDay(DateTime.now());
    final days = rows.map((r) => _startOfDay(r.startedAt)).toSet();
    // Allow the streak to count from yesterday if today hasn't been practised yet.
    var cursor = days.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    if (!days.contains(cursor)) return 0;
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Future<int> countForDay(String programId, DateTime day) async {
    final start = _startOfDay(day);
    final end = start.add(const Duration(days: 1));
    final rows =
        await (_db.select(_db.sessions)..where(
              (t) =>
                  t.programId.equals(programId) &
                  t.startedAt.isBiggerOrEqualValue(start) &
                  t.startedAt.isSmallerThanValue(end),
            ))
            .get();
    return rows.fold<int>(0, (a, b) => a + b.count);
  }

  @override
  Future<Program?> mostRecentlyActive(String profileId) async {
    // Most recent session for any of the user's programs, joined to a Program row.
    final session =
        await (_db.select(_db.sessions).join([
                innerJoin(
                  _db.programs,
                  _db.programs.id.equalsExp(_db.sessions.programId),
                ),
              ])
              ..where(_db.programs.profileId.equals(profileId))
              ..orderBy([OrderingTerm.desc(_db.sessions.startedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (session != null) {
      return _toProgram(session.readTable(_db.programs));
    }
    // Fallback: most recently updated program.
    final p =
        await (_db.select(_db.programs)
              ..where((t) => t.profileId.equals(profileId))
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    return p == null ? null : _toProgram(p);
  }

  @override
  Future<int> longestStreak(String programId) async {
    final rows =
        await (_db.select(_db.sessions)
              ..where((t) => t.programId.equals(programId))
              ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
            .get();
    if (rows.isEmpty) return 0;
    final days = rows.map((r) => _startOfDay(r.startedAt)).toSet().toList()
      ..sort();
    var longest = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }
}
