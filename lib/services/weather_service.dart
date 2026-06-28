import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather.dart';

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> fetch(double lat, double lon) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'latitude': lat.toStringAsFixed(4),
      'longitude': lon.toStringAsFixed(4),
      'current': 'weather_code,temperature_2m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset',
      'timezone': 'auto',
      'forecast_days': '1',
    });

    final resp = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw WeatherException('Open-Meteo returned HTTP ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final current = body['current'] as Map<String, dynamic>?;
    if (current == null) {
      throw const WeatherException('No current weather in response');
    }

    final daily = body['daily'] as Map<String, dynamic>?;
    final code = (current['weather_code'] as num).toInt();
    return WeatherData(
      condition: conditionFromWmo(code),
      weatherCode: code,
      temperatureC: (current['temperature_2m'] as num).toDouble(),
      tempMaxC: _firstNum(daily?['temperature_2m_max']),
      tempMinC: _firstNum(daily?['temperature_2m_min']),
      sunrise: _firstDate(daily?['sunrise']),
      sunset: _firstDate(daily?['sunset']),
      utcOffsetSeconds: (body['utc_offset_seconds'] as num?)?.toInt(),
      fetchedAt: DateTime.now(),
    );
  }

  static DateTime? _firstDate(Object? list) {
    if (list is List && list.isNotEmpty && list.first is String) {
      final d = DateTime.tryParse(list.first as String);
      if (d == null) return null;
      return DateTime.utc(d.year, d.month, d.day, d.hour, d.minute, d.second);
    }
    return null;
  }

  static double? _firstNum(Object? list) {
    if (list is List && list.isNotEmpty && list.first is num) {
      return (list.first as num).toDouble();
    }
    return null;
  }

  void dispose() => _client.close();
}

class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);
  @override
  String toString() => 'WeatherException: $message';
}
