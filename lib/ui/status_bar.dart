import 'dart:async';

import 'package:flutter/material.dart';

import '../services/system_status_service.dart';

class StatusBar extends StatefulWidget {
  const StatusBar({
    super.key,
    this.iconSize = 22,
    this.showMusicTitle = false,
    this.showWifi = true,
    this.showBluetooth = true,
    this.showMusic = true,
    this.shadows = const [],
  });

  final double iconSize;
  final bool showMusicTitle;
  final bool showWifi;
  final bool showBluetooth;
  final bool showMusic;
  final List<Shadow> shadows;

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  final _service = SystemStatusService();
  Timer? _timer;
  SystemStatus _status = SystemStatus.none;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    final s = await _service.get();
    if (mounted) setState(() => _status = s);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  IconData _wifiIcon(int level) {
    switch (level) {
      case 0:
        return Icons.signal_wifi_0_bar;
      case 1:
        return Icons.network_wifi_1_bar;
      case 2:
        return Icons.network_wifi_2_bar;
      case 3:
        return Icons.network_wifi_3_bar;
      default:
        return Icons.signal_wifi_4_bar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final s = _status;
        final size = widget.iconSize;
        final shadow = widget.shadows;
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final wifi = widget.showWifi;
        final bt = widget.showBluetooth && s.bluetoothConnected;
        final music = widget.showMusic && s.musicActive;
        final iconCount =
            (wifi ? 1 : 0) + (bt ? 1 : 0) + (music ? 1 : 0);
        final gap = size * 0.35;
        final reserved = iconCount * size + (iconCount + 1) * gap;
        final titleMax = (available - reserved).clamp(0.0, available);

        final items = <Widget>[
          if (wifi)
            Icon(s.wifiConnected ? _wifiIcon(s.wifiLevel) : Icons.wifi_off,
                size: size, color: Colors.white, shadows: shadow),
          if (bt)
            Icon(Icons.bluetooth_connected,
                size: size, color: Colors.white, shadows: shadow),
          if (music)
            Icon(Icons.music_note,
                size: size, color: Colors.white, shadows: shadow),
          if (music && widget.showMusicTitle && s.musicTitle.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: titleMax),
              child: Text(
                s.musicTitle,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.7,
                  fontWeight: FontWeight.w400,
                  shadows: shadow,
                ),
              ),
            ),
        ];

        if (items.isEmpty) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              items[i],
            ],
          ],
        );
      },
    );
  }
}
