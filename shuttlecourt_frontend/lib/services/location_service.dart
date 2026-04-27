import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shuttlecourt/models/badminton_court.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shuttlecourt/config/api_config.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      // 🏎️ TĂNG TỐC: Dùng accuracy thấp và timeout ngắn để tránh bị treo
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Nếu lỗi hoặc timeout, thử lấy vị trí cuối cùng được lưu
      return await Geolocator.getLastKnownPosition();
    }
  }

  static Future<List<CourtWithDistance>> getNearestCourts({
    int maxResults = 5,
    double maxDistanceKm = 50,
  }) async {
    try {
      // 🌐 WEB PLATFORM: Skip geolocator (not supported), just fetch courts from API
      if (kIsWeb) {
        debugPrint('🌐 WEB: Skipping geolocator, fetching all courts from API');
        try {
          final response = await http
              .get(Uri.parse('${ApiConfig.courtsUrl}/all'))
              .timeout(const Duration(seconds: 5));

          debugPrint('🔵 API Response Status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            debugPrint('✅ Courts from API: ${data.length} records');
            final courts = data
                .map((json) => BadmintonCourt.fromJson(json))
                .toList();
            return courts
                .take(maxResults)
                .map((e) => CourtWithDistance(court: e, distanceKm: 0))
                .toList();
          } else {
            debugPrint(
              '⚠️ API returned status ${response.statusCode}, using sample data',
            );
            return sampleBadmintonCourts
                .take(maxResults)
                .map((e) => CourtWithDistance(court: e, distanceKm: 0))
                .toList();
          }
        } catch (e) {
          debugPrint('❌ WEB: Error fetching courts: $e');
          return sampleBadmintonCourts
              .take(maxResults)
              .map((e) => CourtWithDistance(court: e, distanceKm: 0))
              .toList();
        }
      }

      // 📱 MOBILE: Use geolocator to get nearby courts
      // 🚀 CHẠY SONG SONG: Lấy vị trí và Fetch data cùng lúc để tăng tốc
      final results = await Future.wait([
        getCurrentLocation(), // Lấy vị trí
        http
            .get(Uri.parse('${ApiConfig.courtsUrl}/all'))
            .timeout(const Duration(seconds: 5)), // Fetch API
      ]);

      final Position? position = results[0] as Position?;
      final http.Response response = results[1] as http.Response;

      debugPrint('🔵 API Response Status: ${response.statusCode}');

      List<BadmintonCourt> courts = [];
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ Courts from API: ${data.length} records');
        courts = data.map((json) => BadmintonCourt.fromJson(json)).toList();
      } else {
        debugPrint(
          '⚠️ API returned status ${response.statusCode}, using sample data',
        );
        courts = sampleBadmintonCourts;
      }

      if (position == null) {
        debugPrint(
          '⚠️ Position is null, returning ${courts.take(maxResults).length} courts without distance',
        );
        return courts
            .take(maxResults)
            .map((e) => CourtWithDistance(court: e, distanceKm: 0))
            .toList();
      }

      final courtsWithDistance = courts
          .map(
            (court) => CourtWithDistance(
              court: court,
              distanceKm: court.distanceTo(
                position.latitude,
                position.longitude,
              ),
            ),
          )
          .toList();

      final nearbyCourts = courtsWithDistance
          .where((item) => item.distanceKm <= maxDistanceKm)
          .toList();
      nearbyCourts.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      debugPrint(
        '✅ Returning ${nearbyCourts.take(maxResults).length} nearby courts',
      );
      return nearbyCourts.take(maxResults).toList();
    } catch (e) {
      debugPrint('❌ Error in getNearestCourts: $e');
      return sampleBadmintonCourts
          .take(maxResults)
          .map((e) => CourtWithDistance(court: e, distanceKm: 0))
          .toList();
    }
  }
}

class CourtWithDistance {
  final BadmintonCourt court;
  final double distanceKm;

  CourtWithDistance({required this.court, required this.distanceKm});
}
