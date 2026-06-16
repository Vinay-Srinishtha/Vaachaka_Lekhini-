import 'package:flutter/services.dart';

enum PhoneModeResult {
  enabled,
  disabled,
  permissionRequired,
  unsupported,
  failed,
}

class PhoneModeService {
  static const _channel = MethodChannel('vachika_lekhini/phone_mode');

  Future<bool> isEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<PhoneModeResult> toggle() async {
    try {
      final value = await _channel.invokeMethod<String>('toggle');
      return switch (value) {
        'enabled' => PhoneModeResult.enabled,
        'disabled' => PhoneModeResult.disabled,
        'permission_required' => PhoneModeResult.permissionRequired,
        _ => PhoneModeResult.failed,
      };
    } on MissingPluginException {
      return PhoneModeResult.unsupported;
    } on PlatformException {
      return PhoneModeResult.failed;
    }
  }
}

/// The phone's current ringer state, mirrored live from the OS.
enum RingerMode { normal, vibrate, silent, unknown }

RingerMode _parseRingerMode(Object? value) => switch (value) {
  'silent' => RingerMode.silent,
  'vibrate' => RingerMode.vibrate,
  'normal' => RingerMode.normal,
  _ => RingerMode.unknown,
};

/// Reads — and live-syncs — the device ringer mode (silent / vibrate / ring).
class RingerModeService {
  static const _method = MethodChannel('vachika_lekhini/ringer_mode');
  static const _events = EventChannel('vachika_lekhini/ringer_mode_events');

  Future<RingerMode> current() async {
    try {
      return _parseRingerMode(
        await _method.invokeMethod<String>('getRingerMode'),
      );
    } on MissingPluginException {
      return RingerMode.unknown;
    } on PlatformException {
      return RingerMode.unknown;
    }
  }

  /// Cycles ring → vibrate → silent → ring on the device, returning the new
  /// state. May open Do-Not-Disturb settings the first time access is needed.
  Future<RingerMode> cycle() async {
    try {
      return _parseRingerMode(
        await _method.invokeMethod<String>('cycleRingerMode'),
      );
    } on MissingPluginException {
      return RingerMode.unknown;
    } on PlatformException {
      return RingerMode.unknown;
    }
  }

  /// Emits the current ringer mode immediately and on every OS change.
  Stream<RingerMode> watch() => _events
      .receiveBroadcastStream()
      .map(_parseRingerMode)
      .handleError((_) {});
}
