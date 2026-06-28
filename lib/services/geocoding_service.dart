import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/settings.dart';

class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://geocoding-api.open-meteo.com/v1/search';

  Future<List<SavedLocation>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final uri = Uri.parse(_base).replace(queryParameters: {
      'name': q,
      'count': '8',
      'language': 'en',
      'format': 'json',
    });

    final resp = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) return const [];

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = body['results'] as List?;
    if (results == null) return const [];

    return results.map((e) {
      final m = e as Map<String, dynamic>;
      final region = [m['admin1'], m['country']]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(', ');
      return SavedLocation(
        name: m['name'] as String,
        lat: (m['latitude'] as num).toDouble(),
        lon: (m['longitude'] as num).toDouble(),
        region: region.isEmpty ? null : region,
      );
    }).toList();
  }

  void dispose() => _client.close();
}
