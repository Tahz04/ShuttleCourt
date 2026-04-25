import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shuttlecourt/models/booking.dart';

class BookingService {
  static const String _bookingsKey = 'bookings';

  static Future<List<Booking>> getBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getStringList(_bookingsKey) ?? [];
    return bookingsJson.map((json) => Booking.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> addBooking(Booking booking) async {
    final prefs = await SharedPreferences.getInstance();
    final bookings = await getBookings();
    bookings.add(booking);
    final bookingsJson = bookings.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList(_bookingsKey, bookingsJson);
  }

  static Future<void> removeBooking(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final bookings = await getBookings();
    bookings.removeWhere((b) => b.id == id);
    final bookingsJson = bookings.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList(_bookingsKey, bookingsJson);
  }
}

