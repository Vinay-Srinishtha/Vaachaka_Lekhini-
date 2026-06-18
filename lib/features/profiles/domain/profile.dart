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

enum Gender {
  male,
  female,
  other,
  preferNotToSay;

  String get label => switch (this) {
        Gender.male => 'Male',
        Gender.female => 'Female',
        Gender.other => 'Other',
        Gender.preferNotToSay => 'Prefer not to say',
      };

  String get serverValue => switch (this) {
        Gender.male => 'male',
        Gender.female => 'female',
        Gender.other => 'other',
        Gender.preferNotToSay => 'prefer_not_to_say',
      };

  static Gender? fromServer(String? value) => switch (value) {
        'male' => Gender.male,
        'female' => Gender.female,
        'other' => Gender.other,
        'prefer_not_to_say' => Gender.preferNotToSay,
        _ => null,
      };
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
    this.mantraLanguage = 'hi',
    this.gender,
    this.birthYear,
    this.motherTongue,
    this.profileCompletedAt,
  });

  final String id;
  final String userId;
  final String name;
  final FamilyRelation relation;
  final DateTime createdAt;

  /// Seed string used to generate deterministic placeholder avatars
  /// (gradient + initials) when the user has no real photo.
  final String? avatarSeed;

  /// Preferred UI / app language for this family member (en/hi/te/kn).
  final String language;

  /// Preferred language/script for displaying mantras — independent of the
  /// UI [language]. Defaults to Devanagari ('hi').
  final String mantraLanguage;

  final Gender? gender;

  /// Year of birth, e.g. 1990.
  final int? birthYear;

  /// BCP-47 code for the user's mother tongue, e.g. 'hi', 'te', 'kn', 'ta'.
  final String? motherTongue;

  /// Non-null once the 50-point profile-completion bonus has been awarded.
  final DateTime? profileCompletedAt;

  /// True when all required fields are filled (determines whether the reward
  /// has been / can be earned).
  bool get isProfileComplete =>
      gender != null && birthYear != null && motherTongue != null && name.isNotEmpty;

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
    String? mantraLanguage,
    Gender? gender,
    int? birthYear,
    String? motherTongue,
    DateTime? profileCompletedAt,
  }) => Profile(
        id: id,
        userId: userId,
        name: name ?? this.name,
        relation: relation ?? this.relation,
        avatarSeed: avatarSeed ?? this.avatarSeed,
        language: language ?? this.language,
        mantraLanguage: mantraLanguage ?? this.mantraLanguage,
        gender: gender ?? this.gender,
        birthYear: birthYear ?? this.birthYear,
        motherTongue: motherTongue ?? this.motherTongue,
        profileCompletedAt: profileCompletedAt ?? this.profileCompletedAt,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'relation': relation.name,
        'avatarSeed': avatarSeed,
        'language': language,
        'mantraLanguage': mantraLanguage,
        'gender': gender?.serverValue,
        'birthYear': birthYear,
        'motherTongue': motherTongue,
        'profileCompletedAt': profileCompletedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        userId: j['userId'] as String,
        name: j['name'] as String,
        relation: FamilyRelation.fromName(j['relation'] as String?),
        avatarSeed: j['avatarSeed'] as String?,
        language: j['language'] as String? ?? 'en',
        mantraLanguage: j['mantraLanguage'] as String? ?? 'hi',
        gender: Gender.fromServer(j['gender'] as String?),
        birthYear: j['birthYear'] as int?,
        motherTongue: j['motherTongue'] as String?,
        profileCompletedAt: j['profileCompletedAt'] != null
            ? DateTime.tryParse(j['profileCompletedAt'] as String)
            : null,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        relation,
        avatarSeed,
        language,
        mantraLanguage,
        gender,
        birthYear,
        motherTongue,
        profileCompletedAt,
        createdAt,
      ];
}
