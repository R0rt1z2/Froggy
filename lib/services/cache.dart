import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather.dart';
import 'location_service.dart';

class Cache {
  static const _kWeather = 'last_weather';
  static const _kLat = 'last_lat';
  static const _kLon = 'last_lon';

  Future<void> saveWeather(WeatherData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWeather, jsonEncode(data.toJson()));
  }

  Future<WeatherData?> loadWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kWeather);
    if (raw == null) return null;
    try {
      return WeatherData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLocation(Coords c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLat, c.lat);
    await prefs.setDouble(_kLon, c.lon);
  }

  Future<Coords?> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_kLat);
    final lon = prefs.getDouble(_kLon);
    if (lat == null || lon == null) return null;
    return Coords(lat, lon);
  }
}
