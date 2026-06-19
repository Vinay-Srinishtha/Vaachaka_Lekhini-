import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../core/api/api_client.dart';
import '../domain/quote.dart';

const _cacheKey = 'quotes.active_list';

class QuoteRepository {
  const QuoteRepository({required this.api, required this.cache});

  final ApiClient api;
  final Box<dynamic> cache;

  Future<List<Quote>> fetchActive({List<String> mantraIds = const []}) async {
    List<Quote>? result;
    try {
      final query = mantraIds.isEmpty ? '' : '?mantra_ids=${mantraIds.join(',')}';
      final res = await api.dio.get<Map<String, dynamic>>('/api/v1/quotes$query');
      final list = (res.data?['quotes'] as List<dynamic>?) ?? [];
      await cache.put(_cacheKey, list);
      result = list
          .map((e) => Quote.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      // Fall through to cache.
    }
    return result ?? _fromCache();
  }

  List<Quote> cachedQuotes() => _fromCache();

  List<Quote> _fromCache() {
    final raw = cache.get(_cacheKey);
    if (raw is! List) return const [];
    return raw
        .map((e) => Quote.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
