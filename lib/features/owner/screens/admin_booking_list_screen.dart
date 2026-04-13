import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quynh/config/api_config.dart';
import 'package:quynh/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AdminBookingListScreen extends StatefulWidget {
  const AdminBookingListScreen({super.key});

  @override
  State<AdminBookingListScreen> createState() => _AdminBookingListScreenState();
}

class _AdminBookingListScreenState extends State<AdminBookingListScreen> {
  late Future<List<dynamic>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _fetchBookings();
  }

  Future<List<dynamic>> _fetchBookings() async {
    final response = await http.get(Uri.parse('${ApiConfig.bookingsUrl}/all'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Quản lý lịch đặt', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(child: Text('Chưa có lịch đặt nào.', style: TextStyle(color: AppTheme.textMuted)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final date = DateTime.parse(booking['booking_date']);
              final formattedDate = DateFormat('dd/MM/yyyy').format(date);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(booking['court_name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text('${booking['price']}đ', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text('Khách: ${booking['user_name']}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text('$formattedDate - ${booking['slot']}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: const Text('Đã xác nhận', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
