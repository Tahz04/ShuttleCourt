import 'package:flutter_test/flutter_test.dart';
import 'package:shuttlecourt/models/review.dart';

void main() {
  group('Review.fromJson', () {
    test('Parse JSON đầy đủ', () {
      final review = Review.fromJson({
        'id': 1, 'court_id': 5, 'user_id': 10,
        'booking_id': 20, 'rating': 5,
        'comment': 'Sân rất đẹp!',
        'photos': '["img1.jpg","img2.jpg"]',
        'created_at': '2026-05-26T12:00:00',
        'user_name': 'Nguyễn Văn A',
        'court_name': 'Duy Hung Badminton',
        'owner_reply': 'Cảm ơn bạn!',
        'owner_reply_at': '2026-05-26T13:00:00',
      });

      expect(review.id, 1);
      expect(review.courtId, 5);
      expect(review.userId, 10);
      expect(review.bookingId, 20);
      expect(review.rating, 5);
      expect(review.comment, 'Sân rất đẹp!');
      expect(review.photos.length, 2);
      expect(review.photos[0], 'img1.jpg');
      expect(review.userName, 'Nguyễn Văn A');
      expect(review.ownerReply, 'Cảm ơn bạn!');
      expect(review.ownerReplyAt, isNotNull);
    });

    test('Parse photos dạng List', () {
      final review = Review.fromJson({
        'id': 2, 'court_id': 1, 'user_id': 1, 'rating': 4,
        'photos': ['a.jpg', 'b.jpg', 'c.jpg'],
        'created_at': '2026-05-26T12:00:00',
      });
      expect(review.photos.length, 3);
    });

    test('Parse photos null → list rỗng', () {
      final review = Review.fromJson({
        'id': 3, 'court_id': 1, 'user_id': 1, 'rating': 3,
        'photos': null,
        'created_at': '2026-05-26T12:00:00',
      });
      expect(review.photos, isEmpty);
    });

    test('Parse photos single string', () {
      final review = Review.fromJson({
        'id': 4, 'court_id': 1, 'user_id': 1, 'rating': 4,
        'photos': 'single_image.jpg',
        'created_at': '2026-05-26T12:00:00',
      });
      expect(review.photos.length, 1);
      expect(review.photos[0], 'single_image.jpg');
    });

    test('owner_reply null → không có phản hồi', () {
      final review = Review.fromJson({
        'id': 5, 'court_id': 1, 'user_id': 1, 'rating': 2,
        'created_at': '2026-05-26T12:00:00',
        'owner_reply': null, 'owner_reply_at': null,
      });
      expect(review.ownerReply, isNull);
      expect(review.ownerReplyAt, isNull);
    });
  });
}
