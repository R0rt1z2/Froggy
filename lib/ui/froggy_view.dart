import 'dart:async';
import 'dart:math';

import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';

import '../models/settings.dart';
import '../models/weather.dart';
import '../services/asset_catalog.dart';
import 'overlay.dart';
import 'status_bar.dart';

class FroggyView extends StatelessWidget {
  const FroggyView({
    super.key,
    required this.scene,
    this.weather,
    this.settings = const Settings(),
    this.locationName,
    this.showOverlay = true,
    this.showTopBar = true,
  });

  final SceneAssets? scene;
  final WeatherData? weather;
  final Settings settings;
  final String? locationName;
  final bool showOverlay;
  final bool showTopBar;

  static const _animationName = 'Hero-Action';

  @override
  Widget build(BuildContext context) {
    final s = scene;
    final h = MediaQuery.sizeOf(context).height;
    final statusIcon = (h * 0.05).clamp(16.0, 26.0);
    final statusPad = (h * 0.06).clamp(16.0, 32.0);
    final shadows = settings.textShadows;
    final dayPart = weather?.dayPart ?? dayPartFor(DateTime.now(), null, null);
    final nightFactor = dayPart == DayPart.night
        ? 1.0
        : (dayPart == DayPart.sunset ? 0.5 : 0.0);
    final localTime = weather?.localTime ?? DateTime.now();
    final dim = settings.dimAt(nightFactor, localTime);
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (s != null)
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: SizedBox.expand(
                  key: ValueKey(s.background),
                  child: Image.asset(s.background, fit: BoxFit.cover),
                ),
              ),
            ),
          if (s != null)
            Positioned.fill(
              child: _LoopingFrog(
                key: ValueKey(s.frog),
                asset: s.frog,
                animation: _animationName,
              ),
            ),
          if (showOverlay)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: h * 0.34,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (showOverlay)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: h * 0.45,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (showOverlay) WeatherOverlay(weather: weather, settings: settings),
          if (showOverlay && showTopBar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(statusPad),
                child: SizedBox(
                  height: statusIcon * 1.5,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final showLoc = settings.showLocation &&
                          locationName != null &&
                          locationName!.isNotEmpty;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: StatusBar(
                                iconSize: statusIcon,
                                showMusicTitle: settings.showMusicTitle,
                                showWifi:
                                    settings.showStatus && settings.showWifi,
                                showBluetooth: settings.showStatus &&
                                    settings.showBluetooth,
                                showMusic:
                                    settings.showStatus && settings.showMusic,
                                shadows: shadows,
                              ),
                            ),
                          ),
                          if (showLoc)
                            Align(
                              alignment: Alignment.centerRight,
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: c.maxWidth * 0.4),
                                child: _LocationLabel(
                                  name: locationName!,
                                  size: statusIcon,
                                  shadows: shadows,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          if (dim > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: Colors.black.withValues(alpha: dim)),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationLabel extends StatelessWidget {
  const _LocationLabel({
    required this.name,
    required this.size,
    required this.shadows,
  });

  final String name;
  final double size;
  final List<Shadow> shadows;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on,
            size: size, color: Colors.white, shadows: shadows),
        SizedBox(width: size * 0.2),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: size,
              fontWeight: FontWeight.w500,
              shadows: shadows,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoopingFrog extends StatefulWidget {
  const _LoopingFrog({super.key, required this.asset, required this.animation});

  final String asset;
  final String animation;

  @override
  State<_LoopingFrog> createState() => _LoopingFrogState();
}

class _LoopingFrogState extends State<_LoopingFrog> {
  static final Random _rng = Random();

  String? _current;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _current = widget.animation;
  }

  void _onCompleted(String name) {
    if (!mounted) return;
    final gapMs = 2500 + _rng.nextInt(7500);
    setState(() => _current = null);
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: gapMs), () {
      if (!mounted) return;
      setState(() => _current = widget.animation);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlareActor(
      widget.asset,
      alignment: Alignment.center,
      fit: BoxFit.cover,
      animation: _current,
      isPaused: false,
      callback: _onCompleted,
    );
  }
}
