import '../../../core/widgets/mantra_thumb.dart';
import '../domain/mantra.dart';

/// DTO for the `/api/v1/mantras` payload. The admin app serialises every key
/// in snake_case (mirrored in `manage/.../snake-case.ts`) so we map here.
///
/// We never expose [MantraDto] to UI — it's a transport-only shape.
class MantraDto {
  const MantraDto({
    required this.slug,
    required this.nameDevanagari,
    required this.nameRoman,
    this.nameTelugu,
    this.nameKannada,
    required this.description,
    this.deity,
    required this.thumbPalette,
    required this.tags,
    this.recommendedCount,
    this.recommendedDays,
    this.pronunciationUrl,
  });

  final String slug;
  final String nameDevanagari;
  final String nameRoman;
  final String? nameTelugu;
  final String? nameKannada;
  final String description;
  final String? deity;
  final String thumbPalette;
  final List<String> tags;
  final int? recommendedCount;
  final int? recommendedDays;
  final String? pronunciationUrl;

  factory MantraDto.fromJson(Map<String, Object?> json) => MantraDto(
        slug: json['slug'] as String,
        nameDevanagari: json['name_devanagari'] as String,
        nameRoman: json['name_roman'] as String,
        nameTelugu: json['name_telugu'] as String?,
        nameKannada: json['name_kannada'] as String?,
        description: json['description'] as String,
        deity: json['deity'] as String?,
        thumbPalette: json['thumb_palette'] as String,
        tags: ((json['tags'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(growable: false),
        recommendedCount: (json['recommended_count'] as num?)?.toInt(),
        recommendedDays: (json['recommended_days'] as num?)?.toInt(),
        pronunciationUrl: json['pronunciation_url'] as String?,
      );

  Map<String, Object?> toJson() => {
        'slug': slug,
        'name_devanagari': nameDevanagari,
        'name_roman': nameRoman,
        'name_telugu': nameTelugu,
        'name_kannada': nameKannada,
        'description': description,
        'deity': deity,
        'thumb_palette': thumbPalette,
        'tags': tags,
        'recommended_count': recommendedCount,
        'recommended_days': recommendedDays,
        'pronunciation_url': pronunciationUrl,
      };

  /// Convert to the domain object the rest of the app already knows about.
  /// Unknown palettes / tags are silently dropped so a future server-side
  /// addition can't crash older clients.
  Mantra toDomain() => Mantra(
        id: slug,
        name: MantraName(
          devanagari: nameDevanagari,
          roman: nameRoman,
          telugu: nameTelugu,
          kannada: nameKannada,
        ),
        description: description,
        deity: deity,
        thumbPalette: _paletteByName[thumbPalette] ?? MantraThumbPalette.saffron,
        tags: {
          for (final t in tags)
            if (_tagByName[t] != null) _tagByName[t]!,
        },
        recommendedCount: recommendedCount,
        recommendedDays: recommendedDays,
        pronunciationAsset: pronunciationUrl,
      );
}

final Map<String, MantraThumbPalette> _paletteByName = {
  for (final p in MantraThumbPalette.values) p.name: p,
};

final Map<String, MantraTag> _tagByName = {
  for (final t in MantraTag.values) t.name: t,
};
