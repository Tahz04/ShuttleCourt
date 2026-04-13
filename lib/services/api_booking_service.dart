import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quynh/models/booking.dart';
import 'package:quynh/config/api_config.dart';

class ApiBookingService {

  static String get baseUrl => ApiConfig.bookingsUrl;

  // ================= CREATE BOOKING =================
  static Future<void> createBooking(int userId, Booking booking) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "court_name": booking.courtName,
          "court_address": booking.courtAddress,
          "slot": booking.slot,
          "booking_date": booking.date.toIso8601String().split('T')[0],
          "price": booking.price,
          "payment_method": booking.paymentMethod
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Create booking failed: ${response.body}');
      }

    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ================= GET BOOKINGS =================
  static Future<List> getBookings(int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Fetch bookings failed: ${res.body}');
      }

    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}