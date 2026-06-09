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
