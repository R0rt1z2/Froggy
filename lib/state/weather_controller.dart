import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/settings.dart';
import '../models/weather.dart';
import '../services/asset_catalog.dart';
import '../services/cache.dart';
import '../services/location_service.dart';
import '../services/system_status_service.dart';
import '../services/weather_service.dart';
import 'settings_controller.dart';

const Object _unset = Object();

class WeatherController extends ChangeNotifier {
  WeatherController({
    AssetCatalog? catalog,
    WeatherService? weatherService,
    LocationService? locationService,
    Cache? cache,
    SettingsController? settings,
    this.refreshInterval = const Duration(minutes: 20),
    this.sceneRotation = const Duration(minutes: 5),
    this.allowLocationPrompt = true,
  })  : _catalog = catalog,
        _weather = weatherService ?? WeatherService(),
        _location = locationService ?? LocationService(),
        _cache = cache ?? Cache(),
        _settings = settings {
    _lastLocationKey = _settings?.settings.locationKey ?? 'auto';
    _settings?.addListener(_onSettingsChanged);
  }

  final WeatherService _weather;
  final LocationService _location;
  final Cache _cache;
  final SettingsController? _settings;
  AssetCatalog? _catalog;

  final Duration refreshInterval;

  final Duration sceneRotation;

  final bool allowLocationPrompt;

  Timer? _refreshTimer;
  Timer? _tick;
  Timer? _sceneTimer;
  int _sceneIndex = 0;
  String _lastLocationKey = 'auto';
  String _lastIntervals = '';
  bool _started = false;
  bool _active = true;
  bool _useDeviceLocation = true;
  List<Object?> _lastPublished = const [_unset];

  WeatherData? _data;
  SceneAssets? _scene;
  String? _error;
  String? _locationName;
  bool _loading = false;
  bool _locationDenied = false;
  bool _usingApproximateLocation = false;

  WeatherData? get weather => _data;
  SceneAssets? get scene => _scene;
  String? get error => _error;

  bool get ready => _catalog != null && _scene != null;

  String? get locationName => _locationName;
  bool get loading => _loading;

  bool get locationDenied => _locationDenied;
  bool get usingApproximateLocation => _usingApproximateLocation;
  List<String> get scenes => _catalog?.scenes ?? const [];

  Future<void> init() async {
    _catalog ??= await AssetCatalog.load();
    _useDeviceLocation = !await SystemStatusService().isTelevision();
    _data = await _cache.loadWeather();
    _apply();

    _started = true;
    _lastLocationKey = _settings?.settings.locationKey ?? 'auto';
    _lastIntervals = _intervalsKey();
    _startTimers();
    await refresh();
  }

  String _intervalsKey() {
    final s = _settings?.settings;
    return '${s?.refreshMinutes}:${s?.rotateMinutes}';
  }

  void setActive(bool active) {
    if (_active == active) return;
    _active = active;
    if (!_started) return;
    if (!active) {
      _stopTimers();
      return;
    }
    _startTimers();
    _apply();
    if (_data?.isStale ?? true) refresh();
  }

  void _startTimers() {
    _stopTimers();
    if (!_active) return;
    _tick = Timer.periodic(const Duration(minutes: 1), (_) => _apply());
    final rm = _settings?.settings.refreshMinutes ?? refreshInterval.inMinutes;
    final refreshDur = rm > 0 ? Duration(minutes: rm) : refreshInterval;
    _refreshTimer = Timer.periodic(refreshDur, (_) => refresh());
    final rot = _settings?.settings.rotateMinutes ?? sceneRotation.inMinutes;
    if (rot > 0) {
      _sceneTimer = Timer.periodic(Duration(minutes: rot), (_) => cycleScene());
    }
  }

  void _stopTimers() {
    _tick?.cancel();
    _tick = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _sceneTimer?.cancel();
    _sceneTimer = null;
  }

  Future<void> refresh() async {
    _catalog ??= await AssetCatalog.load();
    _loading = true;
    _publish();
    try {
      final resolved = await _resolveLocation();
      if (resolved != null) {
        _usingApproximateLocation = resolved.source == LocationSource.ip;
        _locationDenied = resolved.permissionDenied;
      }
      var coords = resolved?.coords ?? await _cache.loadLocation();
      if (coords == null) {
        throw const WeatherException('Location unavailable');
      }
      _locationName = resolved?.name ?? _locationName;
      await _cache.saveLocation(coords);

      final data = await _weather.fetch(coords.lat, coords.lon);
      _data = data;
      _error = null;
      await _cache.saveWeather(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _apply();
    }
  }

  Future<ResolvedLocation?> _resolveLocation() async {
    final s = _settings?.settings;
    if (s != null && s.locationMode == LocationMode.manual) {
      final sel = s.selected;
      if (sel != null) {
        return ResolvedLocation(Coords(sel.lat, sel.lon), sel.name);
      }
    }
    return _location.current(
      allowPrompt: allowLocationPrompt,
      useDevice: _useDeviceLocation,
    );
  }

  void _onSettingsChanged() {
    final key = _settings?.settings.locationKey ?? 'auto';
    final changed = key != _lastLocationKey;
    _lastLocationKey = key;
    if (_started && changed) refresh();

    final iv = _intervalsKey();
    if (_started && iv != _lastIntervals) {
      _lastIntervals = iv;
      _startTimers();
    }
  }

  void cycleScene() {
    if (scenes.isEmpty) return;
    _sceneIndex = (_sceneIndex + 1) % scenes.length;
    _apply();
  }

  void _apply() {
    final catalog = _catalog;
    if (catalog == null || catalog.scenes.isEmpty) return;

    final dayPart = _data?.dayPart ?? dayPartFor(DateTime.now(), null, null);
    final condition = _data?.condition ?? WeatherCondition.sunny;
    final scene = catalog.scenes[_sceneIndex % catalog.scenes.length];

    final next = catalog.resolve(
      scene: scene,
      dayPart: dayPart,
      condition: condition,
    );

    if (_scene?.background != next.background || _scene?.frog != next.frog) {
      _scene = next;
    }
    _publish();
  }

  List<Object?> _snapshot() => [
        _scene?.background,
        _scene?.frog,
        _loading,
        _locationName,
        _error,
        _locationDenied,
        _usingApproximateLocation,
        _data?.weatherCode,
        _data?.temperatureC,
        _data?.tempMinC,
        _data?.tempMaxC,
        _data?.utcOffsetSeconds,
        _data?.isStale,
      ];

  void _publish() {
    final next = _snapshot();
    if (listEquals(_lastPublished, next)) return;
    _lastPublished = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _settings?.removeListener(_onSettingsChanged);
    _stopTimers();
    _weather.dispose();
    _location.dispose();
    super.dispose();
  }
}
