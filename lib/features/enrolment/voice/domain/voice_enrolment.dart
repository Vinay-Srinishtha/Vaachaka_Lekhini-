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
    this.handwritingSamples = 0,
    this.trainedLanguageCode = 'hi',
  });

  final String profileId;
  final String mantraId;
  /// Voice chant samples collected during training.
  final int samples;
  /// Accepted handwriting samples collected during enrollment.
  final int handwritingSamples;
  final DateTime trainedAt;

  /// The mantra script/language the user trained in (e.g. 'hi', 'te', 'kn',
  /// 'en'). Used to decide whether existing training is valid for the current
  /// script setting or whether the user should (re)train. Defaults to 'hi'
  /// (Devanagari) for records saved before this field existed.
  final String trainedLanguageCode;

  static const requiredSamples = 11;

  /// Total accepted samples (voice + handwriting) across both modalities.
  int get totalSamples => samples + handwritingSamples;

  bool get isComplete => totalSamples >= requiredSamples;

  String get key => '$profileId::$mantraId';

  VoiceEnrolment copyWith({
    int? samples,
    int? handwritingSamples,
    DateTime? trainedAt,
    String? trainedLanguageCode,
  }) =>
      VoiceEnrolment(
        profileId: profileId,
        mantraId: mantraId,
        samples: samples ?? this.samples,
        handwritingSamples: handwritingSamples ?? this.handwritingSamples,
        trainedAt: trainedAt ?? this.trainedAt,
        trainedLanguageCode: trainedLanguageCode ?? this.trainedLanguageCode,
      );

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'mantraId': mantraId,
    'samples': samples,
    'handwritingSamples': handwritingSamples,
    'trainedAt': trainedAt.toIso8601String(),
    'trainedLanguageCode': trainedLanguageCode,
  };

  factory VoiceEnrolment.fromJson(Map<String, dynamic> j) => VoiceEnrolment(
    profileId: j['profileId'] as String,
    mantraId: j['mantraId'] as String,
    samples: (j['samples'] as num).toInt(),
    handwritingSamples: (j['handwritingSamples'] as num?)?.toInt() ?? 0,
    trainedAt: DateTime.tryParse(j['trainedAt'] as String? ?? '') ?? DateTime.now(),
    // Records saved before this field existed have no known script — treat as
    // unknown ('') so they're accepted for any current script (no forced retrain).
    trainedLanguageCode: j['trainedLanguageCode'] as String? ?? '',
  );

  @override
  List<Object?> get props =>
      [profileId, mantraId, samples, handwritingSamples, trainedAt, trainedLanguageCode];
}
