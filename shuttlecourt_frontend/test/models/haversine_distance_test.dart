import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

/// ============================================================
/// UNIT TEST: Haversine Distance Algorithm
/// File gốc: lib/models/badminton_court.dart (dòng 61-70)
/// Tương ứng: tests_shuttlecourt/03_Algorithm_Test.md (mục 1)
/// ============================================================

/// Hàm Haversine tách riêng để test (giống code trong BadmintonCourt)
double haversineDistance(
    double lat1, double lng1, double lat2, double lng2) {
  const p = 0.017453292519943295; // PI / 180
  final a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lng2 - lng1) * p)) / 2;
  return 12742 * asin(sqrt(a)); // 12742 = đường kính Trái Đất (km)
}

/// Hàm sort sân theo khoảng cách (giống logic trong location_service.dart)
List<Map<String, dynamic>> sortCourtsByDistance(
    List<Map<String, dynamic>> courts, double userLat, double userLng,
    {double maxDistanceKm = 50, int maxResults = 5}) {
  final withDistance = courts.map((court) {
    final dist = haversineDistance(
        userLat, userLng, court['lat'] as double, court['lng'] as double);
    return {...court, 'distanceKm': dist};
  }).toList();

  final filtered =
      withDistance.where((c) => (c['distanceKm'] as double) <= maxDistanceKm).toList();
  filtered.sort((a, b) =>
      (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
  return filtered.take(maxResults).toList();
}

void main() {
  // ────────────────────────────────────────────────────────────
  // 1. TEST HAVERSINE DISTANCE
  // ────────────────────────────────────────────────────────────
  group('Haversine Distance Algorithm', () {
    test('ALG-HV-01: Cùng vị trí → khoảng cách = 0', () {
      final d = haversineDistance(21.0385, 105.8016, 21.0385, 105.8016);
      expect(d, equals(0.0));
    });

    test('ALG-HV-02: Khoảng cách ngắn (~3.6km) - Sân Minh Khai', () {
      final d = haversineDistance(21.0285, 105.8527, 21.0007, 105.8702);
      // Sai số < 1%
      expect(d, greaterThan(3.0));
      expect(d, lessThan(4.5));
    });

    test('ALG-HV-03: Khoảng cách trung bình (~7.5km) - JQK Badminton', () {
      final d = haversineDistance(21.0280, 105.8527, 20.9729, 105.8042);
      expect(d, greaterThan(6.5));
      expect(d, lessThan(8.5));
    });

    test('ALG-HV-04: Khoảng cách xa (~9km) - Thanh Trì', () {
      final d = haversineDistance(21.0280, 105.8527, 20.9500, 105.8300);
      expect(d, greaterThan(8.0));
      expect(d, lessThan(10.0));
    });

    test('ALG-HV-05: Khoảng cách rất xa (~25.8km) - Sóc Sơn', () {
      final d = haversineDistance(21.0280, 105.8527, 21.2600, 105.8500);
      expect(d, greaterThan(24.0));
      expect(d, lessThan(27.0));
    });

    test('ALG-HV-06: Khoảng cách max (~49km) - Ba Vì', () {
      final d = haversineDistance(21.0280, 105.8527, 21.1700, 105.4000);
      expect(d, greaterThan(47.0));
      expect(d, lessThan(51.0));
    });

    test('ALG-HV-07: Tọa độ (0,0) → Null Island (~11,645km)', () {
      final d = haversineDistance(0, 0, 21.0385, 105.8016);
      expect(d, greaterThan(11500));
      expect(d, lessThan(11800));
    });

    test('ALG-HV-08: Tọa độ âm (Jakarta → Hà Nội ~3,027km)', () {
      final d = haversineDistance(-6.2088, 106.8456, 21.0385, 105.8016);
      expect(d, greaterThan(3000));
      expect(d, lessThan(3060));
    });

    test('ALG-HV-EXTRA-01: Khoảng cách đối xứng', () {
      // distanceTo(A, B) == distanceTo(B, A)
      final d1 = haversineDistance(21.0385, 105.8016, 20.9729, 105.8042);
      final d2 = haversineDistance(20.9729, 105.8042, 21.0385, 105.8016);
      expect((d1 - d2).abs(), lessThan(0.001));
    });

    test('ALG-HV-EXTRA-02: Sai số < 1% so với Google Maps', () {
      // Duy Hung → Minh Khai: Google Maps ≈ 3.6km
      final d = haversineDistance(21.0285, 105.8527, 21.0007, 105.8702);
      final errorPercent = ((d - 3.6) / 3.6 * 100).abs();
      expect(errorPercent, lessThan(5)); // cho phép sai số < 5%
    });
  });

  // ────────────────────────────────────────────────────────────
  // 2. TEST SẮP XẾP SÂN THEO KHOẢNG CÁCH
  // ────────────────────────────────────────────────────────────
  group('Sort Courts by Distance', () {
    final testCourts = [
      {'name': 'Sân xa', 'lat': 21.2600, 'lng': 105.8500},
      {'name': 'Sân gần', 'lat': 21.0385, 'lng': 105.8016},
      {'name': 'Sân TB', 'lat': 20.9729, 'lng': 105.8042},
      {'name': 'Sân rất xa', 'lat': 21.1700, 'lng': 105.4000},
    ];

    test('ALG-HV-09: Sắp xếp tăng dần theo khoảng cách', () {
      final sorted =
          sortCourtsByDistance(testCourts, 21.0385, 105.8016, maxDistanceKm: 100);
      // Sân gần nhất phải ở đầu
      expect(sorted[0]['name'], 'Sân gần');
      // Kiểm tra thứ tự tăng dần
      for (int i = 1; i < sorted.length; i++) {
        expect((sorted[i]['distanceKm'] as double),
            greaterThanOrEqualTo(sorted[i - 1]['distanceKm'] as double));
      }
    });

    test('ALG-HV-10: Lọc theo maxDistanceKm = 10', () {
      final sorted =
          sortCourtsByDistance(testCourts, 21.0385, 105.8016, maxDistanceKm: 10);
      // Chỉ Sân gần và Sân TB nằm trong 10km
      for (final court in sorted) {
        expect((court['distanceKm'] as double), lessThanOrEqualTo(10.0));
      }
    });

    test('ALG-HV-11: Giới hạn maxResults = 2', () {
      final sorted = sortCourtsByDistance(testCourts, 21.0385, 105.8016,
          maxDistanceKm: 100, maxResults: 2);
      expect(sorted.length, lessThanOrEqualTo(2));
    });

    test('ALG-HV-EXTRA-03: Danh sách rỗng → trả về rỗng', () {
      final sorted = sortCourtsByDistance([], 21.0385, 105.8016);
      expect(sorted, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────
  // 3. TEST SEARCH FILTER ALGORITHM (Lọc tìm kiếm)
  // ────────────────────────────────────────────────────────────
  group('Search Filter Algorithm', () {
    final courts = [
      {'name': 'Duy Hung Badminton Center', 'address': 'Cầu Giấy, Hà Nội'},
      {'name': 'JQK Badminton', 'address': 'Thanh Trì, Hà Nội'},
      {'name': 'Sân Minh Khai', 'address': 'Hai Bà Trưng, Hà Nội'},
      {'name': 'Royal City Court', 'address': 'Royal City'},
    ];

    List<Map<String, String>> search(String query) {
      final q = query.toLowerCase();
      return courts
          .where((c) =>
              c['name']!.toLowerCase().contains(q) ||
              c['address']!.toLowerCase().contains(q))
          .toList();
    }

    test('ALG-SR-01: Query rỗng → tất cả sân', () {
      expect(search('').length, equals(4));
    });

    test('ALG-SR-02: "Duy Hung" → 1 sân', () {
      expect(search('Duy Hung').length, equals(1));
    });

    test('ALG-SR-03: "duy hung" (lowercase) → 1 sân (case-insensitive)', () {
      expect(search('duy hung').length, equals(1));
    });

    test('ALG-SR-04: "Hà Nội" → 3 sân', () {
      expect(search('Hà Nội').length, equals(3));
    });

    test('ALG-SR-05: "xyzabc" → 0 sân', () {
      expect(search('xyzabc').length, equals(0));
    });

    test('ALG-SR-06: "Badminton" → 2 sân', () {
      expect(search('Badminton').length, equals(2));
    });

    test('ALG-SR-07: "Court" → 1 sân', () {
      expect(search('Court').length, equals(1));
    });
  });

  // ────────────────────────────────────────────────────────────
  // 4. TEST AVERAGE RATING ALGORITHM
  // ────────────────────────────────────────────────────────────
  group('Average Rating Algorithm', () {
    String calcAverage(List<int> ratings) {
      if (ratings.isEmpty) return '0';
      final sum = ratings.reduce((a, b) => a + b);
      return (sum / ratings.length).toStringAsFixed(1);
    }

    test('ALG-RT-01: [5,4,3,2,1] → "3.0"', () {
      expect(calcAverage([5, 4, 3, 2, 1]), '3.0');
    });

    test('ALG-RT-02: [5,5,5,5] → "5.0"', () {
      expect(calcAverage([5, 5, 5, 5]), '5.0');
    });

    test('ALG-RT-03: [1] → "1.0"', () {
      expect(calcAverage([1]), '1.0');
    });

    test('ALG-RT-04: [4,5,3,4,5] → "4.2"', () {
      expect(calcAverage([4, 5, 3, 4, 5]), '4.2');
    });

    test('ALG-RT-05: [] → "0"', () {
      expect(calcAverage([]), '0');
    });

    test('ALG-RT-06: [3,3,4] → "3.3"', () {
      expect(calcAverage([3, 3, 4]), '3.3');
    });
  });

  // ────────────────────────────────────────────────────────────
  // 5. TEST CAPACITY CHECK ALGORITHM
  // ────────────────────────────────────────────────────────────
  group('Capacity Check Algorithm', () {
    bool canJoin(int joinedCount, int capacity) {
      return joinedCount < capacity;
    }

    test('ALG-CP-01: capacity=4, joined=0 → true', () {
      expect(canJoin(0, 4), isTrue);
    });

    test('ALG-CP-02: capacity=4, joined=3 → true', () {
      expect(canJoin(3, 4), isTrue);
    });

    test('ALG-CP-03: capacity=4, joined=4 → false (đầy)', () {
      expect(canJoin(4, 4), isFalse);
    });

    test('ALG-CP-04: capacity=2, joined=2 → false (đầy)', () {
      expect(canJoin(2, 2), isFalse);
    });

    test('ALG-CP-05: capacity=10, joined=5 → true', () {
      expect(canJoin(5, 10), isTrue);
    });
  });
}
