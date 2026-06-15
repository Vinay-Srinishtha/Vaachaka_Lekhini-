import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/sync/sync_outbox.dart';
import '../domain/program.dart';
import '../domain/program_repository.dart';
import '../domain/session.dart';

class ProgramRepositoryDrift implements ProgramRepository {
  ProgramRepositoryDrift(this._db, this._outbox, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final SyncOutbox _outbox;
  final Uuid _uuid;

  // ---------------------------------------------------------------------------
  // Row → Domain mappers
  // ---------------------------------------------------------------------------

  Program _toProgram(ProgramRow row) => Program(
    id: row.id,
    memberId: row.memberId, // was profileId
    mantraId: row.mantraId,
    targetWritings: row.targetWritings,
    targetDays: row.targetDays,
    dailyTarget: row.dailyTarget,
    startedAt: row.startedAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    completedAt: row.completedAt, // was status
    currentStreak: row.currentStreak,
    longestStreak: row.longestStreak,
    lastActiveDate: row.lastActiveDate,
    totalChants: row.totalChants,
    totalWritings: row.totalWritings,
  );

  PracticeSession _toSession(SessionRow row) => PracticeSession(
    id: row.id,
    programId: row.programId,
    memberId: row.memberId, // ADDED
    startedAt: row.startedAt,
    createdAt: row.createdAt, // ADDED
    endedAt: row.endedAt,
    countAdded: row.countAdded, // was count
    durationSec: row.durationSec, // ADDED
    modality: SessionModality.fromName(row.modality),
    updatedAt: row.updatedAt,
  );

  // ---------------------------------------------------------------------------
  // Programs
  // ---------------------------------------------------------------------------

  @override
  Stream<List<Program>> watchForProfile(String memberId) {
    return (_db.select(_db.programs)
          ..where((t) => t.memberId.equals(memberId)) // was profileId
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(_toProgram).toList());
  }

  @override
  Future<List<Program>> listForProfile(String memberId) async {
    final rows =
        await (_db.select(_db.programs)
              ..where((t) => t.memberId.equals(memberId))
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
    required String memberId, // was profileId
    required String mantraId,
    required int targetWritings,
    required int targetDays,
  }) async {
    final now = DateTime.now();
    final program = Program(
      id: _uuid.v4(),
      memberId: memberId,
      mantraId: mantraId,
      targetWritings: targetWritings,
      targetDays: targetDays,
      dailyTarget: ProgramRepository.computeDailyTarget(
        targetWritings,
        targetDays,
      ),
      startedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await _db
        .into(_db.programs)
        .insert(
          ProgramsCompanion.insert(
            id: program.id,
            memberId: program.memberId,
            mantraId: program.mantraId,
            targetWritings: program.targetWritings,
            targetDays: program.targetDays,
            dailyTarget: program.dailyTarget,
            startedAt: program.startedAt,
            createdAt: program.createdAt,
            updatedAt: program.updatedAt,
          ),
        );

    // Queue to backend — Prisma will receive this and persist it
    await _outbox.enqueue('programs.upsert', _programPayload(program));
    return program;
  }

  @override
  Future<void> update(Program program) async {
    final now = DateTime.now();
    await (_db.update(
      _db.programs,
    )..where((t) => t.id.equals(program.id))).write(
      ProgramsCompanion(
        targetWritings: Value(program.targetWritings),
        targetDays: Value(program.targetDays),
        dailyTarget: Value(program.dailyTarget),
        completedAt: Value(program.completedAt),
        currentStreak: Value(program.currentStreak),
        longestStreak: Value(program.longestStreak),
        lastActiveDate: Value(program.lastActiveDate),
        totalChants: Value(program.totalChants),
        totalWritings: Value(program.totalWritings),
        updatedAt: Value(now),
      ),
    );
    await _outbox.enqueue(
      'programs.upsert',
      _programPayload(program.copyWith(updatedAt: now)),
    );
  }

  @override
  Future<void> upsertRemote(Program program) async {
    await _db
        .into(_db.programs)
        .insertOnConflictUpdate(
          ProgramsCompanion.insert(
            id: program.id,
            memberId: program.memberId,
            mantraId: program.mantraId,
            targetWritings: program.targetWritings,
            targetDays: program.targetDays,
            dailyTarget: program.dailyTarget,
            startedAt: program.startedAt,
            createdAt: program.createdAt,
            updatedAt: program.updatedAt,
            completedAt: Value(program.completedAt),
            currentStreak: Value(program.currentStreak),
            longestStreak: Value(program.longestStreak),
            lastActiveDate: Value(program.lastActiveDate),
            totalChants: Value(program.totalChants),
            totalWritings: Value(program.totalWritings),
            syncedAt: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.programs)..where((t) => t.id.equals(id))).go();
  }

  // ---------------------------------------------------------------------------
  // Sessions
  // ---------------------------------------------------------------------------

  @override
  Future<PracticeSession> startSession({
    required String programId,
    required String memberId, // ADDED — needed for Prisma Session.memberId
    required SessionModality modality,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db
        .into(_db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: id,
            programId: programId,
            memberId: memberId,
            startedAt: now,
            createdAt: now,
            modality: modality.name,
            updatedAt: now,
          ),
        );
    return PracticeSession(
      id: id,
      programId: programId,
      memberId: memberId,
      startedAt: now,
      createdAt: now,
      countAdded: 0,
      modality: modality,
      updatedAt: now,
    );
  }

  @override
  Future<void> incrementSession(String sessionId, {int by = 1}) async {
    await _db.customStatement(
      'UPDATE sessions SET count_added = count_added + ?, updated_at = ? WHERE id = ?',
      [by, DateTime.now().millisecondsSinceEpoch ~/ 1000, sessionId],
    );
  }

  @override
  Future<PracticeSession?> openSessionForProgram(String programId) async {
    final row =
        await (_db.select(_db.sessions)
              ..where((t) => t.programId.equals(programId) & t.endedAt.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toSession(row);
  }

  @override
  Future<PracticeSession> finishSession(String sessionId) async {
    final now = DateTime.now();
    await (_db.update(
      _db.sessions,
    )..where((t) => t.id.equals(sessionId))).write(
      SessionsCompanion(
        endedAt: Value(now),
        durationSec: Value(now.millisecondsSinceEpoch), // will be fixed below
        updatedAt: Value(now),
      ),
    );
    final row = await (_db.select(
      _db.sessions,
    )..where((t) => t.id.equals(sessionId))).getSingle();
    final session = _toSession(row);

    // Compute actual durationSec now that we know endedAt
    final durSec = session.endedAt!.difference(session.startedAt).inSeconds;
    await (_db.update(_db.sessions)..where((t) => t.id.equals(sessionId)))
        .write(SessionsCompanion(durationSec: Value(durSec)));

    // Roll countAdded into program totals
    final programRow = await (_db.select(
      _db.programs,
    )..where((t) => t.id.equals(session.programId))).getSingleOrNull();
    if (programRow != null) {
      final isHandwriting = session.modality == SessionModality.handwriting;
      final updatedProgram = isHandwriting
          ? ProgramsCompanion(
              totalWritings: Value(
                programRow.totalWritings + session.countAdded,
              ),
              completedAt: Value(
                programRow.totalWritings +
                            programRow.totalChants +
                            session.countAdded >=
                        programRow.targetWritings
                    ? (programRow.completedAt ?? now)
                    : null,
              ),
              lastActiveDate: Value(now),
              updatedAt: Value(now),
            )
          : ProgramsCompanion(
              totalChants: Value(programRow.totalChants + session.countAdded),
              completedAt: Value(
                programRow.totalWritings +
                            programRow.totalChants +
                            session.countAdded >=
                        programRow.targetWritings
                    ? (programRow.completedAt ?? now)
                    : null,
              ),
              lastActiveDate: Value(now),
              updatedAt: Value(now),
            );
      await (_db.update(
        _db.programs,
      )..where((t) => t.id.equals(session.programId))).write(updatedProgram);

      // Recompute streak from local session history so the UI reflects it
      // immediately without waiting for a server pull.
      final allSessions =
          await (_db.select(_db.sessions)
                ..where((t) => t.programId.equals(session.programId))
                ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
              .get();
      final activeDays =
          allSessions
              .where((s) => s.endedAt != null)
              .map(
                (s) => DateTime(
                  s.startedAt.year,
                  s.startedAt.month,
                  s.startedAt.day,
                ),
              )
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));
      int streak = 0;
      DateTime? cursor;
      for (final d in activeDays) {
        if (cursor == null) {
          final todayDate = DateTime(now.year, now.month, now.day);
          if (d == todayDate ||
              d == todayDate.subtract(const Duration(days: 1))) {
            streak = 1;
            cursor = d;
          } else {
            break;
          }
        } else if (cursor.difference(d).inDays == 1) {
          streak++;
          cursor = d;
        } else {
          break;
        }
      }
      final currentProgramRow = await (_db.select(
        _db.programs,
      )..where((t) => t.id.equals(session.programId))).getSingle();
      final newLongest = streak > currentProgramRow.longestStreak
          ? streak
          : currentProgramRow.longestStreak;
      await (_db.update(
        _db.programs,
      )..where((t) => t.id.equals(session.programId))).write(
        ProgramsCompanion(
          currentStreak: Value(streak),
          longestStreak: Value(newLongest),
        ),
      );

      // Queue finished session to backend (Prisma sessions.append)
      await _outbox.enqueue('sessions.append', {
        'id': session.id,
        'program_id': session.programId,
        'member_id': session.memberId,
        'modality': session.modality.name,
        'count_added': session.countAdded,
        'duration_sec': durSec,
        'started_at': session.startedAt.toUtc().toIso8601String(),
        'ended_at': now.toUtc().toIso8601String(),
      });

      // Queue updated program totals to backend
      final updatedProgramRow = await (_db.select(
        _db.programs,
      )..where((t) => t.id.equals(session.programId))).getSingle();
      await _outbox.enqueue(
        'programs.upsert',
        _programPayload(_toProgram(updatedProgramRow)),
      );
    }

    return session.copyWith(durationSec: durSec, endedAt: now);
  }

  @override
  Stream<List<PracticeSession>> watchSessionsForProgram(String programId) {
    return (_db.select(_db.sessions)
          ..where((t) => t.programId.equals(programId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch()
        .map((rows) => rows.map(_toSession).toList());
  }

  // ---------------------------------------------------------------------------
  // Aggregates
  // ---------------------------------------------------------------------------

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
      out[day] = (out[day] ?? 0) + s.countAdded; // was s.count
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
    final total = rows.fold<int>(0, (a, b) => a + b.countAdded); // was b.count
    // usedHandwriting is now derived from modality
    final usedHandwriting = rows.any(
      (r) => r.modality == SessionModality.handwriting.name,
    );
    return DailySummary(
      day: start,
      dailyTarget: program?.dailyTarget ?? 0,
      actualAchieved: total,
      usedHandwriting: usedHandwriting,
    );
  }

  @override
  Future<int> currentStreak(String programId) async {
    // Read from the stored column (kept in sync with backend)
    final row = await (_db.select(
      _db.programs,
    )..where((t) => t.id.equals(programId))).getSingleOrNull();
    return row?.currentStreak ?? 0;
  }

  @override
  Future<int> longestStreak(String programId) async {
    final row = await (_db.select(
      _db.programs,
    )..where((t) => t.id.equals(programId))).getSingleOrNull();
    return row?.longestStreak ?? 0;
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
    return rows.fold<int>(0, (a, b) => a + b.countAdded); // was b.count
  }

  @override
  Future<Program?> mostRecentlyActive(String memberId) async {
    final session =
        await (_db.select(_db.sessions).join([
                innerJoin(
                  _db.programs,
                  _db.programs.id.equalsExp(_db.sessions.programId),
                ),
              ])
              ..where(_db.programs.memberId.equals(memberId)) // was profileId
              ..orderBy([OrderingTerm.desc(_db.sessions.startedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (session != null) {
      return _toProgram(session.readTable(_db.programs));
    }
    final p =
        await (_db.select(_db.programs)
              ..where((t) => t.memberId.equals(memberId))
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    return p == null ? null : _toProgram(p);
  }

  @override
  Future<void> reconcileFromServer(
    String programId,
    int serverChants,
    int serverWritings,
  ) async {
    final row = await (_db.select(
      _db.programs,
    )..where((t) => t.id.equals(programId))).getSingleOrNull();
    if (row == null) return;
    // Only write if server has higher values — never overwrite with stale data.
    if (serverChants <= row.totalChants &&
        serverWritings <= row.totalWritings) {
      return;
    }
    await (_db.update(
      _db.programs,
    )..where((t) => t.id.equals(programId))).write(
      ProgramsCompanion(
        totalChants: serverChants > row.totalChants
            ? Value(serverChants)
            : const Value.absent(),
        totalWritings: serverWritings > row.totalWritings
            ? Value(serverWritings)
            : const Value.absent(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Outbox payload helpers — field names match Prisma column names exactly
  // ---------------------------------------------------------------------------

  // NOTE: total_writings, current_streak, and longest_streak are intentionally
  // omitted. The server recomputes them from the Session table in
  // /api/v1/sessions after each batch. Sending client-computed values would
  // allow a tampered app to overwrite authoritative server aggregates.
  Map<String, Object?> _programPayload(Program p) => {
    'id': p.id,
    'member_id': p.memberId,
    'mantra_id': p.mantraId,
    'target_writings': p.targetWritings > 0 ? p.targetWritings : 1,
    'target_days': p.targetDays > 0 ? p.targetDays : 1,
    'last_active_date': p.lastActiveDate?.toUtc().toIso8601String(),
    'completed_at': p.completedAt?.toUtc().toIso8601String(),
    'started_at': p.startedAt.toUtc().toIso8601String(),
    'total_chants': p.totalChants,
    'total_writings': p.totalWritings,
  };
}

// Extension so PracticeSession can be copied with new fields after finishSession
extension _SessionCopy on PracticeSession {
  PracticeSession copyWith({int? durationSec, DateTime? endedAt}) =>
      PracticeSession(
        id: id,
        programId: programId,
        memberId: memberId,
        startedAt: startedAt,
        createdAt: createdAt,
        endedAt: endedAt ?? this.endedAt,
        countAdded: countAdded,
        durationSec: durationSec ?? this.durationSec,
        modality: modality,
        updatedAt: updatedAt,
      );
}
