import 'dart:ui' show Color, Offset, Shadow;

enum TempUnit { celsius, fahrenheit }

enum ClockFormat { h24, h12 }

enum LocationMode { automatic, manual }

enum DimMode { off, auto, scheduled }

class SavedLocation {
  final String name;
  final double lat;
  final double lon;
  final String? region;

  const SavedLocation({
    required this.name,
    required this.lat,
    required this.lon,
    this.region,
  });

  String get id => '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';

  String get label =>
      (region == null || region!.isEmpty) ? name : '$name, $region';

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': lat,
        'lon': lon,
        'region': region,
      };

  static SavedLocation fromJson(Map<String, dynamic> j) => SavedLocation(
        name: j['name'] as String,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        region: j['region'] as String?,
      );
}

class Settings {
  final TempUnit unit;
  final ClockFormat hourFormat;
  final LocationMode locationMode;
  final List<SavedLocation> savedLocations;
  final String? selectedLocationId;
  final bool showLocation;
  final bool showMusicTitle;
  final double textShadow;
  final double overlayScale;
  final bool checkUpdatesOnStartup;
  final bool showDate;
  final DimMode dimMode;
  final double nightDim;
  final int dimStart;
  final int dimEnd;
  final int refreshMinutes;
  final int rotateMinutes;
  final bool showStatus;
  final bool showWifi;
  final bool showBluetooth;
  final bool showMusic;
  final bool kioskMode;

  const Settings({
    this.unit = TempUnit.celsius,
    this.hourFormat = ClockFormat.h24,
    this.locationMode = LocationMode.automatic,
    this.savedLocations = const [],
    this.selectedLocationId,
    this.showLocation = false,
    this.showMusicTitle = false,
    this.textShadow = 0.8,
    this.overlayScale = 1.0,
    this.checkUpdatesOnStartup = true,
    this.showDate = true,
    this.dimMode = DimMode.off,
    this.nightDim = 0.45,
    this.dimStart = 1320,
    this.dimEnd = 420,
    this.refreshMinutes = 20,
    this.rotateMinutes = 5,
    this.showStatus = true,
    this.showWifi = true,
    this.showBluetooth = true,
    this.showMusic = true,
    this.kioskMode = false,
  });

  double dimAt(double nightFactor, DateTime localTime) {
    switch (dimMode) {
      case DimMode.off:
        return 0;
      case DimMode.auto:
        return (nightDim * nightFactor).clamp(0.0, 0.85);
      case DimMode.scheduled:
        final m = localTime.hour * 60 + localTime.minute;
        final inRange = dimStart == dimEnd
            ? false
            : (dimStart < dimEnd
                ? (m >= dimStart && m < dimEnd)
                : (m >= dimStart || m < dimEnd));
        return inRange ? nightDim.clamp(0.0, 0.85) : 0.0;
    }
  }

  List<Shadow> get textShadows {
    final a = textShadow.clamp(0.0, 1.0);
    if (a <= 0.0) return const [];
    return [
      Shadow(
        blurRadius: 6 + 12 * a,
        color: const Color(0xFF000000).withValues(alpha: a),
        offset: const Offset(0, 1),
      ),
    ];
  }

  SavedLocation? get selected {
    if (locationMode != LocationMode.manual) return null;
    for (final l in savedLocations) {
      if (l.id == selectedLocationId) return l;
    }
    return savedLocations.isNotEmpty ? savedLocations.first : null;
  }

  String get locationKey => locationMode == LocationMode.manual
      ? 'manual:${selected?.id ?? ''}'
      : 'auto';

  double toDisplayTemp(double celsius) =>
      unit == TempUnit.fahrenheit ? celsius * 9 / 5 + 32 : celsius;

  String get unitSymbol => unit == TempUnit.fahrenheit ? '°F' : '°C';

  String formatTemp(double celsius) => '${toDisplayTemp(celsius).round()}°';

  String formatTempWithUnit(double celsius) =>
      '${toDisplayTemp(celsius).round()}$unitSymbol';

