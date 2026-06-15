import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_storage.dart';
import '../auth/auth_tokens.dart';
import 'api_config.dart';

/// Shared Dio instance for the KVL public API (`/api/v1/*`).
///
/// Wires two interceptors:
///   • injects `Authorization: Bearer <access_token>` on protected paths
///   • on 401, calls /api/v1/auth/refresh once and retries the original
///   • on 403, clears stored tokens so the session stream triggers logout
///
/// The auth-storage dependency is read on every call — no caching — so
/// fresh tokens written by [AuthService] take effect immediately without
/// rebuilding the client.
class ApiClient {
  ApiClient._(this.dio);

  final Dio dio;

  static ApiClient? _instance;
  static AuthStorage? _authStorage;
  static bool _refreshInFlight = false;

  /// Inject the storage so the auth interceptor can read + rewrite tokens.
  /// Call once at bootstrap before any request goes out.
  static void useAuthStorage(AuthStorage storage) {
    _authStorage = storage;
  }

  factory ApiClient() {
    return _instance ??= ApiClient._(_buildDio());
  }

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 5),
        responseType: ResponseType.json,
        headers: const {'accept': 'application/json'},
      ),
    );
    dio.interceptors.add(_AuthInterceptor());
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
          logPrint: (o) => debugPrint('[api] $o'),
        ),
      );
    }
    return dio;
  }
}

/// Paths that never carry a bearer token. Anything else gets the access token
/// auto-attached if one is stored.
bool _isUnauthed(String path) {
  return path.startsWith('/api/v1/auth/') ||
      path == '/api/v1/mantras' ||
      path == '/api/v1/store' ||
      path == '/api/v1/config' ||
      path == '/api/v1/stats';
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final storage = ApiClient._authStorage;
    if (storage != null && !_isUnauthed(options.path)) {
      final tokens = await storage.readTokens();
      if (tokens != null) {
        options.headers['authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final storage = ApiClient._authStorage;

    // 403 = account banned mid-session. Clear stored tokens immediately so
    // the session stream transitions to unauthenticated and the router
    // redirects to the login screen with the ban message.
    if (response?.statusCode == 403 &&
        storage != null &&
        !_isUnauthed(err.requestOptions.path)) {
      await storage.clear();
      if (kDebugMode) debugPrint('[api] 403 received — tokens cleared (account banned)');
      return handler.next(err);
    }

    final shouldTryRefresh = response?.statusCode == 401 &&
        storage != null &&
        !_isUnauthed(err.requestOptions.path) &&
        err.requestOptions.extra['__retried'] != true &&
        !ApiClient._refreshInFlight;
    if (!shouldTryRefresh) return handler.next(err);

    ApiClient._refreshInFlight = true;
    try {
      final tokens = await storage.readTokens();
      if (tokens == null) return handler.next(err);

      final dio = ApiClient().dio;
      final refreshRes = await dio.post<Map<String, Object?>>(
        '/api/v1/auth/refresh',
        data: {'refresh_token': tokens.refreshToken},
        options: Options(headers: {'authorization': null}),
      );
      final body = refreshRes.data;
      if (body == null) return handler.next(err);

      final next = AuthTokens.fromJson(body);
      await storage.writeTokens(next);

      // Retry the original request once with the new access token.
      err.requestOptions.headers['authorization'] = 'Bearer ${next.accessToken}';
      err.requestOptions.extra['__retried'] = true;
      final retried = await dio.fetch<dynamic>(err.requestOptions);
      return handler.resolve(retried);
    } on DioException catch (refreshErr) {
      if (kDebugMode) debugPrint('[api] refresh failed: ${refreshErr.message}');
    } finally {
      ApiClient._refreshInFlight = false;
    }

    return handler.next(err);
  }
}
