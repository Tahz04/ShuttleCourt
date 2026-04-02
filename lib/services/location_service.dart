import 'package:geolocator/geolocator.dart';
import 'package:quynh/models/badminton_court.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  static Future<List<CourtWithDistance>> getNearestCourts({
    int maxResults = 5,
    double maxDistanceKm = 50,
  }) async {
    try {
      final position = await getCurrentLocation();
      if (position == null) {
        return sampleBadmintonCourts
            .take(maxResults)
            .map((e) => CourtWithDistance(court: e, distanceKm: 0))
            .toList();
      }

      final courtsWithDistance = sampleBadmintonCourts
          .map((court) =>
          CourtWithDistance(
            court: court,
            distanceKm: court.distanceTo(
              position.latitude,
              position.longitude,
            ),
          ))
          .toList();

      final nearbyCourts = courtsWithDistance
          .where((item) => item.distanceKm <= maxDistanceKm)
          .toList();

      nearbyCourts.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      return nearbyCourts.take(maxResults).toList();
    } catch (e) {
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

  CourtWithDistance({
    required this.court,
    required this.distanceKm,
  });
}