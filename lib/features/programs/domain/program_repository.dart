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

  Future<void> update(Program program);
  Future<void> delete(String id);

  // --- Sessions ---
  Future<PracticeSession> startSession({
    required String programId,
    required String memberId,
    required SessionModality modality,
  });
  Future<void> incrementSession(String sessionId, {int by = 1});
  Future<PracticeSession> finishSession(String sessionId);
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

  /// Daily target helper — pure function so UI can preview before saving.
  static int computeDailyTarget(int targetWritings, int targetDays) {
    if (targetDays <= 0) return 0;
    return (targetWritings / targetDays).ceil();
  }
}
