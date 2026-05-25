import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shuttlecourt/models/booking.dart';
import 'package:shuttlecourt/config/api_config.dart';

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
  static Future<List<Booking>> getBookings(int userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/user/$userId'));
      if (res.statusCode == 200) {
        List body = jsonDecode(res.body);
        return body.map((json) => Booking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ================= OWNER: GET ALL BOOKINGS =================
  static Future<List<Booking>> getAllBookings() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/all'));
      if (res.statusCode == 200) {
        List body = jsonDecode(res.body);
        return body.map((json) => Booking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ================= OWNER: UPDATE STATUS =================
  static Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/$bookingId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error update status: $e');
      return false;
    }
  }
}