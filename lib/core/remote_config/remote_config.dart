/// Strongly-typed view over the flat key→value map served by
/// `/api/v1/config`. Use the [flag] accessor and pass a fallback so the
/// app never crashes if a key is removed by the admin.
class RemoteConfig {
  const RemoteConfig(this._values, {this.fetchedAt});

  /// Convenience: an empty config — used while bootstrapping before the
  /// first cache load.
  static const RemoteConfig empty = RemoteConfig({});

  final Map<String, Object?> _values;
  final DateTime? fetchedAt;

  Object? raw(String key) => _values[key];

  bool boolFlag(String key, {required bool fallback}) {
    final v = _values[key];
    if (v is bool) return v;
    if (v is String) {
      final s = v.toLowerCase();
      if (s == 'true') return true;
      if (s == 'false') return false;
    }
    return fallback;
  }

  int intFlag(String key, {required int fallback}) {
    final v = _values[key];
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  String stringFlag(String key, {required String fallback}) {
    final v = _values[key];
    if (v is String) return v;
    if (v == null) return fallback;
    return v.toString();
  }

  List<int> listIntFlag(String key, {required List<int> fallback}) {
    final v = _values[key];
    if (v is List) {
      final result = v.whereType<int>().toList();
      return result.isNotEmpty ? result : fallback;
    }
    if (v is String && v.isNotEmpty) {
      final result = v
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();
      return result.isNotEmpty ? result : fallback;
    }
    return fallback;
  }

  T? jsonFlag<T>(String key) {
    final v = _values[key];
    return v is T ? v : null;
  }

  Map<String, Object?> get all => Map.unmodifiable(_values);
}
