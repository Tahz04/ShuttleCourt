import 'package:flutter/material.dart';
import 'package:shuttlecourt/services/admin_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:shuttlecourt/features/shop/screens/owner_shop_management_screen.dart' as shuttlecourt_shop;
import 'package:shuttlecourt/features/shop/screens/owner_order_management_screen.dart' as shuttlecourt_order;
import 'package:shuttlecourt/features/owner/screens/owner_courts_screen.dart' as shuttlecourt_court;
import 'package:shuttlecourt/features/owner/screens/owner_review_management_screen.dart' as shuttlecourt_review;
import 'package:shuttlecourt/features/owner/screens/owner_booking_management_screen.dart' as shuttlecourt_booking;
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/services/notification_service.dart' as shuttlecourt_notif;
import 'package:shuttlecourt/features/notifications/notification_screen.dart' as notif_ui;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _unreadCount = 0;
  List<shuttlecourt_notif.SystemNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.user == null) return;
    try {
      final notifs = await shuttlecourt_notif.NotificationService.getNotifications(auth.user!.id.toString());
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _unreadCount = notifs.where((n) => !n.isRead).length;
        });
      }
    } catch (e) {
      debugPrint('Admin fetch notif error: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quản trị hệ thống', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.primary), 
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const notif_ui.NotificationScreen()));
                }
              ),
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
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Thống kê'),
            Tab(text: 'Người dùng'),
            Tab(text: 'Duyệt chủ sân'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StatsView(),
          _UsersView(),
          _OwnerRequestsView(),
        ],
      ),
    );
  }
}

class _StatsView extends StatefulWidget {
  const _StatsView();
  @override
  State<_StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<_StatsView> {
  Map<String, dynamic>? stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await AdminService.getDashboardStats();
    setState(() => stats = s);
  }

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const Center(child: CircularProgressIndicator());
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Báo Cáo Doanh Thu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          _buildStatCard('Tổng số Người dùng', stats!['totalUsers'].toString(), Icons.people_alt_rounded, Colors.blue),
          _buildStatCard('Tổng số Sân', stats!['totalCourts'].toString(), Icons.sports_tennis_rounded, Colors.green),
          _buildStatCard('Doanh thu Đặt sân', currencyFormat.format(double.tryParse(stats!['totalBookingRevenue'].toString()) ?? 0), Icons.monetization_on_rounded, Colors.orange),
          _buildStatCard('Doanh thu Shop', currencyFormat.format(double.tryParse(stats!['totalShopRevenue'].toString()) ?? 0), Icons.shopping_bag_rounded, Colors.purple),
          
          const SizedBox(height: 24),
          const Text('Quản Lý Nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          _buildManagementButton(
            context, 
            'Quản lý Sản phẩm (Shop)', 
            Icons.storefront_rounded, 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const shuttlecourt_shop.OwnerShopManagementScreen(isAdmin: true))),
          ),
          const SizedBox(height: 8),
          _buildManagementButton(
            context,
            'Duyệt & Quản lý Đơn hàng',
            Icons.receipt_long_rounded,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const shuttlecourt_order.OwnerOrderManagementScreen())),
          ),
          const SizedBox(height: 8),
          _buildManagementButton(
            context, 
            'Quản lý Sân Cầu Lông', 
            Icons.sports_tennis_rounded, 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const shuttlecourt_court.OwnerCourtsScreen(isAdmin: true))),
          ),
          const SizedBox(height: 8),
          _buildManagementButton(
            context, 
            'Quản lý Lịch Đặt (Booking)', 
            Icons.event_available_rounded, 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const shuttlecourt_booking.OwnerBookingManagementScreen(isAdmin: true))),
          ),
          const SizedBox(height: 8),
          _buildManagementButton(
            context, 
            'Quản lý Đánh giá toàn cục', 
            Icons.star_rate_rounded, 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const shuttlecourt_review.OwnerReviewManagementScreen(isAdmin: true))),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
        subtitle: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ),
    );
  }

  Widget _buildManagementButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _UsersView extends StatefulWidget {
  const _UsersView();
  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final u = await AdminService.getAllUsers();
    setState(() => users = u);
  }

  Future<void> _toggleLock(String id, String currentStatus) async {
    final success = await AdminService.toggleUserLock(id);
    if (success) {
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật trạng thái thành công')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final u = users[index];
          final isLocked = u['status'] == 'locked';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(u['full_name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${u['email']}\nVai trò: ${u['role']}'),
              trailing: Switch(
                value: !isLocked,
                activeColor: Colors.green,
                onChanged: (val) => _toggleLock(u['id'].toString(), u['status']),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

class _OwnerRequestsView extends StatefulWidget {
  const _OwnerRequestsView();
  @override
  State<_OwnerRequestsView> createState() => _OwnerRequestsViewState();
}

class _OwnerRequestsViewState extends State<_OwnerRequestsView> {
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    final requests = await AdminService.getAllOwnerRequests();
    setState(() {
      _requests = requests;
      _isLoading = false;
    });
  }

  Future<void> _approveRequest(String id) async {
    final success = await AdminService.approveRequest(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã duyệt thành công!'), backgroundColor: Colors.green),
      );
      _fetchRequests();
    }
  }

  Future<void> _rejectRequest(String id) async {
    final success = await AdminService.rejectRequest(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã từ chối yêu cầu.'), backgroundColor: AppTheme.error),
      );
      _fetchRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _requests.isEmpty
            ? const Center(child: Text('Không có yêu cầu duyệt chủ sân nào'))
            : RefreshIndicator(
                onRefresh: _fetchRequests,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Họ và Tên: ${req['full_name'] ?? req['court_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text('Tài khoản: ${req['email']}'),
                            Text('Số CCCD: ${req['id_number'] ?? req['court_address']}'),
                            const SizedBox(height: 12),
                            const Text('Ảnh CCCD:', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (req['cccd_front'] != null)
                                  Expanded(
                                    child: AspectRatio(
                                      aspectRatio: 1.5,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(req['cccd_front'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                if (req['cccd_back'] != null)
                                  Expanded(
                                    child: AspectRatio(
                                      aspectRatio: 1.5,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(req['cccd_back'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => _rejectRequest(req['id'].toString()),
                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error)),
                              child: const Text('TỪ CHỐI'),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _approveRequest(req['id'].toString()),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('DUYỆT YÊU CẦU NÀY', style: TextStyle(color: Colors.white)),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
  }
}
