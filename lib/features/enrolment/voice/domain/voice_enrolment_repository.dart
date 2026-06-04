import 'voice_enrolment.dart';

abstract class VoiceEnrolmentRepository {
  Future<VoiceEnrolment?> get(String profileId, String mantraId);
  Future<List<VoiceEnrolment>> listForProfile(String profileId);
  Future<void> save(VoiceEnrolment enrolment);
  Future<void> delete(String profileId, String mantraId);
}
