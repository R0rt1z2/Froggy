import 'package:flutter/services.dart';

class WindowService {
  static const _channel = MethodChannel('froggy/window');

  static Future<void> setKeepAwake(bool on) async {
    try {
      await _channel.invokeMethod<void>('setKeepAwake', {'on': on});
    } catch (_) {}
  }

  static Future<bool> isDefaultHome() async {
    try {
      return await _channel.invokeMethod<bool>('isDefaultHome') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openHomeSettings() async {
    try {
      await _channel.invokeMethod<void>('openHomeSettings');
    } catch (_) {}
  }
}
