import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class Coords {
  final double lat;
  final double lon;
  const Coords(this.lat, this.lon);
}

class ResolvedLocation {
  final Coords coords;
  final String? name;
  const ResolvedLocation(this.coords, this.name);
}

class LocationService {
  LocationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ResolvedLocation?> current({
    bool allowPrompt = true,
    bool useDevice = true,
  }) async {
    if (useDevice) {
      final device = await _deviceLocation(allowPrompt: allowPrompt);
      if (device != null) return ResolvedLocation(device, null);
    }
    return _ipLocation();
  }

  Future<Coords?> _deviceLocation({required bool allowPrompt}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _lastKnown();
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied && allowPrompt) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return _lastKnown();
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return Coords(pos.latitude, pos.longitude);
    } catch (_) {
      return _lastKnown();
    }
  }

  Future<Coords?> _lastKnown() async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      return pos == null ? null : Coords(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<ResolvedLocation?> _ipLocation() async {
    try {
      final resp = await _client
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (json['success'] == false) return null;
      final lat = (json['latitude'] as num?)?.toDouble();
      final lon = (json['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) return null;
      final city = json['city'] as String?;
      return ResolvedLocation(Coords(lat, lon), city);
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}
