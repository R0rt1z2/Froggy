import 'package:flutter/services.dart';

class WindowService {
  static const _channel = MethodChannel('froggy/window');

  static Future<void> setKeepAwake(bool on) async {
    try {
      await _channel.invokeMethod<void>('setKeepAwake', {'on': on});
    } catch (_) {}
  }
}
