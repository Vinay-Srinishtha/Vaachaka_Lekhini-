import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../core/api/api_client.dart';
import '../domain/global_sadhana.dart';

const _cacheKey = 'global_sadhana.active_list';
const _enrollmentPrefix = 'global_sadhana.enrollment.';

class GlobalSadhanaRepository {
  const GlobalSadhanaRepository({required this.api, required this.cache});

  final ApiClient api;
  final Box<dynamic> cache;

  // ── List ──────────────────────────────────────────────────────────────────

  /// Returns active global sadhanas. Uses Hive cache for instant first render,
  /// then fetches from network and updates the cache.
  Future<List<GlobalSadhana>> fetchActive() async {
    List<GlobalSadhana>? result;
    try {
      final res = await api.dio.get<Map<String, dynamic>>(
        '/api/v1/global-sadhanas?status=active',
      );
      final list = (res.data?['sadhanas'] as List<dynamic>?) ?? [];
      await cache.put(_cacheKey, list);
      result = list
          .map((e) =>
              GlobalSadhana.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      // Fall through to cache.
    }
    return result ?? cachedActive();
  }

  List<GlobalSadhana> cachedActive() {
    final raw = cache.get(_cacheKey);
    if (raw is! List) return const [];
    return raw
        .map((e) =>
            GlobalSadhana.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Optimistically bump the cached global count + the user's contribution for
  /// every active sadhana the user is enrolled in for [mantraId]. Lets the UI
  /// reflect a just-finished practice session instantly, before the server
  /// round-trip credits it for real. Returns true if anything was updated.
  Future<bool> applyLocalContribution({
    required String mantraId,
    required int count,
  }) async {
    if (count <= 0) return false;
    final raw = cache.get(_cacheKey);
    if (raw is! List) return false;
    var changed = false;
    final updated = raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      if (m['mantra_id'] == mantraId && m['status'] == 'active') {
        final sadhanaId = m['id'] as String?;
        // Only credit sadhanas the user has actually joined.
        if (sadhanaId != null && cachedEnrollment(sadhanaId) != null) {
          m['current_count'] =
              ((m['current_count'] as num?)?.toInt() ?? 0) + count;
          final enrRaw = cache.get('$_enrollmentPrefix$sadhanaId');
          if (enrRaw is Map) {
            final em = Map<String, dynamic>.from(enrRaw);
            em['my_contribution'] =
                ((em['my_contribution'] as num?)?.toInt() ?? 0) + count;
            cache.put('$_enrollmentPrefix$sadhanaId', em);
          }
          changed = true;
        }
      }
      return m;
    }).toList();
    if (changed) await cache.put(_cacheKey, updated);
    return changed;
  }

  // ── Enrollment ─────────────────────────────────────────────────────────────

  GlobalSadhanaEnrollment? cachedEnrollment(String sadhanaId) {
    final raw = cache.get('$_enrollmentPrefix$sadhanaId');
    if (raw is! Map) return null;
    return GlobalSadhanaEnrollment.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<GlobalSadhanaEnrollment?> fetchEnrollment(
    String sadhanaId,
    String memberId,
  ) async {
    try {
      final res = await api.dio.get<Map<String, dynamic>>(
        '/api/v1/global-sadhanas/$sadhanaId?member_id=$memberId',
      );
      final enr = res.data?['sadhana']?['enrollment'];
      if (enr == null) return null;
      final e = GlobalSadhanaEnrollment.fromJson(
        Map<String, dynamic>.from(enr as Map),
      );
      await cache.put('$_enrollmentPrefix$sadhanaId', enr);
      return e;
    } catch (_) {
      return cachedEnrollment(sadhanaId);
    }
  }

  /// Enroll a member. Returns the enrollment or throws on failure.
  Future<GlobalSadhanaEnrollment> enroll({
    required String sadhanaId,
    required String memberId,
    bool voiceTrainingComplete = false,
    bool handwritingTrainingComplete = false,
  }) async {
    final res = await api.dio.post<Map<String, dynamic>>(
      '/api/v1/global-sadhanas/$sadhanaId/enroll',
      data: {
        'member_id': memberId,
        'voice_training_complete': voiceTrainingComplete,
        'handwriting_training_complete': handwritingTrainingComplete,
      },
    );
    final enrMap = res.data!['enrollment'] as Map;
    final enr = GlobalSadhanaEnrollment.fromJson(
      Map<String, dynamic>.from(enrMap),
    );
    await cache.put('$_enrollmentPrefix$sadhanaId', enrMap);
    return enr;
  }

  /// Update training flags after voice/handwriting training completes.
  Future<void> updateTrainingFlags({
    required String sadhanaId,
    required String memberId,
    bool? voiceComplete,
    bool? handwritingComplete,
  }) async {
    final current = cachedEnrollment(sadhanaId);
    if (current == null) return;
    try {
      await enroll(
        sadhanaId: sadhanaId,
        memberId: memberId,
        voiceTrainingComplete: voiceComplete ?? current.voiceTrainingComplete,
        handwritingTrainingComplete:
            handwritingComplete ?? current.handwritingTrainingComplete,
      );
    } catch (_) {
      // Best-effort update; the server will reflect the true state on next pull.
    }
  }

  // ── Refresh detail ─────────────────────────────────────────────────────────

  Future<GlobalSadhana?> fetchById(String id) async {
    try {
      final res = await api.dio
          .get<Map<String, dynamic>>('/api/v1/global-sadhanas/$id');
      final raw = res.data?['sadhana'];
      if (raw == null) return null;
      return GlobalSadhana.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (_) {
      return null;
    }
  }
}
