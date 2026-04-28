import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/models/booking.dart';
import 'package:shuttlecourt/models/match_model.dart';
import 'package:shuttlecourt/services/api_booking_service.dart';
import 'package:shuttlecourt/features/matchmaking/services/matchmaking_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_footer.dart';

/// Web-optimized booking history page with bookings and matches combined
class WebBookingHistoryPage extends StatefulWidget {
  final Function(int)? onTabChange;

  const WebBookingHistoryPage({super.key, this.onTabChange});

  @override
  State<WebBookingHistoryPage> createState() => _WebBookingHistoryPageState();
}

class _WebBookingHistoryPageState extends State<WebBookingHistoryPage> {
  late Future<Map<String, dynamic>> _dataFuture;
  String _filterType = 'Tất cả'; // 'Tất cả', 'Đặt sân', 'Ghép sân'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.user == null) {
      _dataFuture = Future.value({'bookings': [], 'matches': []});
      return;
    }
    int userId = int.parse(auth.user!.id);
    _dataFuture =
        Future.wait([
          ApiBookingService.getBookings(userId),
          MatchmakingService.getUserMatches(userId),
        ]).then(
          (results) => {
            'bookings': List<Booking>.from(results[0]),
            'matches': List<MatchModel>.from(results[1]),
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldLight,
        body: Column(
          children: [
            WebNavbar(
              selectedIndex: 2,
              onNavTap: (i) => widget.onTabChange?.call(i),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            size: 60,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Đăng nhập để xem lịch sử',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Xem các lần đặt sân và các trận ghép sân của bạn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: Column(
        children: [
          WebNavbar(
            selectedIndex: 2,
            onNavTap: (i) => widget.onTabChange?.call(i),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildFilterSection(),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _dataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(40),
                          child: const CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        );
                      }

                      final bookings =
                          (snapshot.data?['bookings'] as List?)
                              ?.cast<Booking>() ??
                          [];
                      final matches =
                          (snapshot.data?['matches'] as List?)
                              ?.cast<MatchModel>() ??
                          [];

                      // Filter by type
                      List<dynamic> filteredItems = [];
                      if (_filterType == 'Tất cả' || _filterType == 'Đặt sân') {
                        filteredItems.addAll(bookings);
                      }
                      if (_filterType == 'Tất cả' ||
                          _filterType == 'Ghép sân') {
                        filteredItems.addAll(matches);
                      }

                      // Sort by date descending
                      filteredItems.sort((a, b) {
                        DateTime dateA = a is Booking
                            ? a.createdAt
                            : (a as MatchModel).matchDate;
                        DateTime dateB = b is Booking
                            ? b.createdAt
                            : (b as MatchModel).matchDate;
                        return dateB.compareTo(dateA);
                      });

                      if (filteredItems.isEmpty) {
                        return _buildEmptyState();
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 24,
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _getCrossAxisCount(
                                  MediaQuery.of(context).size.width,
                                ),
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 1.2,
                              ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            if (item is Booking) {
                              return _buildBookingCard(item);
                            } else {
                              return _buildMatchCard(item as MatchModel);
                            }
                          },
                        ),
                      );
                    },
                  ),
                  WebFooter(onNavTap: (i) => widget.onTabChange?.call(i)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(double width) {
    if (width > 1400) return 4;
    if (width > 1000) return 3;
    if (width > 700) return 2;
    return 1;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch chơi của tôi',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Theo dõi lịch đặt sân và các trận ghép sân của bạn',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loại',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildFilterChip(
                  'Tất cả',
                  () => setState(() => _filterType = 'Tất cả'),
                  _filterType == 'Tất cả',
                ),
                const SizedBox(width: 12),
                _buildFilterChip(
                  'Đặt sân',
                  () => setState(() => _filterType = 'Đặt sân'),
                  _filterType == 'Đặt sân',
                ),
                const SizedBox(width: 12),
                _buildFilterChip(
                  'Ghép sân',
                  () => setState(() => _filterType = 'Ghép sân'),
                  _filterType == 'Ghép sân',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap, bool isActive) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : AppTheme.scaffoldLight,
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.borderLight,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final isConfirmed =
        booking.status == 'Đã duyệt' || booking.status == 'Đã thanh toán';
    final statusColor = isConfirmed ? AppTheme.primary : AppTheme.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConfirmed
              ? AppTheme.primary.withOpacity(0.1)
              : AppTheme.borderLight,
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sports_tennis_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.courtName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.courtAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.borderLight),
            const SizedBox(height: 16),
            // Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.calendar_today_rounded,
                    DateFormat('dd MMM yyyy').format(booking.date),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.access_time_rounded,
                    booking.slot,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${booking.price.toStringAsFixed(0)}đ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: AppTheme.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ghép sân',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        match.courtName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.level,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.borderLight),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.calendar_today_rounded,
                    DateFormat('dd MMM yyyy').format(match.matchDate),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.access_time_rounded,
                    match.startTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  '${match.joinedCount}/${match.capacity}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.event_note_rounded,
            size: 80,
            color: AppTheme.primary.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có lịch chơi nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy bắt đầu đặt sân hoặc ghép sân để xem lịch chơi của bạn',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => widget.onTabChange?.call(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Tìm Sân Ngay',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
