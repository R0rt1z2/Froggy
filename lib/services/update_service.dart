import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool updateAvailable;
  final String releaseUrl;
  final String notes;
  final String? apkUrl;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateAvailable,
    required this.releaseUrl,
    required this.notes,
    this.apkUrl,
  });
}

class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _api =
      'https://api.github.com/repos/R0rt1z2/Froggy/releases/latest';
  static const releasesUrl =
      'https://github.com/R0rt1z2/Froggy/releases/latest';
  static const repoUrl = 'https://github.com/R0rt1z2/Froggy';

  Future<UpdateInfo?> check(String currentVersion) async {
    try {
      final resp = await _client.get(
        Uri.parse(_api),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'Froggy-App',
        },
      ).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String?) ?? '';
      final latest = tag.replaceFirst(RegExp(r'^[vV]'), '').trim();
      if (latest.isEmpty) return null;
      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latest,
        updateAvailable: _isNewer(latest, currentVersion),
        releaseUrl: (json['html_url'] as String?) ?? releasesUrl,
        notes: (json['body'] as String?)?.trim() ?? '',
        apkUrl: _apkAsset(json['assets']),
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();

  static String? _apkAsset(Object? assets) {
    if (assets is! List) return null;
    for (final a in assets) {
      if (a is! Map) continue;
      final name = (a['name'] as String?)?.toLowerCase() ?? '';
      if (name.endsWith('.apk')) return a['browser_download_url'] as String?;
    }
    return null;
  }

  static const _kSkipped = 'skipped_update_version';

  Future<String?> skippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSkipped);
  }

  Future<void> skipVersion(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSkipped, v);
  }

  static bool _isNewer(String latest, String current) {
    final a = _parse(latest);
    final b = _parse(current);
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }

  static List<int> _parse(String v) {
    final parts = v.split(RegExp(r'[.+\-]'));
    final out = <int>[0, 0, 0];
    for (var i = 0; i < 3 && i < parts.length; i++) {
      out[i] = int.tryParse(parts[i].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return out;
  }
}
