library;

enum WeatherCondition { sunny, cloudy, hazy, rainy, snowy }

enum DayPart { morning, day, sunset, night }

extension WeatherConditionName on WeatherCondition {
  String get asset => name;
}

extension DayPartName on DayPart {
  String get asset => name;
}

class WeatherData {
  final WeatherCondition condition;
  final int weatherCode;
  final double temperatureC;
  final double? tempMaxC;
  final double? tempMinC;

  final DateTime? sunrise;
  final DateTime? sunset;

  final int? utcOffsetSeconds;
  final DateTime fetchedAt;

  const WeatherData({
    required this.condition,
    required this.weatherCode,
    required this.temperatureC,
    required this.tempMaxC,
    required this.tempMinC,
    required this.sunrise,
    required this.sunset,
    required this.utcOffsetSeconds,
    required this.fetchedAt,
  });

  DateTime get localTime {
    final off = utcOffsetSeconds;
    if (off != null) {
      return DateTime.now().toUtc().add(Duration(seconds: off));
    }
    final n = DateTime.now();
    return DateTime.utc(n.year, n.month, n.day, n.hour, n.minute, n.second);
  }

  DayPart get dayPart => dayPartFor(localTime, sunrise, sunset);

  bool get isStale =>
      DateTime.now().difference(fetchedAt) > const Duration(hours: 2);

  String get description => wmoDescription(weatherCode);

  String get summary {
    final hl = (tempMaxC != null && tempMinC != null)
        ? ' · ↑${tempMaxC!.round()}° ↓${tempMinC!.round()}°'
        : '';
    return '$description$hl';
  }

  Map<String, dynamic> toJson() => {
        'condition': condition.name,
        'weatherCode': weatherCode,
        'temperatureC': temperatureC,
        'tempMaxC': tempMaxC,
        'tempMinC': tempMinC,
        'sunrise': sunrise?.toIso8601String(),
        'sunset': sunset?.toIso8601String(),
        'utcOffsetSeconds': utcOffsetSeconds,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  static WeatherData fromJson(Map<String, dynamic> json) => WeatherData(
        condition: WeatherCondition.values.byName(json['condition'] as String),
        weatherCode: (json['weatherCode'] as num?)?.toInt() ?? 0,
        temperatureC: (json['temperatureC'] as num).toDouble(),
        tempMaxC: (json['tempMaxC'] as num?)?.toDouble(),
        tempMinC: (json['tempMinC'] as num?)?.toDouble(),
        sunrise: _parseOrNull(json['sunrise']),
        sunset: _parseOrNull(json['sunset']),
        utcOffsetSeconds: (json['utcOffsetSeconds'] as num?)?.toInt(),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );

  static DateTime? _parseOrNull(Object? v) =>
      v == null ? null : DateTime.parse(v as String);
}

WeatherCondition conditionFromWmo(int code) {
  if (code <= 1) return WeatherCondition.sunny;
  if (code <= 3) return WeatherCondition.cloudy;
  if (code == 45 || code == 48) return WeatherCondition.hazy;
  if (code >= 71 && code <= 77) return WeatherCondition.snowy;
  if (code == 85 || code == 86) return WeatherCondition.snowy;
  if (code >= 51 && code <= 67) return WeatherCondition.rainy;
  if (code >= 80 && code <= 82) return WeatherCondition.rainy;
  if (code >= 95) return WeatherCondition.rainy;
  return WeatherCondition.cloudy;
}

String wmoDescription(int code) {
  switch (code) {
    case 0:
      return 'Clear';
    case 1:
      return 'Mainly clear';
    case 2:
      return 'Partly cloudy';
    case 3:
      return 'Overcast';
    case 45:
      return 'Fog';
    case 48:
      return 'Rime fog';
    case 51:
      return 'Light drizzle';
    case 53:
      return 'Drizzle';
    case 55:
      return 'Heavy drizzle';
    case 56:
    case 57:
      return 'Freezing drizzle';
    case 61:
      return 'Light rain';
    case 63:
      return 'Rain';
    case 65:
      return 'Heavy rain';
    case 66:
    case 67:
      return 'Freezing rain';
    case 71:
      return 'Light snow';
    case 73:
      return 'Snow';
    case 75:
      return 'Heavy snow';
    case 77:
      return 'Snow grains';
    case 80:
      return 'Light showers';
    case 81:
      return 'Showers';
    case 82:
      return 'Heavy showers';
    case 85:
      return 'Snow showers';
    case 86:
      return 'Heavy snow showers';
    case 95:
      return 'Thunderstorm';
    case 96:
    case 99:
      return 'Thunderstorm, hail';
    default:
      return 'Unknown';
  }
}

DayPart dayPartFor(DateTime now, DateTime? sunrise, DateTime? sunset) {
  if (sunrise != null && sunset != null) {
    final morningEnd = sunrise.add(const Duration(minutes: 150));
    final sunsetStart = sunset.subtract(const Duration(hours: 1));
    final sunsetEnd = sunset.add(const Duration(minutes: 30));
    if (now.isBefore(sunrise)) return DayPart.night;
    if (now.isBefore(morningEnd)) return DayPart.morning;
    if (now.isBefore(sunsetStart)) return DayPart.day;
    if (now.isBefore(sunsetEnd)) return DayPart.sunset;
    return DayPart.night;
  }
  final h = now.hour;
  if (h >= 6 && h < 9) return DayPart.morning;
  if (h >= 9 && h < 17) return DayPart.day;
  if (h >= 17 && h < 19) return DayPart.sunset;
  return DayPart.night;
}
