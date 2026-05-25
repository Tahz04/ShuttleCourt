import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/models/booking.dart';
import 'package:shuttlecourt/models/match_model.dart';
import 'package:shuttlecourt/services/api_booking_service.dart';
import 'package:shuttlecourt/features/matchmaking/services/matchmaking_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:shuttlecourt/services/notification_service.dart';
import 'package:shuttlecourt/features/reviews/screens/write_review_screen.dart';

// RE-WRITTEN BOOKING HISTORY SCREEN
class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _loadData() {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.user == null) {
      _dataFuture = Future.value({'bookings': [], 'matches': []});
      return;
    }
    int userId = int.parse(auth.user!.id);
    _dataFuture = Future.wait([
      ApiBookingService.getBookings(userId),
      MatchmakingService.getUserMatches(userId),
    ]).then((results) => {
      'bookings': List<Booking>.from(results[0]),
      'matches': List<MatchModel>.from(results[1]),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(),
          SliverFillRemaining(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2));
                }
                
                final bookings = (snapshot.data?['bookings'] as List?)?.map((e) => e as Booking).toList() ?? [];
                final matches = (snapshot.data?['matches'] as List?)?.map((e) => e as MatchModel).toList() ?? [];
                
                if (bookings.isEmpty && matches.isEmpty) {
                  return _buildEmptyState();
                }

                final List<dynamic> combinedList = [...bookings, ...matches];
                combinedList.sort((a, b) {
                  DateTime dateA = a is Booking ? a.createdAt : (a as MatchModel).matchDate;
                  DateTime dateB = b is Booking ? b.createdAt : (b as MatchModel).matchDate;
                  return dateB.compareTo(dateA);
                });

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: combinedList.length,
                  itemBuilder: (context, index) {
                    final item = combinedList[index];
                    return item is Booking ? _buildBookingCard(item) : _buildMatchCard(item as MatchModel);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lịch chơi của tôi', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1)),
            const SizedBox(height: 4),
            Text('Theo dõi lịch đặt sân và các trận đấu của bạn', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking b) {
    bool isConfirmed = b.status == 'Đã duyệt' || b.status == 'Đã thanh toán';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isConfirmed ? AppTheme.primary.withOpacity(0.1) : AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.sports_tennis_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.courtName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                    Text(b.courtAddress, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), maxLines: 1),
                  ],
                ),
              ),
              _StatusBadge(b.status),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppTheme.borderLight)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _detail(Icons.calendar_today_outlined, DateFormat('dd MMM').format(b.date)),
              _detail(Icons.access_time_rounded, b.slot),
              Text('${b.price.toInt()}đ', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 15)),
            ],
          ),
          if (isConfirmed) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => WriteReviewScreen(
                        courtName: b.courtName,
                        bookingId: int.tryParse(b.id),
                      )
                    )
                  );
                },
                icon: const Icon(Icons.star_rate_rounded, size: 16),
                label: const Text('ĐÁNH GIÁ SÂN NÀY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentGold,
                  side: const BorderSide(color: AppTheme.accentGold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchCard(MatchModel m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.people_alt_rounded, color: AppTheme.accent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.courtName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                    Text('Chủ kèo: ${m.hostName}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppTheme.borderLight)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _detail(Icons.calendar_today_outlined, DateFormat('dd MMM').format(m.matchDate)),
              _detail(Icons.bolt_rounded, m.level),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${m.joinedCount}/${m.capacity} Slot', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Chưa có lịch chơi', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color = AppTheme.primary;
    if (status == 'Đã hủy') color = AppTheme.error;
    if (status == 'Chờ duyệt') color = Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}
