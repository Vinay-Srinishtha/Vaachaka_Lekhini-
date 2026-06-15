import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Generates a deterministic invite link from a user id and shares it via
/// platform-specific deep links (WhatsApp, Facebook) or the OS share sheet.
class InviteService {
  InviteService({this.host = 'vaachakalekhini.com'});
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
    return '$who has invited you to Vaachaka Lekhini — chant, write, and track your spiritual practice together.\n\n$link';
  }

  /// Opens WhatsApp directly with the invite message pre-filled.
  /// Returns false if WhatsApp is not installed (falls back to system share).
  Future<bool> shareViaWhatsApp(String userId, {String? sender}) async {
    final msg = inviteMessage(userId, sender: sender);
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    await share(userId, sender: sender);
    return false;
  }

  /// Opens a Facebook share dialog for the invite link in the browser.
  /// Returns false if no browser is available.
  Future<bool> shareViaFacebook(String userId) async {
    final link = linkFor(userId);
    final uri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    await share(userId);
    return false;
  }

  /// Copies the invite message to clipboard then tries to open the Instagram app.
  /// Instagram doesn't support URL-based text sharing; the user pastes in DMs.
  /// Returns true if Instagram was opened, false if not installed.
  Future<bool> shareViaInstagram(String userId, {String? sender}) async {
    await Clipboard.setData(ClipboardData(text: inviteMessage(userId, sender: sender)));
    final uri = Uri.parse('instagram://');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// Generic OS share sheet — fallback for unknown channels.
  Future<void> share(String userId, {String? sender}) async {
    final params = ShareParams(text: inviteMessage(userId, sender: sender));
    await SharePlus.instance.share(params);
  }

  Future<void> copyLink(String userId) async {
    await Clipboard.setData(ClipboardData(text: linkFor(userId)));
  }
}
