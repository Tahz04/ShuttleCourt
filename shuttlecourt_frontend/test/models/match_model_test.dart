import 'package:flutter_test/flutter_test.dart';
import 'package:shuttlecourt/models/match_model.dart';

void main() {
  group('MatchModel.fromJson', () {
    test('Parse JSON đầy đủ', () {
      final match = MatchModel.fromJson({
        'id': 1, 'host_id': 10,
        'host_name': 'Nguyễn Văn A',
        'court_name': 'Duy Hung Badminton',
        'level': 'Trung bình',
        'match_date': '2026-06-01',
        'start_time': '18:00',
        'capacity': 4, 'joined_count': 2,
        'price': '50000',
        'description': 'Tìm bạn chơi đôi',
      });

      expect(match.id, 1);
      expect(match.hostId, 10);
      expect(match.hostName, 'Nguyễn Văn A');
      expect(match.courtName, 'Duy Hung Badminton');
      expect(match.level, 'Trung bình');
      expect(match.capacity, 4);
      expect(match.joinedCount, 2);
      expect(match.price, 50000.0);
      expect(match.description, 'Tìm bạn chơi đôi');
    });

    test('host_name null → default "Ẩn danh"', () {
      final match = MatchModel.fromJson({
        'id': 2, 'host_id': 5, 'host_name': null,
        'court_name': 'Test', 'level': 'Yếu',
        'match_date': '2026-06-02', 'start_time': '19:00',
        'capacity': 2, 'price': '30000',
      });
      expect(match.hostName, 'Ẩn danh');
    });

    test('joined_count null → default 1', () {
      final match = MatchModel.fromJson({
        'id': 3, 'host_id': 5, 'host_name': 'Test',
        'court_name': 'Test', 'level': 'Khá',
        'match_date': '2026-06-02', 'start_time': '20:00',
        'capacity': 4, 'joined_count': null, 'price': '40000',
      });
      expect(match.joinedCount, 1);
    });

    test('description null → default rỗng', () {
      final match = MatchModel.fromJson({
        'id': 4, 'host_id': 5, 'host_name': 'Test',
        'court_name': 'Test', 'level': 'Mạnh',
        'match_date': '2026-06-03', 'start_time': '21:00',
        'capacity': 2, 'price': '60000', 'description': null,
      });
      expect(match.description, '');
    });

    test('price dạng int → parse thành double', () {
      final match = MatchModel.fromJson({
        'id': 5, 'host_id': 5, 'host_name': 'Test',
        'court_name': 'Test', 'level': 'Trung bình',
        'match_date': '2026-06-03', 'start_time': '17:00',
        'capacity': 4, 'price': 75000,
      });
      expect(match.price, 75000.0);
    });
  });

  group('MatchModel - Capacity Logic', () {
    test('Kiểm tra kèo chưa đầy', () {
      final match = MatchModel(
        id: 1, hostId: 10, hostName: 'Host',
        courtName: 'Test', level: 'TB',
        matchDate: DateTime(2026, 6, 1), startTime: '18:00',
        capacity: 4, joinedCount: 2, price: 50000,
      );
      expect(match.joinedCount < match.capacity, isTrue);
    });

    test('Kiểm tra kèo đã đầy', () {
      final match = MatchModel(
        id: 2, hostId: 10, hostName: 'Host',
        courtName: 'Test', level: 'TB',
        matchDate: DateTime(2026, 6, 1), startTime: '18:00',
        capacity: 4, joinedCount: 4, price: 50000,
      );
      expect(match.joinedCount >= match.capacity, isTrue);
    });
  });
}
