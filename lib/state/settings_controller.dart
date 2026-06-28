import 'package:flutter/foundation.dart';

import '../models/settings.dart';
import '../services/settings_store.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({SettingsStore? store})
      : _store = store ?? SettingsStore();

  final SettingsStore _store;
  Settings _settings = const Settings();

  Settings get settings => _settings;

  Future<void> load() async {
    _settings = await _store.load();
    notifyListeners();
  }

  Future<void> _update(Settings next) async {
    _settings = next;
    notifyListeners();
    await _store.save(next);
  }

  Future<void> setUnit(TempUnit unit) =>
      _update(_settings.copyWith(unit: unit));

  Future<void> setClockFormat(ClockFormat f) =>
      _update(_settings.copyWith(hourFormat: f));

  Future<void> setShowLocation(bool v) =>
      _update(_settings.copyWith(showLocation: v));

  Future<void> setShowMusicTitle(bool v) =>
      _update(_settings.copyWith(showMusicTitle: v));

  Future<void> setTextShadow(double v) =>
      _update(_settings.copyWith(textShadow: v));

  Future<void> setShowDate(bool v) =>
      _update(_settings.copyWith(showDate: v));

  Future<void> setNightDim(double v) =>
      _update(_settings.copyWith(nightDim: v));

  Future<void> setDimMode(DimMode v) =>
      _update(_settings.copyWith(dimMode: v));

  Future<void> setDimStart(int v) => _update(_settings.copyWith(dimStart: v));

  Future<void> setDimEnd(int v) => _update(_settings.copyWith(dimEnd: v));

  Future<void> setShowStatus(bool v) =>
      _update(_settings.copyWith(showStatus: v));

  Future<void> setShowWifi(bool v) => _update(_settings.copyWith(showWifi: v));

  Future<void> setShowBluetooth(bool v) =>
      _update(_settings.copyWith(showBluetooth: v));

  Future<void> setShowMusic(bool v) => _update(_settings.copyWith(showMusic: v));

  Future<void> setKioskMode(bool v) =>
      _update(_settings.copyWith(kioskMode: v));

  Future<void> resetToDefaults() {
    final keep = _settings;
    return _update(Settings(
      savedLocations: keep.savedLocations,
      locationMode: keep.locationMode,
      selectedLocationId: keep.selectedLocationId,
    ));
  }

  Future<void> setRefreshMinutes(int v) =>
      _update(_settings.copyWith(refreshMinutes: v));

  Future<void> setRotateMinutes(int v) =>
      _update(_settings.copyWith(rotateMinutes: v));

  Future<void> setLocationMode(LocationMode mode) =>
      _update(_settings.copyWith(locationMode: mode));

  Future<void> addLocation(SavedLocation loc) async {
    final exists = _settings.savedLocations.any((l) => l.id == loc.id);
    final list =
        exists ? _settings.savedLocations : [..._settings.savedLocations, loc];

    await _update(_settings.copyWith(
      savedLocations: list,
      locationMode: LocationMode.manual,
      selectedLocationId: loc.id,
    ));
  }

  Future<void> removeLocation(String id) async {
    final list = _settings.savedLocations.where((l) => l.id != id).toList();
    final clearing = _settings.selectedLocationId == id;
    await _update(_settings.copyWith(
      savedLocations: list,
      clearSelected: clearing,
      locationMode: list.isEmpty ? LocationMode.automatic : null,
    ));
  }

  Future<void> selectLocation(String id) => _update(_settings.copyWith(
        locationMode: LocationMode.manual,
        selectedLocationId: id,
      ));
}
