import 'package:characters/characters.dart';
import 'package:equatable/equatable.dart';

import '../../../core/widgets/mantra_thumb.dart';

/// A mantra's name in every script we display. Devanagari is the
/// canonical chant form; Roman is the transliteration; Telugu / Kannada
/// are regional renderings shown when the user's chosen language matches.
class MantraName extends Equatable {
  const MantraName({
    required this.devanagari,
    required this.roman,
    this.telugu,
    this.kannada,
  });

  final String devanagari;
  final String roman;
  final String? telugu;
  final String? kannada;

  /// Single-character glyph for circular thumbnails. Falls back to the
  /// first character of the roman name if none is provided.
  String thumbGlyph() => devanagari.characters.first;

  @override
  List<Object?> get props => [devanagari, roman, telugu, kannada];
}

/// Spiritual / pragmatic outcome the user is seeking. Maps a Mantra-by-Need
/// dropdown selection to a recommended mantra via tag overlap.
enum MantraNeed {
  wealthProsperity,
  peaceCalm,
  healing,
  protection,
  strengthCourage,
  spiritualLiberation,
  wisdomEnlightenment,
  devotion;

  String get label => switch (this) {
        MantraNeed.wealthProsperity => 'Wealth & Prosperity',
        MantraNeed.peaceCalm => 'Peace & Calm',
        MantraNeed.healing => 'Healing',
        MantraNeed.protection => 'Protection',
        MantraNeed.strengthCourage => 'Strength & Courage',
        MantraNeed.spiritualLiberation => 'Spiritual Liberation',
        MantraNeed.wisdomEnlightenment => 'Wisdom & Enlightenment',
        MantraNeed.devotion => 'Devotion',
      };
}

/// Tags that classify a mantra. A mantra-by-need lookup matches one or
/// more of these to the user's [MantraNeed].
enum MantraTag {
  peace,
  righteousness,
  healing,
  protection,
  strength,
  courage,
  wealth,
  prosperity,
  liberation,
  enlightenment,
  wisdom,
  devotion,
}

/// A mantra in the seeded catalog. Read-only for v1.
class Mantra extends Equatable {
  const Mantra({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbPalette,
    required this.tags,
    this.isActive = true,
    this.deity,
    this.imageUrl,
    this.pronunciationAsset,
    this.recommendedCount,
    this.recommendedDays,
  });

  final String id;
  final MantraName name;
  final String description;
  final MantraThumbPalette thumbPalette;
  final Set<MantraTag> tags;

  /// False when the admin has deactivated this mantra. The API already filters
  /// server-side; this field enables defensive client-side filtering from cache.
  final bool isActive;

  /// Optional name of the deity invoked — drives the hero image colour.
  final String? deity;

  /// Remote image URL for this mantra (served from the admin CDN).
  final String? imageUrl;

  /// Pronunciation audio URL (remote) or asset path (legacy).
  final String? pronunciationAsset;

  /// Suggested per-day recitations / total days (only set for "by need" mantras).
  final int? recommendedCount;
  final int? recommendedDays;

  @override
  List<Object?> get props => [id, isActive, imageUrl];
}
