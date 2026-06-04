import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../api/api_client.dart';
import '../storage/storage_keys.dart';
import 'remote_config.dart';
import 'remote_config_repository.dart';

/// Cache key in the shared `kvl_cache` Hive box.
extension RemoteConfigCacheKeys on KvlKeys {
  static const remoteConfigPayload = 'remote.config.payload';
  static const remoteConfigFetchedAt = 'remote.config.fetchedAt';
}

class RemoteConfigRepositoryRemote implements RemoteConfigRepository {
  RemoteConfigRepositoryRemote({
    required ApiClient api,
    required Box<dynamic> cache,
    RemoteConfig? bootstrap,
  })  : _api = api,
        _cache = cache,
        _current = bootstrap ?? RemoteConfig.empty {
    unawaited(refresh());
  }

  final ApiClient _api;
  final Box<dynamic> _cache;
  RemoteConfig _current;

  final StreamController<RemoteConfig> _controller = StreamController.broadcast();

  @override
  RemoteConfig current() => _current;

  @override
  Stream<RemoteConfig> watch() => _controller.stream;

  @override
  Future<void> refresh() async {
    try {
      final res = await _api.dio.get<Map<String, Object?>>('/api/v1/config');
      final body = res.data;
      if (body == null) return;
      final configRaw = body['config'];
      if (configRaw is! Map) return;

      final values = Map<String, Object?>.from(configRaw);
      _current = RemoteConfig(values, fetchedAt: DateTime.now());
      _controller.add(_current);

      await _cache.put(RemoteConfigCacheKeys.remoteConfigPayload, body);
      await _cache.put(
        RemoteConfigCacheKeys.remoteConfigFetchedAt,
        DateTime.now().toIso8601String(),
      );
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('[remote-config] refresh failed: ${e.message}');
    } catch (e) {
      if (kDebugMode) debugPrint('[remote-config] refresh error: $e');
    }
  }

  /// Read the previously-cached payload from Hive, if any. Returns
  /// [RemoteConfig.empty] when no usable cache exists.
  static RemoteConfig readCache(Box<dynamic> cache) {
    final raw = cache.get(RemoteConfigCacheKeys.remoteConfigPayload);
    if (raw is! Map) return RemoteConfig.empty;
    final configRaw = raw['config'];
    if (configRaw is! Map) return RemoteConfig.empty;
    final fetchedAtRaw = cache.get(RemoteConfigCacheKeys.remoteConfigFetchedAt);
    final fetchedAt = fetchedAtRaw is String ? DateTime.tryParse(fetchedAtRaw) : null;
    return RemoteConfig(Map<String, Object?>.from(configRaw), fetchedAt: fetchedAt);
  }
}
