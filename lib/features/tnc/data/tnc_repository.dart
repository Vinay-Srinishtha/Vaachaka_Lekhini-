import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/tnc.dart';

class TncRepository {
  TncRepository(this._ref);
  final Ref _ref;

  Future<TermsAndConditions?> fetchCurrent() async {
    try {
      final api = _ref.read(apiClientProvider);
      final res = await api.dio.get<Map<String, dynamic>>('/api/v1/tnc/current');
      final data = res.data;
      if (data == null) return null;
      return TermsAndConditions.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> accept(String tncId) async {
    final api = _ref.read(apiClientProvider);
    await api.dio.post<void>(
      '/api/v1/tnc/accept',
      data: {'tnc_id': tncId},
    );
  }
}
