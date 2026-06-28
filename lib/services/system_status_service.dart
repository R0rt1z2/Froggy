import 'package:flutter/services.dart';

class SystemStatus {
  final bool wifiConnected;
  final int wifiLevel;
  final bool bluetoothConnected;
  final bool musicActive;
  final String musicTitle;

  const SystemStatus({
    required this.wifiConnected,
    required this.wifiLevel,
    required this.bluetoothConnected,
    required this.musicActive,
    this.musicTitle = '',
  });

  static const none = SystemStatus(
    wifiConnected: false,
    wifiLevel: 0,
    bluetoothConnected: false,
    musicActive: false,
  );
}

class SystemStatusService {
  static const _channel = MethodChannel('froggy/system_status');

  Future<SystemStatus> get() async {
    try {
      final m = await _channel.invokeMapMethod<String, dynamic>('get');
      if (m == null) return SystemStatus.none;
      return SystemStatus(
        wifiConnected: m['wifiConnected'] == true,
        wifiLevel: (m['wifiLevel'] as num?)?.toInt() ?? 0,
        bluetoothConnected: m['bluetoothConnected'] == true,
        musicActive: m['musicActive'] == true,
        musicTitle: (m['musicTitle'] as String?) ?? '',
      );
    } catch (_) {
      return SystemStatus.none;
    }
  }

  Future<bool> isTelevision() async {
    try {
      return await _channel.invokeMethod<bool>('isTelevision') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasNotificationAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasNotificationAccess') ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openNotificationAccess() async {
    try {
      await _channel.invokeMethod<void>('openNotificationAccess');
    } catch (_) {}
  }
}
