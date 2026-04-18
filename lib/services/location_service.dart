import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quynh/models/badminton_court.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quynh/config/api_config.dart';

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
      // 🚀 CHẠY SONG SONG: Lấy vị trí và Fetch data cùng lúc để tăng tốc
      final results = await Future.wait([
        getCurrentLocation(), // Lấy vị trí
        http.get(Uri.parse('${ApiConfig.courtsUrl}/all')).timeout(const Duration(seconds: 5)), // Fetch API
      ]);

      final Position? position = results[0] as Position?;
      final http.Response response = results[1] as http.Response;
      
      List<BadmintonCourt> courts = [];
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        courts = data.map((json) => BadmintonCourt.fromJson(json)).toList();
      } else {
        courts = sampleBadmintonCourts;
      }

      if (position == null) {
        return courts.take(maxResults).map((e) => CourtWithDistance(court: e, distanceKm: 0)).toList();
      }

      final courtsWithDistance = courts.map((court) => CourtWithDistance(
        court: court,
        distanceKm: court.distanceTo(position.latitude, position.longitude),
      )).toList();

      final nearbyCourts = courtsWithDistance.where((item) => item.distanceKm <= maxDistanceKm).toList();
      nearbyCourts.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      return nearbyCourts.take(maxResults).toList();
    } catch (e) {
      debugPrint('Error in getNearestCourts: $e');
      return sampleBadmintonCourts.take(maxResults).map((e) => CourtWithDistance(court: e, distanceKm: 0)).toList();
    }
  }
}

class CourtWithDistance {
  final BadmintonCourt court;
  final double distanceKm;

  CourtWithDistance({
    required this.court,
    required this.distanceKm,
  });
}