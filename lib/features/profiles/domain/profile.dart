import 'package:characters/characters.dart';
import 'package:equatable/equatable.dart';

enum FamilyRelation {
  me,
  son,
  daughter,
  father,
  mother,
  spouse,
  sibling,
  other;

  String get label => switch (this) {
        FamilyRelation.me => 'Me',
        FamilyRelation.son => 'Son',
        FamilyRelation.daughter => 'Daughter',
        FamilyRelation.father => 'Father',
        FamilyRelation.mother => 'Mother',
        FamilyRelation.spouse => 'Spouse',
        FamilyRelation.sibling => 'Sibling',
        FamilyRelation.other => 'Other',
      };

  static FamilyRelation fromName(String? name) =>
      FamilyRelation.values.firstWhere((r) => r.name == name, orElse: () => FamilyRelation.other);
}

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.userId,
    required this.name,
    required this.relation,
    required this.createdAt,
    this.avatarSeed,
    this.language = 'en',
  });

  final String id;
  final String userId;
  final String name;
  final FamilyRelation relation;
  final DateTime createdAt;

  /// Seed string used to generate deterministic placeholder avatars
  /// (gradient + initials) when the user has no real photo.
  final String? avatarSeed;

  /// Preferred UI language for this family member (BCP-47 code: en/hi/te/kn).
  final String language;

  /// Display label used on the Profile Selection screen.
  /// "Me" → just "Me", others → "Name, Relation".
  String get displayLabel => relation == FamilyRelation.me
      ? 'Me'
      : '$name, ${relation.label}';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  Profile copyWith({
    String? name,
    FamilyRelation? relation,
    String? avatarSeed,
    String? language,
  }) => Profile(
        id: id,
        userId: userId,
        name: name ?? this.name,
        relation: relation ?? this.relation,
        avatarSeed: avatarSeed ?? this.avatarSeed,
        language: language ?? this.language,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'relation': relation.name,
        'avatarSeed': avatarSeed,
        'language': language,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        userId: j['userId'] as String,
        name: j['name'] as String,
        relation: FamilyRelation.fromName(j['relation'] as String?),
        avatarSeed: j['avatarSeed'] as String?,
        language: j['language'] as String? ?? 'en',
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  @override
  List<Object?> get props => [id, userId, name, relation, avatarSeed, language, createdAt];
}
