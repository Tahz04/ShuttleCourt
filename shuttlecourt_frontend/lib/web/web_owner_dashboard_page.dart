import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_styles.dart';
import 'dart:async';

// Import existing mobile screens to embed
import 'package:shuttlecourt/features/owner/screens/owner_courts_screen.dart';
import 'package:shuttlecourt/features/owner/screens/owner_booking_management_screen.dart';
import 'package:shuttlecourt/features/owner/screens/owner_review_management_screen.dart';
import 'package:shuttlecourt/features/shop/screens/owner_shop_management_screen.dart';
import 'package:shuttlecourt/features/shop/screens/owner_order_management_screen.dart';

// Services
import 'package:shuttlecourt/services/api_booking_service.dart';
import 'package:shuttlecourt/services/shop_service.dart';
import 'package:shuttlecourt/models/booking.dart';

class WebOwnerDashboardPage extends StatefulWidget {
  final int initialTab;
  const WebOwnerDashboardPage({super.key, this.initialTab = 0});

  @override
  State<WebOwnerDashboardPage> createState() => _WebOwnerDashboardPageState();
}

class _WebOwnerDashboardPageState extends State<WebOwnerDashboardPage> {
  late int _selectedIndex;
  bool _isLoading = true;
  double _dailyRevenue = 0;
  double _monthlyRevenue = 0;
  double _yearlyRevenue = 0;
  int _pendingCount = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Tổng quan', 'icon': Icons.dashboard_rounded, 'color': WebStyles.brand},
    {'title': 'Kho sân', 'icon': Icons.stadium_rounded, 'color': WebStyles.brand},
    {'title': 'Lịch đặt', 'icon': Icons.calendar_today_rounded, 'color': WebStyles.cta},
    {'title': 'Đánh giá', 'icon': Icons.star_rate_rounded, 'color': WebStyles.cta},
    {'title': 'Cửa hàng', 'icon': Icons.storefront_rounded, 'color': const Color(0xFF8B5CF6)},
    {'title': 'Đơn hàng', 'icon': Icons.local_shipping_rounded, 'color': const Color(0xFF8B5CF6)},
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _fetchStats();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _fetchStats());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.user == null) return;

    try {
      final results = await Future.wait([
        ApiBookingService.getOwnerBookings(int.parse(auth.user!.id)),
        ShopService.getOrders(ownerId: int.parse(auth.user!.id)),
      ]);

      final bookings = results[0] as List<Booking>;
      final shopOrders = results[1] as List<dynamic>;

      if (mounted) {
        setState(() {
          _pendingCount = bookings.where((b) => b.status == 'Chờ duyệt').length;

          final now = DateTime.now();

          // Daily Revenue Calc
          double bRevDaily = bookings
              .where((b) => (b.status == 'Đã duyệt' || b.status == 'Đã thanh toán' || b.status == 'Đã hoàn thành') &&
                  b.date.year == now.year && b.date.month == now.month && b.date.day == now.day)
              .fold(0.0, (sum, b) => sum + b.price);
          
          double sRevDaily = shopOrders
              .where((o) {
                if (o['status'] != 'Đã duyệt' && o['status'] != 'Đã giao' && o['status'] != 'completed') return false;
                if (o['created_at'] == null) return false;
                final od = DateTime.parse(o['created_at'].toString()).toLocal();
                return od.year == now.year && od.month == now.month && od.day == now.day;
              })
              .fold(0.0, (sum, o) => sum + (double.tryParse(o['total_price'].toString()) ?? 0.0));

          _dailyRevenue = bRevDaily + sRevDaily;

          // Monthly Revenue Calc
          double bRevMonthly = bookings
              .where((b) => (b.status == 'Đã duyệt' || b.status == 'Đã thanh toán' || b.status == 'Đã hoàn thành') &&
                  b.date.year == now.year && b.date.month == now.month)
              .fold(0.0, (sum, b) => sum + b.price);
          
          double sRevMonthly = shopOrders
              .where((o) {
                if (o['status'] != 'Đã duyệt' && o['status'] != 'Đã giao' && o['status'] != 'completed') return false;
                if (o['created_at'] == null) return false;
                final od = DateTime.parse(o['created_at'].toString()).toLocal();
                return od.year == now.year && od.month == now.month;
              })
              .fold(0.0, (sum, o) => sum + (double.tryParse(o['total_price'].toString()) ?? 0.0));

          _monthlyRevenue = bRevMonthly + sRevMonthly;

          // Yearly Revenue Calc
          double bRevYearly = bookings
              .where((b) => (b.status == 'Đã duyệt' || b.status == 'Đã thanh toán' || b.status == 'Đã hoàn thành') &&
                  b.date.year == now.year)
              .fold(0.0, (sum, b) => sum + b.price);
          
          double sRevYearly = shopOrders
              .where((o) {
                if (o['status'] != 'Đã duyệt' && o['status'] != 'Đã giao' && o['status'] != 'completed') return false;
                if (o['created_at'] == null) return false;
                final od = DateTime.parse(o['created_at'].toString()).toLocal();
                return od.year == now.year;
              })
              .fold(0.0, (sum, o) => sum + (double.tryParse(o['total_price'].toString()) ?? 0.0));

          _yearlyRevenue = bRevYearly + sRevYearly;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMenuTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1024;
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      backgroundColor: WebStyles.bg,
      body: Column(
        children: [
          WebNavbar(
            selectedIndex: -1,
            onNavTap: (index) {
              Navigator.pop(context); // Optional depending on nav structure
            },
          ),
          Expanded(
            child: isWide 
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSidebar(user?.fullName ?? 'Chủ sân'),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          decoration: WebStyles.card,
                          clipBehavior: Clip.antiAlias,
                          child: _buildContent(),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildMobileHeader(),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: WebStyles.surface,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            boxShadow: WebStyles.shadowMd,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildContent(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(String userName) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: WebStyles.surface,
        border: const Border(right: BorderSide(color: WebStyles.border)),
        boxShadow: WebStyles.shadowSm,
      ),
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: WebStyles.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: WebStyles.brandGrad,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đối tác',
                        style: TextStyle(color: WebStyles.inkFaint, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(color: WebStyles.ink, fontSize: 16, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedIndex == index;
                final color = item['color'] as Color;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Material(
                    color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _onMenuTap(index),
                      borderRadius: BorderRadius.circular(12),
                      hoverColor: WebStyles.dark50,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: isSelected ? color : WebStyles.inkLight,
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item['title'] as String,
                                style: TextStyle(
                                  color: isSelected ? color : WebStyles.inkMid,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: WebStyles.bg,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_menuItems.length, (index) {
                final item = _menuItems[index];
                final isSelected = _selectedIndex == index;
                final color = item['color'] as Color;

                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _onMenuTap(index),
                    icon: Icon(item['icon'] as IconData, size: 16, color: isSelected ? Colors.white : color),
                    label: Text(item['title'] as String),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? color : color.withValues(alpha: 0.1),
                      foregroundColor: isSelected ? Colors.white : color,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return _buildOverviewTab();
      case 1: return const OwnerCourtsScreen(isEmbedded: true);
      case 2: return const OwnerBookingManagementScreen(isEmbedded: true);
      case 3: return const OwnerReviewManagementScreen(isEmbedded: true);
      case 4: return const OwnerShopManagementScreen(isEmbedded: true);
      case 5: return const OwnerOrderManagementScreen(isEmbedded: true);
      default: return const Center(child: Text('Coming soon'));
    }
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: WebStyles.brand));
    }

    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const Text('Tổng quan hoạt động', style: WebStyles.sectionTitle),
          const SizedBox(height: 8),
          const Text('Thống kê nhanh hiệu suất kinh doanh của bạn.', style: WebStyles.sectionSub),
          const SizedBox(height: 32),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 768 ? 2 : 1),
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 2.2,
            children: [
              _buildStatCard(
                'DOANH THU HÔM NAY',
                '${_dailyRevenue.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} đ',
                Icons.today_rounded,
                WebStyles.brandGrad,
              ),
              _buildStatCard(
                'YÊU CẦU CHỜ DUYỆT',
                '$_pendingCount',
                Icons.event_available_rounded,
                WebStyles.ctaGrad,
              ),
              _buildStatCard(
                'DOANH THU THÁNG NÀY',
                '${_monthlyRevenue.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} đ',
                Icons.calendar_month_rounded,
                WebStyles.brandGrad,
              ),
              _buildStatCard(
                'DOANH THU NĂM NAY',
                '${_yearlyRevenue.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} đ',
                Icons.account_balance_wallet_rounded,
                WebStyles.brandGrad,
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Tips / Welcome section
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: WebStyles.dark50,
              borderRadius: BorderRadius.circular(WebStyles.rXl),
              border: Border.all(color: WebStyles.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: WebStyles.shadowSm),
                  child: const Icon(Icons.tips_and_updates_rounded, color: WebStyles.cta, size: 32),
                ),
                const SizedBox(width: 24),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mẹo cho Chủ Sân', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WebStyles.ink)),
                      SizedBox(height: 8),
                      Text('Thường xuyên kiểm tra lịch đặt sân và đơn hàng để đảm bảo khách hàng luôn nhận được dịch vụ tốt nhất. Trả lời đánh giá nhanh chóng giúp tăng uy tín của sân.', 
                           style: TextStyle(color: WebStyles.inkLight, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, LinearGradient gradient) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(WebStyles.rLg),
        boxShadow: WebStyles.shadowMd,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(icon, size: 120, color: Colors.white.withValues(alpha: 0.15)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
