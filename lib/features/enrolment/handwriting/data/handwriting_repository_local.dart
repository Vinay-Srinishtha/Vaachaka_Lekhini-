import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../domain/handwriting_asset.dart';
import '../domain/handwriting_repository.dart';

class HandwritingRepositoryLocal implements HandwritingRepository {
  HandwritingRepositoryLocal(this._box, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Box<dynamic> _box;
  final Uuid _uuid;

  String _key(String id) => 'handwriting::$id';

  Future<Directory> _dirFor(String profileId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'handwriting', profileId));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  @override
  Future<List<HandwritingAsset>> listForProfile(String profileId) async {
    return _box.toMap().entries
        .where((e) => e.key is String && (e.key as String).startsWith('handwriting::'))
        .map((e) => HandwritingAsset.fromJson(Map<String, dynamic>.from(e.value as Map)))
        .where((a) => a.profileId == profileId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<HandwritingAsset> savePng({
    required String profileId,
    required HandwritingMode mode,
    required Uint8List bytes,
    String? mantraId,
  }) async {
    final id = _uuid.v4();
    final dir = await _dirFor(profileId);
    final file = File(p.join(dir.path, '$id.png'));
    await file.writeAsBytes(bytes, flush: true);
    return _persist(HandwritingAsset(
      id: id,
      profileId: profileId,
      mode: mode,
      createdAt: DateTime.now(),
      filePath: file.path,
      mantraId: mantraId,
    ));
  }

  @override
  Future<HandwritingAsset> registerExisting({
    required String profileId,
    required HandwritingMode mode,
    required String filePath,
    String? mantraId,
  }) async {
    final id = _uuid.v4();
    return _persist(HandwritingAsset(
      id: id,
      profileId: profileId,
      mode: mode,
      createdAt: DateTime.now(),
      filePath: filePath,
      mantraId: mantraId,
    ));
  }

  @override
  Future<HandwritingAsset> recordDefaultFontChoice({required String profileId, String? mantraId}) async {
    final id = _uuid.v4();
    return _persist(HandwritingAsset(
      id: id,
      profileId: profileId,
      mode: HandwritingMode.useDefaultFont,
      createdAt: DateTime.now(),
      mantraId: mantraId,
    ));
  }

  String _countKey(String profileId, String mantraId) =>
      'handwriting_count::$profileId::$mantraId';

  @override
  Future<HandwritingAsset> savePngCapped({
    required String profileId,
    required String mantraId,
    required Uint8List bytes,
    int maxSamples = 10,
  }) async {
    // Increment the lifetime write count for this (profile, mantra).
    final countKey = _countKey(profileId, mantraId);
    final totalCount = (((_box.get(countKey) as int?) ?? 0) + 1);
    await _box.put(countKey, totalCount);

    // Reservoir sampling:
    // - First maxSamples writes: always add to pool.
    // - After that: add with probability maxSamples/totalCount,
    //   replacing a random existing sample. This ensures every write
    //   has an equal probability of being in the pool at any time.
    final rng = Random();
    if (totalCount <= maxSamples) {
      // Pool not full yet — always save.
      return savePng(
        profileId: profileId,
        mode: HandwritingMode.writeOnScreen,
        bytes: bytes,
        mantraId: mantraId,
      );
    }

    // After pool is full: replace with probability maxSamples/totalCount.
    final replaceIndex = rng.nextInt(totalCount); // 0 .. totalCount-1
    if (replaceIndex >= maxSamples) {
      // This write does not enter the pool — discard silently.
      // Return a dummy asset so callers don't need to handle null.
      return HandwritingAsset(
        id: 'discarded',
        profileId: profileId,
        mode: HandwritingMode.writeOnScreen,
        createdAt: DateTime.now(),
        mantraId: mantraId,
      );
    }

    // replaceIndex < maxSamples — save new sample and evict one at random.
    final saved = await savePng(
      profileId: profileId,
      mode: HandwritingMode.writeOnScreen,
      bytes: bytes,
      mantraId: mantraId,
    );

    final pool = (await listForProfile(profileId))
        .where((a) =>
            a.mantraId == mantraId &&
            a.filePath != null &&
            a.mode == HandwritingMode.writeOnScreen &&
            a.id != saved.id)
        .toList();

    if (pool.length >= maxSamples) {
      final victim = pool[rng.nextInt(pool.length)];
      await delete(victim.id);
    }

    return saved;
  }

  Future<HandwritingAsset> _persist(HandwritingAsset asset) async {
    await _box.put(_key(asset.id), asset.toJson());
    return asset;
  }

  @override
  Future<void> delete(String id) async {
    final raw = _box.get(_key(id));
    if (raw == null) return;
    final asset = HandwritingAsset.fromJson(Map<String, dynamic>.from(raw as Map));
    if (asset.filePath != null) {
      final f = File(asset.filePath!);
      if (await f.exists()) await f.delete();
    }
    await _box.delete(_key(id));
  }
}
