import 'package:equatable/equatable.dart';

/// Records that a profile has trained the voice model for a given mantra.
///
/// Phase 2 stores only a marker (sample count + timestamp). Phase 8 will
/// add the actual TFLite ECAPA-TDNN speaker embedding.
class VoiceEnrolment extends Equatable {
  const VoiceEnrolment({
    required this.profileId,
    required this.mantraId,
    required this.samples,
    required this.trainedAt,
  });

  final String profileId;
  final String mantraId;
  final int samples;
  final DateTime trainedAt;

  static const requiredSamples = 11;

  bool get isComplete => samples >= requiredSamples;

  String get key => '$profileId::$mantraId';

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'mantraId': mantraId,
    'samples': samples,
    'trainedAt': trainedAt.toIso8601String(),
  };

  factory VoiceEnrolment.fromJson(Map<String, dynamic> j) => VoiceEnrolment(
    profileId: j['profileId'] as String,
    mantraId: j['mantraId'] as String,
    samples: (j['samples'] as num).toInt(),
    trainedAt: DateTime.tryParse(j['trainedAt'] as String? ?? '') ?? DateTime.now(),
  );

  @override
  List<Object?> get props => [profileId, mantraId, samples, trainedAt];
}
