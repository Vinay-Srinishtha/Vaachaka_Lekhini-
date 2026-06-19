class GlobalSadhana {
  const GlobalSadhana({
    required this.id,
    required this.title,
    required this.description,
    required this.mantraId,
    this.mantraText,
    this.imageUrl,
    required this.targetCount,
    required this.currentCount,
    required this.startAt,
    this.endAt,
    required this.status,
    required this.participationMode,
    this.instructions,
    this.isSponsored = false,
    this.participantCount = 0,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final String mantraId;
  final String? mantraText;
  final String? imageUrl;
  final int targetCount;
  final int currentCount;
  final DateTime startAt;
  final DateTime? endAt;
  final String status;
  final String participationMode;
  final String? instructions;
  final bool isSponsored;
  final int participantCount;
  final DateTime? completedAt;

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isPaused => status == 'paused';
  bool get voiceAllowed => participationMode == 'voice' || participationMode == 'both';
  bool get handwritingAllowed => participationMode == 'handwriting' || participationMode == 'both';

  int get remaining => (targetCount - currentCount).clamp(0, targetCount);
  double get progress =>
      targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  factory GlobalSadhana.fromJson(Map<String, dynamic> json) => GlobalSadhana(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        mantraId: json['mantra_id'] as String,
        mantraText: json['mantra_text'] as String?,
        imageUrl: json['image_url'] as String?,
        targetCount: (json['target_count'] as num).toInt(),
        currentCount: (json['current_count'] as num? ?? 0).toInt(),
        startAt: DateTime.parse(json['start_at'] as String),
        endAt: json['end_at'] != null
            ? DateTime.tryParse(json['end_at'] as String)
            : null,
        status: json['status'] as String,
        participationMode: json['participation_mode'] as String? ?? 'both',
        instructions: json['instructions'] as String?,
        isSponsored: json['is_sponsored'] == true,
        participantCount: (json['participant_count'] as num? ?? 0).toInt(),
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'] as String)
            : null,
      );
}

class GlobalSadhanaEnrollment {
  const GlobalSadhanaEnrollment({
    required this.sadhanaId,
    required this.memberId,
    required this.enrolledAt,
    required this.voiceTrainingComplete,
    required this.handwritingTrainingComplete,
    this.myContribution = 0,
  });

  final String sadhanaId;
  final String memberId;
  final DateTime enrolledAt;
  final bool voiceTrainingComplete;
  final bool handwritingTrainingComplete;
  final int myContribution;

  factory GlobalSadhanaEnrollment.fromJson(Map<String, dynamic> json) =>
      GlobalSadhanaEnrollment(
        sadhanaId: json['global_sadhana_id'] as String,
        memberId: json['member_id'] as String,
        enrolledAt: DateTime.parse(json['enrolled_at'] as String),
        voiceTrainingComplete: json['voice_training_complete'] == true,
        handwritingTrainingComplete:
            json['handwriting_training_complete'] == true,
        myContribution: (json['my_contribution'] as num? ?? 0).toInt(),
      );
}
