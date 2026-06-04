import 'dart:io';
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
