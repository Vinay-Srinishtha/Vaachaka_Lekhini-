import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests the runtime permissions the app needs, once at startup.
///
/// We ask for Microphone (voice chanting) and Notifications (daily reminders).
/// Camera is intentionally NOT requested here — the photo-capture handwriting
/// option is disabled, so the camera is only ever requested on-demand if that
/// flow is later re-enabled.
///
/// Safe to call repeatedly: already-granted permissions resolve immediately
/// and permanently-denied ones are not re-prompted by the OS.
abstract final class StartupPermissions {
  static bool _requested = false;

  static Future<void> requestAll() async {
    if (_requested) return;
    _requested = true;
    try {
      await [
        Permission.microphone,
        Permission.notification,
      ].request();
    } catch (e) {
      if (kDebugMode) debugPrint('[permissions] startup request failed: $e');
    }
  }
}
