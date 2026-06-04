import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_keys.dart';
import '../domain/mantra.dart';
import '../domain/mantra_repository.dart';
import 'mantra_dto.dart';
import 'mantra_seed.dart';

/// Hive cache key holding the last successful API payload (JSON map).
/// Stored as a JSON-encodable structure so it survives schema additions.
extension MantraCacheKeys on KvlKeys {
  static const remoteMantraPayload = 'remote.mantras.payload';
  static const remoteMantraFetchedAt = 'remote.mantras.fetchedAt';
}

/// Repository backed by the admin API at `/api/v1/mantras`.
///
/// Synchronous read API is preserved (existing call sites depend on it).
/// On construction the in-memory list is the *best* of:
///   1. an explicit `bootstrap` (cached from Hive on app launch)
///   2. the bundled seed
///
/// A background refresh fires on construction and on `refresh()`. Listeners
/// can subscribe to [stream] to react to fresh data.
class MantraRepositoryRemote implements MantraRepository {
  MantraRepositoryRemote({
    required ApiClient api,
    required Box<dynamic> cache,
    List<Mantra>? bootstrap,
  })  : _api = api,
        _cache = cache,
        _mantras = List.unmodifiable(bootstrap?.isNotEmpty == true ? bootstrap! : kMantraSeed) {
    _byId = {for (final m in _mantras) m.id: m};
    unawaited(refresh());
  }

  final ApiClient _api;
  final Box<dynamic> _cache;

  List<Mantra> _mantras;
  late Map<String, Mantra> _byId;

  final StreamController<List<Mantra>> _controller = StreamController.broadcast();

  /// Streams the catalog every time it's refreshed from the API.
  Stream<List<Mantra>> get stream => _controller.stream;

  @override
  List<Mantra> all() => _mantras;

  @override
  Mantra? byId(String id) => _byId[id];

  @override
  List<Mantra> recommendForNeed(MantraNeed need) {
    final wanted = _tagsFor(need);
    final ranked = _mantras
        .map((m) => (mantra: m, overlap: m.tags.intersection(wanted).length))
        .where((e) => e.overlap > 0)
        .toList()
      ..sort((a, b) => b.overlap.compareTo(a.overlap));
    return [for (final e in ranked) e.mantra];
  }

  /// Pull the latest catalog from the API. Updates the cache + in-memory
  /// view on success. Failures are swallowed (we keep showing what we had).
  Future<void> refresh() async {
    try {
      final res = await _api.dio.get<Map<String, Object?>>('/api/v1/mantras');
      final body = res.data;
      if (body == null) return;
      final list = (body['mantras'] as List?) ?? const [];
      final parsed = [
        for (final item in list) MantraDto.fromJson(item as Map<String, Object?>).toDomain(),
      ];
      if (parsed.isEmpty) return;

      _mantras = List.unmodifiable(parsed);
      _byId = {for (final m in _mantras) m.id: m};
      _controller.add(_mantras);

      await _cache.put(MantraCacheKeys.remoteMantraPayload, body);
      await _cache.put(MantraCacheKeys.remoteMantraFetchedAt, DateTime.now().toIso8601String());
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('[mantras] refresh failed: ${e.message}');
    } catch (e) {
      if (kDebugMode) debugPrint('[mantras] refresh error: $e');
    }
  }

  /// Decode whatever was cached on the last successful fetch.
  /// Returns null if no cache entry exists or it's malformed.
  static List<Mantra>? readCache(Box<dynamic> cache) {
    final raw = cache.get(MantraCacheKeys.remoteMantraPayload);
    if (raw is! Map) return null;
    final list = raw['mantras'];
    if (list is! List) return null;
    try {
      return [
        for (final item in list)
          MantraDto.fromJson(Map<String, Object?>.from(item as Map)).toDomain(),
      ];
    } catch (_) {
      return null;
    }
  }

  Set<MantraTag> _tagsFor(MantraNeed need) => switch (need) {
        MantraNeed.wealthProsperity => {MantraTag.wealth, MantraTag.prosperity},
        MantraNeed.peaceCalm => {MantraTag.peace},
        MantraNeed.healing => {MantraTag.healing},
        MantraNeed.protection => {MantraTag.protection},
        MantraNeed.strengthCourage => {MantraTag.strength, MantraTag.courage},
        MantraNeed.spiritualLiberation => {MantraTag.liberation},
        MantraNeed.wisdomEnlightenment => {MantraTag.wisdom, MantraTag.enlightenment},
        MantraNeed.devotion => {MantraTag.devotion},
      };
}
