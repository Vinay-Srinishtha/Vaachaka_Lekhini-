import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';

/// One entry in a mantra's configurable milestone list.
/// [count] is the target chant count; [dayOptions] are the day presets
/// shown in the segmented control (first is auto-selected).
class MantraMilestone extends Equatable {
  const MantraMilestone({required this.count, required this.dayOptions});

  final int count;
  final List<int> dayOptions;

  @override
  List<Object?> get props => [count, dayOptions];
}

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
  String thumbGlyph() => devanagari.isEmpty ? '' : String.fromCharCode(devanagari.runes.first);

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

  String localizedLabel(BuildContext context) {
    final l = AppLocalizations.of(context);
    return switch (this) {
      MantraNeed.wealthProsperity => l.mantraNeedWealthProsperity,
      MantraNeed.peaceCalm => l.mantraNeedPeaceCalm,
      MantraNeed.healing => l.mantraNeedHealing,
      MantraNeed.protection => l.mantraNeedProtection,
      MantraNeed.strengthCourage => l.mantraNeedStrengthCourage,
      MantraNeed.spiritualLiberation => l.mantraNeedSpiritualLiberation,
      MantraNeed.wisdomEnlightenment => l.mantraNeedWisdomEnlightenment,
      MantraNeed.devotion => l.mantraNeedDevotion,
    };
  }
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
    required this.tags,
    this.isActive = true,
    this.deity,
    this.imageUrl,
    this.previewImageUrl,
    this.shareImageUrl,
    this.shareText,
    this.pronunciationAsset,
    this.recommendedCount,
    this.recommendedDays,
    this.milestones,
  });

  final String id;
  final MantraName name;
  final String description;
  final Set<MantraTag> tags;

  /// False when the admin has deactivated this mantra. The API already filters
  /// server-side; this field enables defensive client-side filtering from cache.
  final bool isActive;

  /// Optional name of the deity invoked — drives the hero image colour.
  final String? deity;

  /// Remote image URL for this mantra (served from the admin CDN).
  final String? imageUrl;

  /// Smaller preview image shown in selection list and reminders.
  final String? previewImageUrl;

  /// Image attached when sharing this mantra's progress on WhatsApp / social.
  final String? shareImageUrl;

  /// Share message template. Placeholders: {mantra_name} {chant_count} {app_link}
  final String? shareText;

  /// Pronunciation audio URL (remote) or asset path (legacy).
  final String? pronunciationAsset;

  /// Suggested per-day recitations / total days (only set for "by need" mantras).
  final int? recommendedCount;
  final int? recommendedDays;

  /// Admin-configured milestones shown on the Set Target screen.
  /// Null means fall back to app defaults.
  final List<MantraMilestone>? milestones;

  @override
  List<Object?> get props => [id, isActive, imageUrl, shareImageUrl, shareText];
}
