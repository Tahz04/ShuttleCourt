import 'package:flutter_test/flutter_test.dart';
import 'package:shuttlecourt/models/badminton_court.dart';

/// ============================================================
/// UNIT TEST: BadmintonCourt Model
/// File gốc: lib/models/badminton_court.dart
/// Tương ứng: tests_shuttlecourt/03_Algorithm_Test.md (mục 1)
///
/// Test:
///   - fromJson parsing
///   - distanceTo (Haversine)
///   - Default values
///   - Edge cases
/// ============================================================
void main() {
  // ────────────────────────────────────────────────────────────
  // 1. TEST fromJson PARSING
  // ────────────────────────────────────────────────────────────
  group('BadmintonCourt.fromJson', () {
    test('Parse đầy đủ fields → tạo object đúng', () {
      final json = {
        'id': 1,
        'name': 'Duy Hung Badminton Center',
        'latitude': '21.0385',
        'longitude': '105.8016',
        'average_rating': '4.7',
        'total_reviews': '23',
        'address': '118 Nguyễn Khánh Toàn, Cầu Giấy',
        'phone': '0972914307',
        'price_per_hour': '80000',
        'amenities': 'Wifi,Gửi xe',
        'status': 'active',
      };

      final court = BadmintonCourt.fromJson(json);
      expect(court.id, '1');
      expect(court.name, 'Duy Hung Badminton Center');
      expect(court.latitude, 21.0385);
      expect(court.longitude, 105.8016);
      expect(court.rating, 4.7);
      expect(court.reviews, 23);
      expect(court.address, '118 Nguyễn Khánh Toàn, Cầu Giấy');
      expect(court.phone, '0972914307');
      expect(court.pricePerHour, 80000);
      expect(court.status, 'active');
    });

    test('Parse với fields bị thiếu → dùng default values', () {
      final json = <String, dynamic>{};
      final court = BadmintonCourt.fromJson(json);
      expect(court.id, '');
      expect(court.name, 'Sân Cầu Lông');
      expect(court.latitude, 0.0);
      expect(court.longitude, 0.0);
      expect(court.rating, 0.0); // tryParse('0') returns 0.0
      expect(court.reviews, 0);
      expect(court.address, '');
      expect(court.phone, '');
      expect(court.pricePerHour, 0.0);
      expect(court.status, 'active');
    });

    test('Parse amenities dạng String → split thành List', () {
      final json = {
        'amenities': 'Wifi,Gửi xe,Đèn LED',
      };
      final court = BadmintonCourt.fromJson(json);
      expect(court.amenities.length, 3);
      expect(court.amenities[0], 'Wifi');
    });

    test('Parse amenities dạng List → giữ nguyên', () {
      final json = {
        'amenities': ['Wifi', 'Gửi xe'],
      };
      final court = BadmintonCourt.fromJson(json);
      expect(court.amenities.length, 2);
    });

    test('Parse amenities null → default ["Wifi", "Gửi xe"]', () {
      final json = <String, dynamic>{};
      final court = BadmintonCourt.fromJson(json);
      expect(court.amenities, contains('Wifi'));
      expect(court.amenities, contains('Gửi xe'));
    });

    test('Parse latitude/longitude dạng number → chuyển đổi đúng', () {
      final json = {
        'latitude': 21.0385,
        'longitude': 105.8016,
      };
      final court = BadmintonCourt.fromJson(json);
      expect(court.latitude, 21.0385);
      expect(court.longitude, 105.8016);
    });

    test('Parse status = maintenance → đúng', () {
      final json = {
        'status': 'maintenance',
      };
      final court = BadmintonCourt.fromJson(json);
      expect(court.status, 'maintenance');
    });
  });

  // ────────────────────────────────────────────────────────────
  // 2. TEST distanceTo (Haversine)
  // ────────────────────────────────────────────────────────────
  group('BadmintonCourt.distanceTo', () {
    test('Cùng vị trí → distance = 0', () {
      final court = BadmintonCourt(
        id: '1', name: 'Test', latitude: 21.0385, longitude: 105.8016,
        rating: 4.5, reviews: 0, address: '', phone: '',
        pricePerHour: 0, amenities: [],
      );
      expect(court.distanceTo(21.0385, 105.8016), equals(0.0));
    });

    test('Khoảng cách ngắn (~3.6km) - Sân Minh Khai', () {
      final court = BadmintonCourt(
        id: '3', name: 'Minh Khai', latitude: 21.0007, longitude: 105.8702,
        rating: 4.1, reviews: 144, address: '521 Minh Khai', phone: '',
        pricePerHour: 90000, amenities: [],
      );
      final d = court.distanceTo(21.0285, 105.8527);
      expect(d, greaterThan(3.0));
      expect(d, lessThan(4.5));
    });

    test('Khoảng cách xa (~25km) - Sóc Sơn', () {
      final court = BadmintonCourt(
        id: '39', name: 'Sóc Sơn', latitude: 21.2600, longitude: 105.8500,
        rating: 4.0, reviews: 12, address: 'Sóc Sơn', phone: '',
        pricePerHour: 65000, amenities: [],
      );
      final d = court.distanceTo(21.0280, 105.8527);
      expect(d, greaterThan(24.0));
      expect(d, lessThan(27.0));
    });

    test('Khoảng cách tính là số dương', () {
      final court = BadmintonCourt(
        id: '1', name: 'Test', latitude: 21.0385, longitude: 105.8016,
        rating: 4.5, reviews: 0, address: '', phone: '',
        pricePerHour: 0, amenities: [],
      );
      final d = court.distanceTo(20.9729, 105.8042);
      expect(d, greaterThan(0));
    });
  });

  // ────────────────────────────────────────────────────────────
  // 3. TEST SAMPLE DATA
  // ────────────────────────────────────────────────────────────
  group('sampleBadmintonCourts', () {
    test('Có 40 sân mẫu', () {
      expect(sampleBadmintonCourts.length, equals(40));
    });

    test('Tất cả sân có tên không rỗng', () {
      for (final court in sampleBadmintonCourts) {
        expect(court.name.isNotEmpty, isTrue,
            reason: 'Court ${court.id} has empty name');
      }
    });

    test('Tất cả sân có tọa độ hợp lệ', () {
      for (final court in sampleBadmintonCourts) {
        expect(court.latitude, greaterThan(0),
            reason: 'Court ${court.name} has invalid latitude');
        expect(court.longitude, greaterThan(0),
            reason: 'Court ${court.name} has invalid longitude');
      }
    });

    test('Tất cả sân có giá > 0', () {
      for (final court in sampleBadmintonCourts) {
        expect(court.pricePerHour, greaterThan(0),
            reason: 'Court ${court.name} has price <= 0');
      }
    });

    test('Tất cả ID là duy nhất', () {
      final ids = sampleBadmintonCourts.map((c) => c.id).toSet();
      expect(ids.length, equals(sampleBadmintonCourts.length));
    });

    test('Rating nằm trong khoảng 1.0 - 5.0', () {
      for (final court in sampleBadmintonCourts) {
        expect(court.rating, greaterThanOrEqualTo(1.0));
        expect(court.rating, lessThanOrEqualTo(5.0));
      }
    });
  });
}
