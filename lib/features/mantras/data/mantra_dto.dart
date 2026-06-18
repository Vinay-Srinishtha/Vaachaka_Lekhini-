import '../domain/mantra.dart';

List<MantraMilestone>? _parseMilestones(Object? raw) {
  if (raw is! List || raw.isEmpty) return null;
  try {
    return raw.map((e) {
      final m = e as Map<String, Object?>;
      return MantraMilestone(
        count: (m['count'] as num).toInt(),
        dayOptions: ((m['day_options'] as List?) ?? const [])
            .map((d) => (d as num).toInt())
            .toList(growable: false),
      );
    }).toList(growable: false);
  } catch (_) {
    return null;
  }
}

/// DTO for the `/api/v1/mantras` payload. The admin app serialises every key
/// in snake_case (mirrored in `manage/.../snake-case.ts`) so we map here.
///
/// We never expose [MantraDto] to UI — it's a transport-only shape.
class MantraDto {
  const MantraDto({
    required this.slug,
    required this.isActive,
    required this.nameDevanagari,
    required this.nameRoman,
    this.nameTelugu,
    this.nameKannada,
    required this.description,
    this.deity,
    required this.tags,
    this.recommendedCount,
    this.recommendedDays,
    this.pronunciationUrl,
    this.imageUrl,
    this.previewImageUrl,
    this.shareImageUrl,
    this.shareText,
    this.milestones,
  });

  final String slug;
  final bool isActive;
  final String nameDevanagari;
  final String nameRoman;
  final String? nameTelugu;
  final String? nameKannada;
  final String description;
  final String? deity;
  final List<String> tags;
  final int? recommendedCount;
  final int? recommendedDays;
  final String? pronunciationUrl;
  final String? imageUrl;
  final String? previewImageUrl;
  final String? shareImageUrl;
  final String? shareText;
  final List<MantraMilestone>? milestones;

  factory MantraDto.fromJson(Map<String, Object?> json) => MantraDto(
        slug: json['slug'] as String,
        // Default true: old cached entries without the field were active when cached.
        isActive: json['is_active'] as bool? ?? true,
        nameDevanagari: json['name_devanagari'] as String,
        nameRoman: json['name_roman'] as String,
        nameTelugu: json['name_telugu'] as String?,
        nameKannada: json['name_kannada'] as String?,
        description: json['description'] as String,
        deity: json['deity'] as String?,
        tags: ((json['tags'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(growable: false),
        recommendedCount: (json['recommended_count'] as num?)?.toInt(),
        recommendedDays: (json['recommended_days'] as num?)?.toInt(),
        pronunciationUrl: json['pronunciation_url'] as String?,
        imageUrl: json['image_url'] as String?,
        previewImageUrl: json['preview_image_url'] as String?,
        shareImageUrl: json['share_image_url'] as String?,
        shareText: json['share_text'] as String?,
        milestones: _parseMilestones(json['milestones']),
      );

  Map<String, Object?> toJson() => {
        'slug': slug,
        'is_active': isActive,
        'name_devanagari': nameDevanagari,
        'name_roman': nameRoman,
        'name_telugu': nameTelugu,
        'name_kannada': nameKannada,
        'description': description,
        'deity': deity,
        'tags': tags,
        'recommended_count': recommendedCount,
        'recommended_days': recommendedDays,
        'pronunciation_url': pronunciationUrl,
        'image_url': imageUrl,
        'preview_image_url': previewImageUrl,
        'share_image_url': shareImageUrl,
        'share_text': shareText,
        'milestones': milestones
            ?.map((m) => {'count': m.count, 'day_options': m.dayOptions})
            .toList(),
      };

  /// Convert to the domain object. Unknown palettes/tags are silently dropped.
  Mantra toDomain() => Mantra(
        id: slug,
        isActive: isActive,
        name: MantraName(
          devanagari: nameDevanagari,
          roman: nameRoman,
          telugu: nameTelugu,
          kannada: nameKannada,
        ),
        description: description,
        deity: deity,
        tags: {
          for (final t in tags)
            if (_tagByName[t] != null) _tagByName[t]!,
        },
        recommendedCount: recommendedCount,
        recommendedDays: recommendedDays,
        pronunciationAsset: pronunciationUrl,
        imageUrl: imageUrl,
        previewImageUrl: previewImageUrl,
        shareImageUrl: shareImageUrl,
        shareText: shareText,
        milestones: milestones,
      );
}


final Map<String, MantraTag> _tagByName = {
  for (final t in MantraTag.values) t.name: t,
};
