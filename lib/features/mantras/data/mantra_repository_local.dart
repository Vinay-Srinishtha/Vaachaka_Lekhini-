import '../domain/mantra.dart';
import '../domain/mantra_repository.dart';

class MantraRepositoryLocal implements MantraRepository {
  MantraRepositoryLocal({List<Mantra>? seed}) : _all = seed ?? const [];

  final List<Mantra> _all;
  late final Map<String, Mantra> _byId = {for (final m in _all) m.id: m};

  @override
  Stream<List<Mantra>> get stream => const Stream.empty();

  @override
  List<Mantra> all() => List.unmodifiable(_all);

  @override
  Mantra? byId(String id) => _byId[id];

  @override
  Future<void> refresh() async {}

  @override
  List<Mantra> recommendForNeed(MantraNeed need) {
    final wanted = _tagsFor(need);
    final ranked =
        _all
            .map(
              (m) => (mantra: m, overlap: m.tags.intersection(wanted).length),
            )
            .where((e) => e.overlap > 0)
            .toList()
          ..sort((a, b) => b.overlap.compareTo(a.overlap));
    return [for (final e in ranked) e.mantra];
  }

  Set<MantraTag> _tagsFor(MantraNeed need) => switch (need) {
    MantraNeed.wealthProsperity => {MantraTag.wealth, MantraTag.prosperity},
    MantraNeed.peaceCalm => {MantraTag.peace},
    MantraNeed.healing => {MantraTag.healing},
    MantraNeed.protection => {MantraTag.protection},
    MantraNeed.strengthCourage => {MantraTag.strength, MantraTag.courage},
    MantraNeed.spiritualLiberation => {MantraTag.liberation},
    MantraNeed.wisdomEnlightenment => {
      MantraTag.wisdom,
      MantraTag.enlightenment,
    },
    MantraNeed.devotion => {MantraTag.devotion},
  };
}
