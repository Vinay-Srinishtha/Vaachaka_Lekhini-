import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests the runtime permissions the app needs, once at startup.
///
/// We ask for Microphone (voice chanting) and Notifications (daily reminders).
/// Camera is intentionally NOT requested here — the photo-capture handwriting
/// option is disabled, so the camera is only ever requested on-demand if that
/// flow is later re-enabled.
///
/// Requests run sequentially and each is individually guarded: a failure on
/// one permission (or an OEM that throws) never propagates and never blocks
/// app launch. Safe to call repeatedly — already-decided permissions resolve
/// immediately and the OS won't re-prompt permanently-denied ones.
abstract final class StartupPermissions {
  static bool _requested = false;

  static Future<void> requestAll() async {
    if (_requested) return;
    _requested = true;

    // Let the first frame settle and the Activity fully resume before we
    // surface a system permission dialog — requesting too early during cold
    // start can fail on some Android builds.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    await _request(Permission.microphone, 'microphone');
    await _request(Permission.notification, 'notification');
  }

  static Future<void> _request(Permission permission, String label) async {
    try {
      final status = await permission.status;
      // Only prompt when the OS will actually show a dialog. Re-requesting a
      // permanently-denied permission is a no-op but we skip it to be safe.
      if (status.isGranted || status.isPermanentlyDenied || status.isRestricted) {
        return;
      }
      await permission.request();
    } catch (e) {
      if (kDebugMode) debugPrint('[permissions] $label request failed: $e');
    }
  }
}
