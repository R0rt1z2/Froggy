import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/settings.dart';
import '../models/weather.dart';
import 'foreground.dart';

class WeatherOverlay extends StatefulWidget {
  const WeatherOverlay({
    super.key,
    required this.weather,
    required this.settings,
  });

  final WeatherData? weather;
  final Settings settings;

  @override
  State<WeatherOverlay> createState() => _WeatherOverlayState();
}

class _WeatherOverlayState extends State<WeatherOverlay>
    with WidgetsBindingObserver, ForegroundAware<WeatherOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  void _scheduleTick() {
    _timer?.cancel();
    _timer = null;
    if (!foreground) return;
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, now.hour, now.minute)
        .add(const Duration(minutes: 1));
    _timer = Timer(next.difference(now) + const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() {});
      _scheduleTick();
    });
  }

  @override
  void onForegroundChanged(bool foreground) => _scheduleTick();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _time {
    final fmt = widget.settings.hourFormat == ClockFormat.h12
        ? DateFormat.jm()
        : DateFormat.Hm();
    final now = widget.weather?.localTime ?? DateTime.now();
    return fmt.format(now);
  }

  String get _date {
    final now = widget.weather?.localTime ?? DateTime.now();
    return DateFormat.MMMEd().format(now);
  }

  String _summary(WeatherData w) {
    final s = widget.settings;
    final hl = (w.tempMaxC != null && w.tempMinC != null)
        ? ' · ↑${s.formatTemp(w.tempMaxC!)} ↓${s.formatTemp(w.tempMinC!)}'
        : '';
    return '${w.description}$hl';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final w = widget.weather;
    final showWeather = s.showWeather && w != null;
    if (!s.showClock && !s.showDate && !showWeather) {
      return const SizedBox.shrink();
    }
    final stale = w?.isStale ?? false;
    final tempColor = stale ? Colors.white.withValues(alpha: 0.6) : Colors.white;
    final summaryColor =
        stale ? Colors.white.withValues(alpha: 0.45) : Colors.white70;
    final shadow = s.textShadows;
    final tv =
        MediaQuery.navigationModeOf(context) == NavigationMode.directional;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final scale = s.overlayScale;
        final tempBase = (h * 0.075).clamp(16.0, tv ? 22.0 : 30.0);
        final timeSize = (h * 0.16).clamp(28.0, tv ? 46.0 : 72.0) * scale;
        final tempSize = tempBase * scale;
        final summarySize = (tempBase * 0.7).clamp(12.0, 22.0) * scale;
        final pad = (h * 0.06).clamp(16.0, tv ? 22.0 : 32.0);

        return SafeArea(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.showClock)
                    Text(
                      _time,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: timeSize,
                        fontWeight: FontWeight.w300,
                        height: 1.0,
                        shadows: shadow,
                      ),
                    ),
                  if (s.showDate)
                    Padding(
                      padding: EdgeInsets.only(
                          top: s.showClock ? pad * 0.15 : 0),
                      child: Text(
                        _date,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: tempSize,
                          fontWeight: FontWeight.w400,
                          shadows: shadow,
                        ),
                      ),
                    ),
                  if (showWeather)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          s.formatTempWithUnit(w.temperatureC),
                          style: TextStyle(
                            color: tempColor,
                            fontSize: tempSize,
                            fontWeight: FontWeight.w500,
                            shadows: shadow,
                          ),
                        ),
                        SizedBox(width: pad * 0.4),
                        Text(
                          _summary(w),
                          style: TextStyle(
                            color: summaryColor,
                            fontSize: summarySize,
                            fontWeight: FontWeight.w400,
                            shadows: shadow,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
