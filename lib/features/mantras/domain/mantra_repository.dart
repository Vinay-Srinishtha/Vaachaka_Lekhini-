import 'mantra.dart';

abstract class MantraRepository {
  List<Mantra> all();
  Mantra? byId(String id);

  /// Pulls the latest active catalog from the backing source.
  Future<void> refresh() async {}

  /// Returns the best-fit mantras for [need], ordered by match strength.
  /// In v1 we return a single recommendation, but the API is plural-friendly
  /// for later "show me 3 options" UX.
  List<Mantra> recommendForNeed(MantraNeed need);

  /// Emits the full catalog every time it is refreshed from the remote source.
  /// Implementations backed by a local-only store may return an empty stream.
  Stream<List<Mantra>> get stream => const Stream.empty();
}
