import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../models/weather.dart';

class SceneAssets {
  final String background;
  final String frog;
  const SceneAssets(this.background, this.frog);
}

class AssetCatalog {
  AssetCatalog._(this._available, this.scenes);

  final Set<String> _available;

  final List<String> scenes;

  static const _neutralOrder = <WeatherCondition>[
    WeatherCondition.cloudy,
    WeatherCondition.hazy,
    WeatherCondition.sunny,
    WeatherCondition.rainy,
    WeatherCondition.snowy,
  ];

  static Future<AssetCatalog> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final available = manifest
        .listAssets()
        .where((a) =>
            a.startsWith('assets/') &&
            (a.endsWith('_bg.webp') || a.endsWith('_frog.flr')))
        .toSet();

    final scenes = <String>{};
    for (final a in available) {
      if (a.endsWith('_frog.flr')) {
        scenes.add(a.substring('assets/'.length).split('_').first);
      }
    }
    final ordered = scenes.toList()..sort();
    return AssetCatalog._(available, ordered);
  }

  String _bg(String scene, DayPart tod, WeatherCondition cond) =>
      'assets/${scene}_${tod.asset}_${cond.asset}_bg.webp';

  String _frog(String scene, DayPart tod, WeatherCondition cond) =>
      'assets/${scene}_${tod.asset}_${cond.asset}_frog.flr';

  DayPart _adjacentTod(DayPart tod) {
    switch (tod) {
      case DayPart.morning:
        return DayPart.day;
      case DayPart.day:
        return DayPart.morning;
      case DayPart.sunset:
        return DayPart.night;
      case DayPart.night:
        return DayPart.sunset;
    }
  }

  String _resolveBackground(String scene, DayPart tod, WeatherCondition cond) {
    final exact = _bg(scene, tod, cond);
    if (_available.contains(exact)) return exact;

    for (final c in _neutralOrder) {
      final cand = _bg(scene, tod, c);
      if (_available.contains(cand)) return cand;
    }

    final alt = _adjacentTod(tod);
    final altExact = _bg(scene, alt, cond);
    if (_available.contains(altExact)) return altExact;
    for (final c in _neutralOrder) {
      final cand = _bg(scene, alt, c);
      if (_available.contains(cand)) return cand;
    }

    return _available.firstWhere(
      (a) => a.startsWith('assets/${scene}_') && a.endsWith('_bg.webp'),
      orElse: () => exact,
    );
  }

  String _resolveFrog(String scene, DayPart tod, WeatherCondition cond) {
    final exact = _frog(scene, tod, cond);
    if (_available.contains(exact)) return exact;
    final alt = _frog(scene, _adjacentTod(tod), cond);
    if (_available.contains(alt)) return alt;
    return _available.firstWhere(
      (a) => a.startsWith('assets/${scene}_') && a.endsWith('_frog.flr'),
      orElse: () => exact,
    );
  }

  SceneAssets resolve({
    required String scene,
    required DayPart dayPart,
    required WeatherCondition condition,
  }) {
    return SceneAssets(
      _resolveBackground(scene, dayPart, condition),
      _resolveFrog(scene, dayPart, condition),
    );
  }
}
