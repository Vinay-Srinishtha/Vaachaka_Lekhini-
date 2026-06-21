import 'program.dart';
import 'session.dart';

abstract class ProgramRepository {
  Stream<List<Program>> watchForProfile(String memberId);
  Future<List<Program>> listForProfile(String memberId);
  Future<Program?> getById(String id);

  Future<Program> create({
    required String memberId,
    required String mantraId,
    required int targetWritings,
    required int targetDays,
  });

  /// Create a goal-less ("open") program so the user can start chanting
  /// immediately. On finish they either set a target (→ becomes a real
  /// program) or keep it as a Bonus Chants bucket. targetWritings/targetDays = 0.
  Future<Program> createOpen({
    required String memberId,
    required String mantraId,
  });

  /// Set (or change) the goal on an existing program — used to graduate an
  /// open/bonus program into a targeted one from the Finish flow.
  Future<Program> setTarget({
    required String programId,
    required int targetWritings,
    required int targetDays,
  });

  Future<void> update(Program program);
  Future<void> upsertRemote(Program program);
  Future<void> delete(String id);

  // --- Sessions ---
  Future<PracticeSession> startSession({
    required String programId,
    required String memberId,
    required SessionModality modality,
  });
  Future<void> incrementSession(String sessionId, {int by = 1});
  Future<PracticeSession> finishSession(String sessionId);
  Future<PracticeSession?> openSessionForProgram(String programId);
  Stream<List<PracticeSession>> watchSessionsForProgram(String programId);

  /// Calendar/dashboard aggregates.
  Future<Map<DateTime, int>> sessionCountsByDay({
    required String programId,
    required DateTime from,
    required DateTime to,
  });
  Future<DailySummary> dailySummary(String programId, DateTime day);

  /// Longest run of consecutive days with at least one session.
  Future<int> longestStreak(String programId);

  /// Run of consecutive days ending today (or yesterday if no session today
  /// yet) — i.e. the active streak.
  Future<int> currentStreak(String programId);

  /// Sum of session counts for [day]. Convenience over [dailySummary].
  Future<int> countForDay(String programId, DateTime day);

  /// Program with the most recent session for [profileId], or the most
  /// recently updated program if no sessions yet.
  Future<Program?> mostRecentlyActive(String memberId);

  /// Reconcile server-computed totals into local Drift (no outbox enqueue).
  /// Called after each /api/v1/me pull to keep program status live.
  Future<void> reconcileFromServer(
    String programId,
    int serverChants,
    int serverWritings,
  );

  /// Daily target helper — pure function so UI can preview before saving.
  static int computeDailyTarget(int targetWritings, int targetDays) {
    if (targetDays <= 0) return 0;
    return (targetWritings / targetDays).ceil();
  }
}
