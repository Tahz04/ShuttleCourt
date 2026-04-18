import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quynh/config/api_config.dart';
import 'package:quynh/models/review.dart';

class ReviewService {
  static Future<bool> createReview({
    required int courtId,
    required int userId,
    int? bookingId,
    required int rating,
    String? comment,
    List<String>? photos,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'court_id': courtId,
          'user_id': userId,
          'booking_id': bookingId,
          'rating': rating,
          'comment': comment,
          'photos': photos,
        }),
      );

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('=== ReviewService: Error creating review ===');
      print(e);
      return false;
    }
  }

  static Future<Map<String, dynamic>> getCourtReviews(int courtId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/reviews/court/$courtId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> rawReviews = data['reviews'];
          final reviews = rawReviews.map((json) => Review.fromJson(json)).toList();
          return {
            'reviews': reviews,
            'averageRating': data['averageRating'],
            'total': data['total'],
          };
        }
      }
      return {'reviews': <Review>[], 'averageRating': 0, 'total': 0};
    } catch (e) {
      print('=== ReviewService: Error getting court reviews ===');
      print(e);
      return {'reviews': <Review>[], 'averageRating': 0, 'total': 0};
    }
  }

  static Future<List<Review>> getUserReviews(int userId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/reviews/user/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> rawReviews = data['reviews'];
          return rawReviews.map((json) => Review.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('=== ReviewService: Error getting user reviews ===');
      print(e);
      return [];
    }
  }
}