  Settings copyWith({
    TempUnit? unit,
    ClockFormat? hourFormat,
    LocationMode? locationMode,
    List<SavedLocation>? savedLocations,
    String? selectedLocationId,
    bool clearSelected = false,
    bool? showLocation,
    bool? showMusicTitle,
    double? textShadow,
    double? overlayScale,
    bool? checkUpdatesOnStartup,
    bool? showDate,
    DimMode? dimMode,
    double? nightDim,
    int? dimStart,
    int? dimEnd,
    int? refreshMinutes,
    int? rotateMinutes,
    bool? showStatus,
    bool? showWifi,
    bool? showBluetooth,
    bool? showMusic,
    bool? kioskMode,
  }) {
    return Settings(
      unit: unit ?? this.unit,
      hourFormat: hourFormat ?? this.hourFormat,
      locationMode: locationMode ?? this.locationMode,
      savedLocations: savedLocations ?? this.savedLocations,
      selectedLocationId: clearSelected
          ? null
          : (selectedLocationId ?? this.selectedLocationId),
      showLocation: showLocation ?? this.showLocation,
      showMusicTitle: showMusicTitle ?? this.showMusicTitle,
      textShadow: textShadow ?? this.textShadow,
      overlayScale: overlayScale ?? this.overlayScale,
      checkUpdatesOnStartup:
          checkUpdatesOnStartup ?? this.checkUpdatesOnStartup,
      showDate: showDate ?? this.showDate,
      dimMode: dimMode ?? this.dimMode,
      nightDim: nightDim ?? this.nightDim,
      dimStart: dimStart ?? this.dimStart,
      dimEnd: dimEnd ?? this.dimEnd,
      refreshMinutes: refreshMinutes ?? this.refreshMinutes,
      rotateMinutes: rotateMinutes ?? this.rotateMinutes,
      showStatus: showStatus ?? this.showStatus,
      showWifi: showWifi ?? this.showWifi,
      showBluetooth: showBluetooth ?? this.showBluetooth,
      showMusic: showMusic ?? this.showMusic,
      kioskMode: kioskMode ?? this.kioskMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'unit': unit.name,
        'hourFormat': hourFormat.name,
        'locationMode': locationMode.name,
        'savedLocations': savedLocations.map((l) => l.toJson()).toList(),
        'selectedLocationId': selectedLocationId,
        'showLocation': showLocation,
        'showMusicTitle': showMusicTitle,
        'textShadow': textShadow,
        'overlayScale': overlayScale,
        'checkUpdatesOnStartup': checkUpdatesOnStartup,
        'showDate': showDate,
        'dimMode': dimMode.name,
        'nightDim': nightDim,
        'dimStart': dimStart,
        'dimEnd': dimEnd,
        'refreshMinutes': refreshMinutes,
        'rotateMinutes': rotateMinutes,
        'showStatus': showStatus,
        'showWifi': showWifi,
        'showBluetooth': showBluetooth,
        'showMusic': showMusic,
        'kioskMode': kioskMode,
      };

  static Settings fromJson(Map<String, dynamic> j) => Settings(
        unit: _enumByName(TempUnit.values, j['unit'], TempUnit.celsius),
        hourFormat:
            _enumByName(ClockFormat.values, j['hourFormat'], ClockFormat.h24),
        locationMode: _enumByName(
            LocationMode.values, j['locationMode'], LocationMode.automatic),
        savedLocations: ((j['savedLocations'] as List?) ?? const [])
            .map((e) => SavedLocation.fromJson(e as Map<String, dynamic>))
            .toList(),
        selectedLocationId: j['selectedLocationId'] as String?,
        showLocation: (j['showLocation'] as bool?) ?? false,
        showMusicTitle: (j['showMusicTitle'] as bool?) ?? false,
        textShadow: (j['textShadow'] as num?)?.toDouble() ?? 0.8,
        overlayScale: (j['overlayScale'] as num?)?.toDouble() ?? 1.0,
        checkUpdatesOnStartup:
            (j['checkUpdatesOnStartup'] as bool?) ?? true,
        showDate: (j['showDate'] as bool?) ?? true,
        dimMode: _enumByName(DimMode.values, j['dimMode'], DimMode.off),
        nightDim: (j['nightDim'] as num?)?.toDouble() ?? 0.45,
        dimStart: (j['dimStart'] as num?)?.toInt() ?? 1320,
        dimEnd: (j['dimEnd'] as num?)?.toInt() ?? 420,
        refreshMinutes: (j['refreshMinutes'] as num?)?.toInt() ?? 20,
        rotateMinutes: (j['rotateMinutes'] as num?)?.toInt() ?? 5,
        showStatus: (j['showStatus'] as bool?) ?? true,
        showWifi: (j['showWifi'] as bool?) ?? true,
        showBluetooth: (j['showBluetooth'] as bool?) ?? true,
        showMusic: (j['showMusic'] as bool?) ?? true,
        kioskMode: (j['kioskMode'] as bool?) ?? false,
      );

  static T _enumByName<T extends Enum>(
      List<T> values, Object? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
