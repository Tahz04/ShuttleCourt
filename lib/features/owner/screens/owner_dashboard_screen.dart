import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quynh/auth/auth_service.dart';
import 'package:quynh/features/owner/screens/add_court_screen.dart';
import 'package:quynh/features/owner/screens/owner_courts_screen.dart';
import 'package:quynh/features/shop/screens/owner_shop_management_screen.dart';
import 'package:quynh/features/shop/screens/owner_order_management_screen.dart';
import 'package:quynh/features/owner/screens/owner_booking_management_screen.dart';
import 'package:quynh/services/notification_service.dart';
import 'package:quynh/services/api_booking_service.dart';
import 'package:quynh/services/shop_service.dart';
import 'package:quynh/models/booking.dart';
import 'package:quynh/theme/app_theme.dart';
import 'dart:async';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<SystemNotification> _notifications = [];
  Timer? _timer;
  int _unreadCount = 0;
  double _monthlyRevenue = 0;
  int _pendingCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _fetchData());
  }

  Future<void> _fetchData() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.user == null) return;

    try {
      final results = await Future.wait([
        NotificationService.getNotifications(auth.user!.id.toString()),
        ApiBookingService.getAllBookings(),
        ShopService.getOrders(),
      ]);

      final newNotifs = results[0] as List<SystemNotification>;
      final bookings = results[1] as List<Booking>;
      final shopOrders = results[2] as List<dynamic>;

      if (mounted) {
        setState(() {
          _notifications = newNotifs;
          _unreadCount = newNotifs.where((n) => !n.isRead).length;
          _pendingCount = bookings.where((b) => b.status == 'Chờ duyệt').length;

          // Revenue Calc
          double bRev = bookings
              .where((b) => b.status == 'Đã duyệt' || b.status == 'Đã thanh toán')
              .fold(0.0, (sum, b) => sum + b.price);
          
          double sRev = shopOrders
              .where((o) => o['status'] == 'completed' || o['status'] == 'Đã giao')
              .fold(0.0, (sum, o) => sum + (double.tryParse(o['total_price'].toString()) ?? 0.0));

          _monthlyRevenue = bRev + sRev;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildHeader(user?.fullName),
              _buildStatsSection(),
              _buildMenuSection('QUẢN LÝ SÂN', [
                _MenuIcon(Icons.add_business_rounded, 'Thêm Sân', AppTheme.primary, () => _nav(const AddCourtScreen())),
                _MenuIcon(Icons.stadium_rounded, 'Kho Sân', AppTheme.primary, () => _nav(const OwnerCourtsScreen())),
                _MenuIcon(Icons.calendar_today_rounded, 'Lịch Đặt', AppTheme.highlight, () => _nav(const OwnerBookingManagementScreen())),
                _MenuIcon(Icons.analytics_rounded, 'Báo Cáo', AppTheme.primary, () {}),
              ]),
              _buildMenuSection('CỬA HÀNG', [
                _MenuIcon(Icons.inventory_2_rounded, 'Sản Phẩm', AppTheme.accent, () => _nav(const OwnerShopManagementScreen())),
                _MenuIcon(Icons.local_shipping_rounded, 'Đơn Hàng', AppTheme.accent, () => _nav(const OwnerOrderManagementScreen())),
              ]),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.scaffoldLight.withOpacity(0.8),
      surfaceTintColor: Colors.transparent,
      title: const Text('Bảng điều khiển Đối tác', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primary)),
      centerTitle: true,
      actions: [
        _buildNotificationIcon(),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        IconButton(icon: const Icon(Icons.notifications_outlined, color: AppTheme.primary), onPressed: _showNotificationSheet),
        if (_unreadCount > 0)
          Positioned(
            right: 8, top: 10,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(String? name) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chào mừng trở lại,', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(name ?? 'Chủ sân', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.premiumShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TỔNG DOANH THU', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      '${_monthlyRevenue.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}đ',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CHỜ DUYỆT', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('$_pendingCount', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 8),
                          if (_pendingCount > 0) const Icon(Icons.emergency_rounded, color: AppTheme.highlight, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuIcon> items) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.3,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _buildMenuCard(items[i]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(_MenuIcon data) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(data.icon, color: data.color, size: 28),
            Text(data.label, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _nav(Widget s) => Navigator.push(context, MaterialPageRoute(builder: (_) => s));

  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _NotificationList(notifications: _notifications, onRefresh: _fetchData),
    );
  }
}

class _MenuIcon {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  _MenuIcon(this.icon, this.label, this.color, this.onTap);
}

class _NotificationList extends StatelessWidget {
  final List<SystemNotification> notifications; final VoidCallback onRefresh;
  const _NotificationList({required this.notifications, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                  TextButton(
                    onPressed: () async {
                      await NotificationService.markAllAsRead(auth.user!.id.toString());
                      onRefresh();
                    },
                    child: const Text('Mark all read', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                ? const Center(child: Text('All caught up!', style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.builder(
                    controller: controller, padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: notifications.length,
                    itemBuilder: (_, i) {
                      final n = notifications[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: n.isRead ? Colors.transparent : AppTheme.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: n.isRead ? AppTheme.borderLight : AppTheme.primary.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(n.type == 'order' ? Icons.shopping_bag_rounded : Icons.info_rounded, color: AppTheme.primary, size: 20),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.title, style: TextStyle(color: AppTheme.primary, fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800, fontSize: 14)),
                                  Text(n.message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}