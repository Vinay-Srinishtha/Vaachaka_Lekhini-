import 'package:equatable/equatable.dart';

enum HandwritingMode {
  writeOnScreen,
  useDefaultFont;

  String get label => switch (this) {
        HandwritingMode.writeOnScreen => 'Write on Screen',
        HandwritingMode.useDefaultFont => 'Use Default Font',
      };

  static HandwritingMode fromName(String name) =>
      HandwritingMode.values.firstWhere((m) => m.name == name, orElse: () => HandwritingMode.useDefaultFont);
}

/// A piece of handwriting submitted by the user. `filePath` is relative
/// to the app documents directory; for `useDefaultFont` it is null.
class HandwritingAsset extends Equatable {
  const HandwritingAsset({
    required this.id,
    required this.profileId,
    required this.mode,
    required this.createdAt,
    this.filePath,
    this.mantraId,
  });

  final String id;
  final String profileId;
  final HandwritingMode mode;
  final DateTime createdAt;
  final String? filePath;
  final String? mantraId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'mode': mode.name,
        'createdAt': createdAt.toIso8601String(),
        'filePath': filePath,
        'mantraId': mantraId,
      };

  factory HandwritingAsset.fromJson(Map<String, dynamic> j) => HandwritingAsset(
        id: j['id'] as String,
        profileId: j['profileId'] as String,
        mode: HandwritingMode.fromName(j['mode'] as String? ?? ''),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        filePath: j['filePath'] as String?,
        mantraId: j['mantraId'] as String?,
      );

  @override
  List<Object?> get props => [id, profileId, mode, createdAt, filePath, mantraId];
}
