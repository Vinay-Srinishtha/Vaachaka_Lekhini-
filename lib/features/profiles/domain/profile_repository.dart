import 'profile.dart';

/// Contract for family-profile persistence. Each user has up to 4 profiles.
/// One is "active" at any time — that's whose counter, programs, voice model
/// the app is currently working with.
abstract class ProfileRepository {
  Future<List<Profile>> listForUser(String userId);

  Future<Profile?> getById(String id);

  /// The active profile id is stored separately so it can outlive any
  /// individual profile add/delete.
  Future<Profile?> getActive();

  Stream<Profile?> watchActive();
  Stream<List<Profile>> watchForUser(String userId);

  Future<void> setActive(String profileId);

  /// Clears the active profile so the router shows the "Who is Practicing?"
  /// picker on the next navigation.
  Future<void> clearActive();

  Future<Profile> create({
    required String userId,
    required String name,
    required FamilyRelation relation,
  });

  Future<void> update(Profile profile);

  /// Write a server-fetched profile locally without enqueuing to the outbox.
  Future<void> upsertRemote(Profile profile);

  Future<void> delete(String profileId);

  /// Max profiles per user (per Figma constraint).
  static const int maxPerUser = 4;
}
