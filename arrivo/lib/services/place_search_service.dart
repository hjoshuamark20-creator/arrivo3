import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class PlaceResult {
  const PlaceResult({required this.name, required this.latitude, required this.longitude});
  final String name;
  final double latitude;
  final double longitude;
}

class SearchException implements Exception {
  const SearchException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Place search with OpenStreetMap Nominatim (free, no API key).
/// Nominatim requires a descriptive User-Agent and at most one request per second,
/// so the UI should wait for the user to stop typing before searching.
class PlaceSearchService {
  PlaceSearchService([http.Client? client]) : _client = client ?? http.Client();
  final http.Client _client;

  Future<List<PlaceResult>> search(String query) async {
    final text = query.trim();
    if (text.length < 3) return const [];
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': text,
      'format': 'json',
      'limit': '6',
    });
    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': 'Arrivo/1.0 (student project)'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw const SearchException('Search is unavailable right now. Try again.');
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((raw) {
        final item = raw as Map<String, dynamic>;
        return PlaceResult(
          name: (item['display_name'] as String?) ?? 'Unnamed place',
          latitude: double.parse(item['lat'] as String),
          longitude: double.parse(item['lon'] as String),
        );
      }).toList();
    } on SearchException {
      rethrow;
    } on TimeoutException {
      throw const SearchException('Search took too long. Check your internet connection.');
    } catch (_) {
      throw const SearchException('Could not search. Check your internet connection.');
    }
  }
}
