import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:http/http.dart' as http;
import 'dart:convert';

class Location {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Location({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

Future<List<Location>> locationFromAddress(String address) async {
  // 📱 Mobile fallback (Android / iOS)
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      final List<gc.Location> nativeLocs = await gc.locationFromAddress(address);
      return nativeLocs.map((e) => Location(
        latitude: e.latitude,
        longitude: e.longitude,
        timestamp: e.timestamp,
      )).toList();
    } catch (e) {
      debugPrint('Native geocoding failed, falling back to Nominatim: $e');
    }
  }

  // 🌐 Windows, Web, macOS, Linux, or native failed: Use OpenStreetMap Nominatim API
  try {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1');
    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'shuttlecourt-app',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final double lat = double.parse(data[0]['lat']);
        final double lng = double.parse(data[0]['lon']);
        return [
          Location(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
          )
        ];
      }
    }
  } catch (e) {
    debugPrint('Nominatim geocoding error: $e');
  }

  throw Exception('Could not find location for the given address');
}
