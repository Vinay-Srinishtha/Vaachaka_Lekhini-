import 'package:hive_ce/hive.dart';

import '../domain/voice_enrolment.dart';
import '../domain/voice_enrolment_repository.dart';

class VoiceEnrolmentRepositoryLocal implements VoiceEnrolmentRepository {
  VoiceEnrolmentRepositoryLocal(this._box);

  final Box<dynamic> _box;

  String _key(String profileId, String mantraId) => 'voice::$profileId::$mantraId';

  @override
  Future<VoiceEnrolment?> get(String profileId, String mantraId) async {
    final raw = _box.get(_key(profileId, mantraId));
    if (raw == null) return null;
    return VoiceEnrolment.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<List<VoiceEnrolment>> listForProfile(String profileId) async {
    return _box.toMap().entries
        .where((e) => e.key is String && (e.key as String).startsWith('voice::$profileId::'))
        .map((e) => VoiceEnrolment.fromJson(Map<String, dynamic>.from(e.value as Map)))
        .toList();
  }

  @override
  Future<void> save(VoiceEnrolment e) =>
      _box.put(_key(e.profileId, e.mantraId), e.toJson());

  @override
  Future<void> delete(String profileId, String mantraId) =>
      _box.delete(_key(profileId, mantraId));
}
