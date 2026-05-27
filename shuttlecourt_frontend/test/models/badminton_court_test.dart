import 'package:flutter_test/flutter_test.dart';
import 'package:shuttlecourt/models/badminton_court.dart';

void main() {
  group('BadmintonCourt.distanceTo (Haversine)', () {
    late BadmintonCourt court;

    setUp(() {
      court = BadmintonCourt(
        id: 'test_1', name: 'Test Court',
        latitude: 21.0385, longitude: 105.8016,
        rating: 4.5, reviews: 10, address: 'Test',
        phone: '0123456789', pricePerHour: 80000, amenities: ['Wifi'],
      );
    });

    test('Cùng vị trí → khoảng cách = 0', () {
      expect(court.distanceTo(21.0385, 105.8016), closeTo(0.0, 0.001));
    });

    test('Khoảng cách ngắn (Minh Khai) trong 2-10km', () {
      final d = court.distanceTo(21.0007, 105.8702);
      expect(d, greaterThan(2.0));
      expect(d, lessThan(10.0));
    });

    test('Khoảng cách xa (Sóc Sơn) trong 20-30km', () {
      final d = court.distanceTo(21.2600, 105.8500);
      expect(d, greaterThan(20.0));
      expect(d, lessThan(30.0));
    });

    test('Khoảng cách đối xứng A→B == B→A', () {
      final courtB = BadmintonCourt(
        id: 'b', name: 'B', latitude: 21.0007, longitude: 105.8702,
        rating: 4.0, reviews: 5, address: '', phone: '',
        pricePerHour: 70000, amenities: [],
      );
      final dAB = court.distanceTo(courtB.latitude, courtB.longitude);
      final dBA = courtB.distanceTo(court.latitude, court.longitude);
      expect(dAB, closeTo(dBA, 0.001));
    });

    test('Khoảng cách luôn dương', () {
      expect(court.distanceTo(20.0, 106.0), greaterThan(0));
    });
  });

  group('BadmintonCourt.fromJson', () {
    test('Parse JSON đầy đủ', () {
      final court = BadmintonCourt.fromJson({
        'id': 1, 'name': 'Sân Test',
        'latitude': '21.0385', 'longitude': '105.8016',
        'average_rating': '4.7', 'total_reviews': '23',
        'address': '118 NKT', 'phone': '0972914307',
        'price_per_hour': '80000', 'amenities': 'Wifi,Gửi xe',
        'status': 'active',
      });
      expect(court.id, '1');
      expect(court.name, 'Sân Test');
      expect(court.latitude, 21.0385);
      expect(court.rating, 4.7);
      expect(court.amenities, ['Wifi', 'Gửi xe']);
      expect(court.status, 'active');
    });

    test('Parse JSON thiếu fields → default', () {
      final court = BadmintonCourt.fromJson(<String, dynamic>{});
      expect(court.name, 'Sân Cầu Lông');
      expect(court.latitude, 0.0);
      expect(court.status, 'active');
    });
  });

  group('sampleBadmintonCourts', () {
    test('Có ít nhất 20 sân mẫu', () {
      expect(sampleBadmintonCourts.length, greaterThanOrEqualTo(20));
    });

    test('Tất cả sân có tọa độ Hà Nội hợp lệ', () {
      for (final c in sampleBadmintonCourts) {
        expect(c.latitude, greaterThan(20.0));
        expect(c.latitude, lessThan(22.0));
        expect(c.longitude, greaterThan(105.0));
        expect(c.longitude, lessThan(107.0));
      }
    });

    test('Tất cả sân có ID unique', () {
      final ids = sampleBadmintonCourts.map((c) => c.id).toSet();
      expect(ids.length, sampleBadmintonCourts.length);
    });

    test('Rating trong khoảng 1-5', () {
      for (final c in sampleBadmintonCourts) {
        expect(c.rating, greaterThanOrEqualTo(1.0));
        expect(c.rating, lessThanOrEqualTo(5.0));
      }
    });
  });
}
