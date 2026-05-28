import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shuttlecourt/models/booking.dart';
import 'package:shuttlecourt/config/api_config.dart';

class ApiBookingService {

  static String get baseUrl => ApiConfig.bookingsUrl;

  // ================= CREATE BOOKING =================
  static Future<void> createBooking(int userId, Booking booking) async {
    http.Response response;
    try {
      response = await http.post(
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
    } catch (e) {
      throw Exception('Lỗi kết nối mạng: $e');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      String errorMessage = 'Lỗi không xác định';
      try {
        final body = jsonDecode(response.body);
        errorMessage = body['message'] ?? body['error'] ?? response.body;
      } catch (e) {
        errorMessage = response.body;
      }
      throw Exception(errorMessage);
    }
  }

  // ================= GET BOOKED SLOTS =================
  static Future<List<String>> getBookedSlots(String courtName, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final res = await http.get(Uri.parse('$baseUrl/booked-slots?court_name=${Uri.encodeComponent(courtName)}&booking_date=$dateStr'));
      if (res.statusCode == 200) {
        List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error getting booked slots: $e');
      return [];
    }
  }

  static Future<bool> cancelBooking(String bookingId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$bookingId/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error canceling booking: $e');
      return false;
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

  // ================= OWNER: GET BOOKINGS FOR OWNED COURTS =================
  static Future<List<Booking>> getOwnerBookings(int ownerId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/owner/$ownerId'));
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
