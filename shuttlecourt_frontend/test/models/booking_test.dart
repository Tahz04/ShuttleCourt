import 'package:flutter_test/flutter_test.dart';
import 'package:shuttlecourt/models/booking.dart';

void main() {
  group('Booking.fromJson', () {
    test('Parse JSON đầy đủ fields', () {
      final booking = Booking.fromJson({
        'id': 1,
        'court_name': 'Duy Hung Badminton',
        'court_address': '118 NKT, Cầu Giấy',
        'slot': '18:00 - 19:00',
        'booking_date': '2026-05-28',
        'price': 80000,
        'payment_method': 'Tiền mặt',
        'created_at': '2026-05-26T12:00:00',
        'status': 'Chờ duyệt',
        'user_name': 'Nguyễn Văn A',
      });

      expect(booking.id, '1');
      expect(booking.courtName, 'Duy Hung Badminton');
      expect(booking.courtAddress, '118 NKT, Cầu Giấy');
      expect(booking.slot, '18:00 - 19:00');
      expect(booking.price, 80000.0);
      expect(booking.paymentMethod, 'Tiền mặt');
      expect(booking.status, 'Chờ duyệt');
      expect(booking.userName, 'Nguyễn Văn A');
    });

    test('Parse JSON với key camelCase', () {
      final booking = Booking.fromJson({
        'id': 2,
        'courtName': 'JQK Badminton',
        'courtAddress': 'Thanh Trì',
        'slot': '20:00 - 21:00',
        'date': '2026-06-01',
        'price': '100000',
        'paymentMethod': 'Chuyển khoản',
        'createdAt': '2026-05-26T15:00:00',
      });

      expect(booking.id, '2');
      expect(booking.courtName, 'JQK Badminton');
      expect(booking.price, 100000.0);
      expect(booking.status, 'Chờ duyệt'); // default
    });

    test('Price dạng String → parse thành double', () {
      final booking = Booking.fromJson({
        'id': 3, 'court_name': 'Test', 'court_address': 'Test',
        'slot': '05:00 - 06:00', 'booking_date': '2026-05-28',
        'price': '150000', 'payment_method': 'MoMo',
        'created_at': '2026-05-26T12:00:00',
      });
      expect(booking.price, 150000.0);
    });

    test('Status mặc định là "Chờ duyệt"', () {
      final booking = Booking.fromJson({
        'id': 4, 'court_name': 'Test', 'court_address': 'Test',
        'slot': '05:00', 'booking_date': '2026-05-28',
        'price': 50000, 'payment_method': 'Cash',
        'created_at': '2026-05-26T12:00:00',
      });
      expect(booking.status, 'Chờ duyệt');
    });
  });

  group('Booking.toJson', () {
    test('Xuất JSON đúng format', () {
      final booking = Booking(
        id: '10', courtName: 'Test Court', courtAddress: 'Test Address',
        slot: '18:00 - 19:00', date: DateTime(2026, 5, 28),
        price: 80000, paymentMethod: 'Tiền mặt',
        createdAt: DateTime(2026, 5, 26),
      );

      final json = booking.toJson();
      expect(json['id'], '10');
      expect(json['court_name'], 'Test Court');
      expect(json['court_address'], 'Test Address');
      expect(json['slot'], '18:00 - 19:00');
      expect(json['price'], 80000);
      expect(json['payment_method'], 'Tiền mặt');
      expect(json['status'], 'Chờ duyệt');
      expect(json['booking_date'], contains('2026-05-28'));
    });
  });
}
