import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/storage_keys.dart';
import '../../../core/sync/sync_outbox.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

/// Hive-backed implementation. Each profile is a JSON map keyed by its id
/// in the profiles box. The active-profile pointer lives in the session box.
///
/// [outbox] is optional — when provided, every create/update enqueues a
/// `members.upsert` so the Prisma Member table stays in sync.
class ProfileRepositoryLocal implements ProfileRepository {
  ProfileRepositoryLocal({
    required Box<dynamic> profilesBox,
    required Box<dynamic> sessionBox,
    Uuid? uuid,
    SyncOutbox? outbox,   // ADDED
  })  : _profiles = profilesBox,
        _session = sessionBox,
        _uuid = uuid ?? const Uuid(),
        _outbox = outbox {
    _profiles.watch().listen((_) => _emitAll());
    _session.watch(key: KvlKeys.activeProfileId).listen((_) async {
      _activeController.add(await getActive());
    });
  }

  final Box<dynamic> _profiles;
  final Box<dynamic> _session;
  final Uuid _uuid;
  final SyncOutbox? _outbox;

  final _allController = StreamController<List<Profile>>.broadcast();
  final _activeController = StreamController<Profile?>.broadcast();

  // We don't know the userId at construction time, so the broadcast stream
  // simply re-emits the full list. Consumers filter by userId — cheap given
  // the cap of 4 profiles per user.
  Future<void> _emitAll() async {
    _allController.add(_readAll());
  }

  List<Profile> _readAll() {
    return _profiles.values
        .whereType<Map>()
        .map((raw) => Profile.fromJson(Map<String, dynamic>.from(raw)))
        .toList();
  }

  @override
  Future<List<Profile>> listForUser(String userId) async {
    return _readAll()
        .where((p) => p.userId == userId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<Profile?> getById(String id) async {
    final raw = _profiles.get(id);
    if (raw == null) return null;
    return Profile.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<Profile?> getActive() async {
    final id = _session.get(KvlKeys.activeProfileId) as String?;
    if (id == null) return null;
    return getById(id);
  }

  @override
  Stream<Profile?> watchActive() async* {
    yield await getActive();
    yield* _activeController.stream;
  }

  @override
  Stream<List<Profile>> watchForUser(String userId) async* {
    yield await listForUser(userId);
    yield* _allController.stream
        .map((all) => all.where((p) => p.userId == userId).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  @override
  Future<void> setActive(String profileId) async {
    await _session.put(KvlKeys.activeProfileId, profileId);
  }

  @override
  Future<Profile> create({
    required String userId,
    required String name,
    required FamilyRelation relation,
  }) async {
    final existing = await listForUser(userId);
    if (existing.length >= ProfileRepository.maxPerUser) {
      throw StateError('Maximum ${ProfileRepository.maxPerUser} profiles per user.');
    }
    final p = Profile(
      id: _uuid.v4(),
      userId: userId,
      name: name.trim().isEmpty ? 'Profile' : name.trim(),
      relation: relation,
      createdAt: DateTime.now(),
      avatarSeed: _uuid.v4().substring(0, 8),
    );
    await _profiles.put(p.id, p.toJson());
    // Sync to Prisma — field names match Member table exactly
    await _outbox?.enqueue('members.upsert', _memberPayload(p));
    return p;
  }

  @override
  Future<void> update(Profile profile) async {
    await _profiles.put(profile.id, profile.toJson());
    await _outbox?.enqueue('members.upsert', _memberPayload(profile));
  }

  @override
  Future<void> upsertRemote(Profile profile) async {
    // Write without outbox — this data came from the server, not the user.
    await _profiles.put(profile.id, profile.toJson());
  }

  @override
  Future<void> delete(String profileId) async {
    final active = _session.get(KvlKeys.activeProfileId) as String?;
    if (active == profileId) {
      await _session.delete(KvlKeys.activeProfileId);
    }
    await _profiles.delete(profileId);
  }

  /// Payload keys match Prisma Member column names exactly so the backend
  /// can upsert without any transformation.
  Map<String, Object?> _memberPayload(Profile p) => {
        'id': p.id,
        'account_id': p.userId,          // Prisma Member.accountId
        'display_name': p.name,          // Prisma Member.displayName
        'avatar_key': p.avatarSeed,      // Prisma Member.avatarKey
        'relation': _serverRelation(p.relation),
        'is_primary': p.relation == FamilyRelation.me,
        'language': p.language,
      };

  // Map Flutter FamilyRelation to the server's FAMILY_RELATIONS enum.
  // Server accepts: self | spouse | parent | child | sibling | friend | other
  static String _serverRelation(FamilyRelation r) => switch (r) {
        FamilyRelation.me => 'self',
        FamilyRelation.father || FamilyRelation.mother => 'parent',
        FamilyRelation.son || FamilyRelation.daughter => 'child',
        FamilyRelation.spouse => 'spouse',
        FamilyRelation.sibling => 'sibling',
        _ => 'other',
      };
}
