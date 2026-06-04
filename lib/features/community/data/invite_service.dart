import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Generates a deterministic invite link from a user id and shares it via
/// the OS share sheet (used by WhatsApp / Facebook / Instagram / clipboard
/// alike in v1 — Phase 9 may add per-channel deeplinks).
class InviteService {
  InviteService({this.host = 'kvl.app'});
  final String host;

  /// Stable 6-character code derived from the user id (case-insensitive).
  String codeFor(String userId) {
    final clean = userId.replaceAll('-', '').toUpperCase();
    return clean.substring(0, clean.length < 6 ? clean.length : 6);
  }

  String linkFor(String userId) => 'https://$host/invite/${codeFor(userId)}';

  String inviteMessage(String userId, {String? sender}) {
    final link = linkFor(userId);
    final who = sender == null || sender.trim().isEmpty ? 'A friend' : sender.trim();
    return "$who has invited you to Koti Vachika Lekhini — chant, write, and track your spiritual practice together.\n\n$link";
  }

  Future<void> share(String userId, {String? sender}) async {
    final params = ShareParams(text: inviteMessage(userId, sender: sender));
    await SharePlus.instance.share(params);
  }

  Future<void> copyLink(String userId) async {
    await Clipboard.setData(ClipboardData(text: linkFor(userId)));
  }
}
