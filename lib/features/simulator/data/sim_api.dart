import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_config.dart';

/// One provisioned simulated account: its bearer token + primary member id.
///
/// Sim accounts live in a reserved mobile range (see [SimApi.mobileBase]) so
/// they are trivially identifiable in the database for cleanup.
class SimUser {
  SimUser({
    required this.index,
    required this.mobile,
    required this.accessToken,
    required this.memberId,
  });

  final int index;
  final String mobile;
  final String accessToken;
  final String memberId;
  String? programId;

  /// Fractional-chant carry for real-time pacing (keeps the rate exact across
  /// sub-minute ticks instead of truncating every tick).
  double carry = 0;
}

/// Direct, interceptor-free API access for the load simulator.
///
/// This deliberately does NOT reuse [ApiClient] — that instance auto-injects
/// the *logged-in* user's token on every request. The simulator drives up to
/// thousands of distinct accounts, so each call carries its own bearer header.
class SimApi {
  SimApi()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 25),
          sendTimeout: const Duration(seconds: 25),
          responseType: ResponseType.json,
          headers: const {
            'accept': 'application/json',
            'content-type': 'application/json',
          },
        ),
      );

  final Dio _dio;
  static const _uuid = Uuid();

  /// First mobile number of the reserved simulator range. All sim accounts use
  /// `mobileBase + index`, e.g. 9900000000, 9900000001, … These pass the
  /// backend's `^[6-9]\d{9}$` validation and are easy to target for deletion.
  static const int mobileBase = 9900000000;
  static const String simPassword = 'SimLoad!2024';
  static const String namePrefix = 'SIM_';

  String mobileFor(int index) => (mobileBase + index).toString();

  String get baseUrl => ApiConfig.baseUrl;

  Options _auth(String token) =>
      Options(headers: {'authorization': 'Bearer $token'});

  /// Public catalog — used to pick a mantra for the generated programs.
  /// Returns a list of `{id, slug, name}` maps.
  Future<List<Map<String, String>>> fetchMantras() async {
    final res = await _dio.get<Map<String, Object?>>('/api/v1/mantras');
    final list = (res.data?['mantras'] as List?) ?? const [];
    return [
      for (final m in list)
        if (m is Map)
          {
            'id': (m['id'] ?? m['slug'] ?? '').toString(),
            'slug': (m['slug'] ?? '').toString(),
            'name': (m['nameRoman'] ?? m['name_roman'] ?? m['slug'] ?? '?')
                .toString(),
          },
    ];
  }

  /// Ensure a sim account exists and return a usable session for it.
  ///
  /// Tries register first; on 409 (already exists, e.g. a re-run) falls back to
  /// password login. Either way we end up with an access token + member id.
  Future<SimUser> provisionUser(int index) async {
    final mobile = mobileFor(index);
    Map<String, Object?>? body;
    try {
      final res = await _dio.post<Map<String, Object?>>(
        '/api/v1/auth/register',
        data: {
          'mobile': mobile,
          'username': '$namePrefix$index',
          'password': simPassword,
        },
      );
      body = res.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final res = await _dio.post<Map<String, Object?>>(
          '/api/v1/auth/password/login',
          data: {'mobile': mobile, 'password': simPassword},
        );
        body = res.data;
      } else {
        rethrow;
      }
    }

    final token = (body?['access_token'] ?? '').toString();
    final member =
        (body?['primary_member'] ?? body?['primaryMember']) as Map?;
    final memberId = (member?['id'] ?? '').toString();
    if (token.isEmpty || memberId.isEmpty) {
      throw StateError('provision failed for $mobile: missing token/member');
    }
    return SimUser(
      index: index,
      mobile: mobile,
      accessToken: token,
      memberId: memberId,
    );
  }

  /// Create a never-completing program for [user] and stash its id.
  /// `targetWritings` is set astronomically high so the backend never stamps
  /// `completedAt` mid-run.
  Future<void> createProgram(SimUser user, String mantraId) async {
    final programId = _uuid.v4();
    final res = await _dio.post<Map<String, Object?>>(
      '/api/v1/programs',
      data: {
        'programs': [
          {
            'id': programId,
            'member_id': user.memberId,
            'mantra_id': mantraId,
            'target_writings': 1000000000,
            'target_days': 365,
            'started_at': _nowIso(),
          },
        ],
      },
      options: _auth(user.accessToken),
    );
    final programs = (res.data?['programs'] as List?) ?? const [];
    final returnedId = programs.isNotEmpty && programs.first is Map
        ? (programs.first as Map)['id']?.toString()
        : null;
    user.programId = returnedId ?? programId;
  }

  /// Post a batch of sessions for a single user. Returns the count the server
  /// reports as created. Session ids are client-supplied UUIDs (idempotent).
  Future<int> postSessions(
    SimUser user, {
    required List<({DateTime start, DateTime end, int count})> sessions,
    required String modality,
  }) async {
    if (sessions.isEmpty || user.programId == null) return 0;
    final payload = [
      for (final s in sessions)
        {
          'id': _uuid.v4(),
          'member_id': user.memberId,
          'program_id': user.programId,
          'started_at': s.start.toUtc().toIso8601String(),
          'ended_at': s.end.toUtc().toIso8601String(),
          'duration_sec': s.end.difference(s.start).inSeconds.abs(),
          'count_added': s.count,
          'modality': modality,
        },
    ];
    final res = await _dio.post<Map<String, Object?>>(
      '/api/v1/sessions',
      data: {'sessions': payload},
      options: _auth(user.accessToken),
    );
    final created = res.data?['created'];
    return created is int ? created : sessions.length;
  }

  String _nowIso() => DateTime.now().toUtc().toIso8601String();
}
