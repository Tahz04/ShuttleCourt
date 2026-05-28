import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/services/admin_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_styles.dart';

// Import existing mobile screens to embed
import 'package:shuttlecourt/features/owner/screens/owner_courts_screen.dart';
import 'package:shuttlecourt/features/owner/screens/owner_booking_management_screen.dart';
import 'package:shuttlecourt/features/owner/screens/owner_review_management_screen.dart';
import 'package:shuttlecourt/features/shop/screens/owner_shop_management_screen.dart';
import 'package:shuttlecourt/features/shop/screens/owner_order_management_screen.dart';

class WebAdminDashboardPage extends StatefulWidget {
  const WebAdminDashboardPage({super.key});

  @override
  State<WebAdminDashboardPage> createState() => _WebAdminDashboardPageState();
}

class _WebAdminDashboardPageState extends State<WebAdminDashboardPage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Thống kê', 'icon': Icons.insights_rounded, 'color': WebStyles.brand},
    {'title': 'Người dùng', 'icon': Icons.people_alt_rounded, 'color': const Color(0xFF3B82F6)},
    {'title': 'Duyệt chủ sân', 'icon': Icons.admin_panel_settings_rounded, 'color': const Color(0xFFF59E0B)},
    {'title': 'Quản lý Sân', 'icon': Icons.stadium_rounded, 'color': WebStyles.inkMid},
    {'title': 'Quản lý Lịch Đặt', 'icon': Icons.event_available_rounded, 'color': WebStyles.inkMid},
    {'title': 'Quản lý Đánh giá', 'icon': Icons.star_rate_rounded, 'color': WebStyles.inkMid},
    {'title': 'Quản lý Shop', 'icon': Icons.storefront_rounded, 'color': WebStyles.inkMid},
    {'title': 'Quản lý Đơn hàng', 'icon': Icons.receipt_long_rounded, 'color': WebStyles.inkMid},
  ];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final s = await AdminService.getDashboardStats();
      if (mounted) setState(() { _stats = s; _isLoading = false; });
    } catch (e) {
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
            onNavTap: (index) => Navigator.pop(context),
          ),
          Expanded(
            child: isWide 
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSidebar(user?.fullName ?? 'Admin'),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: WebStyles.darkBannerGrad,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quản trị viên',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedIndex == index;
                final color = item['color'] as Color;

                if (index == 3) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Text('DỮ LIỆU HỆ THỐNG', style: WebStyles.eyebrow),
                      ),
                      _buildMenuItem(item, index, isSelected, color),
                    ],
                  );
                }

                return _buildMenuItem(item, index, isSelected, color);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item, int index, bool isSelected, Color color) {
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
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item['title'] as String,
                    style: TextStyle(
                      color: isSelected ? color : WebStyles.inkMid,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: WebStyles.bg,
      child: SingleChildScrollView(
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
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return _buildStatsTab();
      case 1: return const _WebUsersView();
      case 2: return const _WebOwnerRequestsView();
      case 3: return const OwnerCourtsScreen(isAdmin: true, isEmbedded: true);
      case 4: return const OwnerBookingManagementScreen(isAdmin: true, isEmbedded: true);
      case 5: return const OwnerReviewManagementScreen(isAdmin: true, isEmbedded: true);
      case 6: return const OwnerShopManagementScreen(isAdmin: true, isEmbedded: true);
      case 7: return const OwnerOrderManagementScreen(isEmbedded: true); // Currently no isAdmin required in mobile version
      default: return const Center(child: Text('Coming soon'));
    }
  }

  Widget _buildStatsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: WebStyles.brand));
    }

    if (_stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            const Text('Không thể tải dữ liệu thống kê', style: TextStyle(color: WebStyles.inkMid)),
            TextButton(onPressed: _fetchStats, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thống kê Hệ thống', style: WebStyles.sectionTitle),
                  SizedBox(height: 8),
                  Text('Tổng quan các số liệu quan trọng trên toàn hệ thống', style: WebStyles.sectionSub),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _fetchStats,
                tooltip: 'Làm mới',
              ),
            ],
          ),
          const SizedBox(height: 32),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 960 ? 4 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Tổng Người Dùng', _stats!['totalUsers'].toString(), Icons.people_alt_rounded, const Color(0xFF3B82F6)),
              _buildStatCard('Tổng Số Sân', _stats!['totalCourts'].toString(), Icons.sports_tennis_rounded, WebStyles.brand),
              _buildStatCard('Doanh thu Đặt Sân', currencyFormat.format(double.tryParse(_stats!['totalBookingRevenue'].toString()) ?? 0), Icons.monetization_on_rounded, const Color(0xFFF59E0B)),
              _buildStatCard('Doanh thu Shop', currencyFormat.format(double.tryParse(_stats!['totalShopRevenue'].toString()) ?? 0), Icons.shopping_bag_rounded, const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(WebStyles.rLg),
        border: Border.all(color: WebStyles.border),
        boxShadow: WebStyles.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: WebStyles.inkLight, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Users View ─────────────────────────────────────────────────────────────

class _WebUsersView extends StatefulWidget {
  const _WebUsersView();
  @override
  State<_WebUsersView> createState() => _WebUsersViewState();
}

class _WebUsersViewState extends State<_WebUsersView> {
  List<dynamic> users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final u = await AdminService.getAllUsers();
    if (mounted) setState(() { users = u; _isLoading = false; });
  }

  Future<void> _toggleLock(String id, String currentStatus) async {
    final success = await AdminService.toggleUserLock(id);
    if (success) {
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật trạng thái thành công')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: WebStyles.brand));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quản lý Người Dùng', style: WebStyles.sectionTitle),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Làm mới'),
                style: WebStyles.ghostBtn(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final u = users[index];
              final isLocked = u['status'] == 'locked';
              
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: WebStyles.card,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: WebStyles.dark100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, color: WebStyles.inkFaint),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['full_name'] ?? 'Không tên', style: WebStyles.cardTitle),
                          const SizedBox(height: 4),
                          Text('${u['email']}', style: WebStyles.caption),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: WebStyles.dark50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: WebStyles.border),
                      ),
                      child: Text(
                        'Vai trò: ${u['role']}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WebStyles.inkMid),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      children: [
                        Text(isLocked ? 'Đang Khóa' : 'Hoạt Động', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isLocked ? AppTheme.error : WebStyles.brand)),
                        Switch(
                          value: !isLocked,
                          activeThumbColor: WebStyles.brand,
                          onChanged: (val) => _toggleLock(u['id'].toString(), u['status']),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Owner Requests View ───────────────────────────────────────────────────

class _WebOwnerRequestsView extends StatefulWidget {
  const _WebOwnerRequestsView();
  @override
  State<_WebOwnerRequestsView> createState() => _WebOwnerRequestsViewState();
}

class _WebOwnerRequestsViewState extends State<_WebOwnerRequestsView> {
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
    if (mounted) {
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(String id) async {
    final success = await AdminService.approveRequest(id);
    if (success) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt thành công!'), backgroundColor: WebStyles.brand));
      _fetchRequests();
    }
  }

  Future<void> _rejectRequest(String id) async {
    final success = await AdminService.rejectRequest(id);
    if (success) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối yêu cầu.'), backgroundColor: AppTheme.error));
      _fetchRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: WebStyles.brand));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Duyệt Chủ Sân Mới', style: WebStyles.sectionTitle),
              ElevatedButton.icon(
                onPressed: _fetchRequests,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Làm mới'),
                style: WebStyles.ghostBtn(),
              ),
            ],
          ),
        ),
        if (_requests.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 64, color: WebStyles.inkFaint),
                  SizedBox(height: 16),
                  Text('Không có yêu cầu chờ duyệt nào', style: TextStyle(fontSize: 18, color: WebStyles.inkMid, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final req = _requests[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: WebStyles.card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.storefront_rounded, color: Color(0xFFF59E0B)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Yêu cầu từ: ${req['full_name'] ?? req['court_name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WebStyles.ink)),
                                const SizedBox(height: 4),
                                Text('Email: ${req['email']}', style: WebStyles.caption),
                                Text('CCCD: ${req['id_number'] ?? req['court_address']}', style: WebStyles.caption),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _rejectRequest(req['id'].toString()),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Từ chối'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: const BorderSide(color: AppTheme.error),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _approveRequest(req['id'].toString()),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Duyệt yêu cầu'),
                            style: WebStyles.primaryBtn(h: 14, v: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: WebStyles.border),
                      const SizedBox(height: 16),
                      const Text('Ảnh CCCD đính kèm:', style: TextStyle(fontWeight: FontWeight.w600, color: WebStyles.inkMid)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (req['cccd_front'] != null)
                            Expanded(
                              child: Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: WebStyles.border),
                                  image: DecorationImage(
                                    image: NetworkImage(req['cccd_front']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          if (req['cccd_back'] != null)
                            Expanded(
                              child: Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: WebStyles.border),
                                  image: DecorationImage(
                                    image: NetworkImage(req['cccd_back']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
