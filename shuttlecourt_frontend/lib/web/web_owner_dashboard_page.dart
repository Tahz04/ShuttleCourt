import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_footer.dart';
import 'package:shuttlecourt/services/api_booking_service.dart';
import 'dart:async';

/// Web-optimized owner dashboard for managing courts, bookings, products, and revenue
class WebOwnerDashboardPage extends StatefulWidget {
  final Function(int)? onTabChange;

  const WebOwnerDashboardPage({super.key, this.onTabChange});

  @override
  State<WebOwnerDashboardPage> createState() => _WebOwnerDashboardPageState();
}

class _WebOwnerDashboardPageState extends State<WebOwnerDashboardPage> {
  int _selectedTab = 0;
  bool _isLoading = true;
  int _pendingBookings = 0;
  int _totalCourts = 0;
  double _monthlyRevenue = 0.0;
  int _totalBookings = 0;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.user == null) return;

    try {
      final bookings = await ApiBookingService.getAllBookings();
      if (mounted) {
        setState(() {
          _pendingBookings = bookings
              .where((b) => b.status == 'Chờ duyệt')
              .length;
          _totalBookings = bookings.length;
          _totalCourts = 8; // Placeholder - would need actual API
          _monthlyRevenue = bookings
              .where(
                (b) => b.status == 'Đã duyệt' || b.status == 'Đã thanh toán',
              )
              .fold(0.0, (sum, b) => sum + b.price);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isOwner = auth.user?.role == 'owner';

    if (!auth.isAuthenticated || !isOwner) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldLight,
        body: Column(
          children: [
            WebNavbar(
              selectedIndex: 6,
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
                            color: AppTheme.error.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.block_rounded,
                            size: 60,
                            color: AppTheme.error,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Truy cập bị từ chối',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Bảng điều khiển này chỉ dành cho chủ sân.',
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
            selectedIndex: 6,
            onNavTap: (i) => widget.onTabChange?.call(i),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: const CircularProgressIndicator(
                      color: AppTheme.primary,
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeader(auth.user?.fullName ?? 'Owner'),
                        _buildStatsSection(),
                        _buildTabNavigation(),
                        _buildTabContent(),
                        WebFooter(onNavTap: (i) => widget.onTabChange?.call(i)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bảng điều khiển đối tác',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chào $name! 👋',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getStatsGridCount(),
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              'Tổng sân',
              _totalCourts.toString(),
              Icons.stadium_rounded,
              AppTheme.primary,
            ),
            _buildStatCard(
              'Đặt sân (Tháng)',
              _totalBookings.toString(),
              Icons.calendar_month_rounded,
              AppTheme.accent,
            ),
            _buildStatCard(
              'Chờ duyệt',
              _pendingBookings.toString(),
              Icons.pending_actions_rounded,
              AppTheme.highlight,
            ),
            _buildStatCard(
              'Doanh thu',
              '${(_monthlyRevenue / 1000000).toStringAsFixed(1)}M đ',
              Icons.trending_up_rounded,
              AppTheme.accentGold,
            ),
          ],
        ),
      ),
    );
  }

  int _getStatsGridCount() {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    final tabs = ['Tổng quan', 'Sân', 'Đặt sân', 'Sản phẩm', 'Cài đặt'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(tabs.length, (index) {
              final isActive = _selectedTab == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedTab = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: () {
          switch (_selectedTab) {
            case 0:
              return _buildOverviewTab();
            case 1:
              return _buildCourtsTab();
            case 2:
              return _buildBookingsTab();
            case 3:
              return _buildProductsTab();
            case 4:
              return _buildSettingsTab();
            default:
              return const SizedBox();
          }
        }(),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan hoạt động',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActivityItem(
                'Đặt sân',
                'Tháng này',
                _totalBookings.toString(),
              ),
              _buildActivityItem(
                'Chờ duyệt',
                'Cần xử lý',
                _pendingBookings.toString(),
              ),
              _buildActivityItem(
                'Doanh thu',
                'Tháng này',
                '${(_monthlyRevenue / 1000000).toStringAsFixed(1)}M',
              ),
              _buildActivityItem('Đánh giá', 'Điểm TB', '4.8⭐'),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Tài liệu & Hỗ trợ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildHelpChip('Hướng dẫn sử dụng', Icons.description_outlined),
              _buildHelpChip('Liên hệ hỗ trợ', Icons.support_agent_outlined),
              _buildHelpChip('Xem quy định', Icons.policy_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String label, String subtitle, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.scaffoldLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtsTab() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quản lý sân',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tổng số sân: $_totalCourts',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng sẽ sớm được phát hành'),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm sân'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildComingSoonCard(
            'Danh sách sân của bạn sẽ hiển thị tại đây',
            Icons.stadium_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản lý đặt sân',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          if (_pendingBookings > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.highlight.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.highlight.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_rounded, color: AppTheme.highlight),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bạn có $_pendingBookings đơn đặt sân chờ duyệt',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _buildComingSoonCard(
              'Không có đơn đặt sân chờ xử lý',
              Icons.check_circle_rounded,
            ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản lý sản phẩm',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildComingSoonCard(
            'Tính năng quản lý sản phẩm sẽ sớm được phát hành',
            Icons.inventory_2_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cài đặt',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingItem(
            'Thông tin cửa hàng',
            'Quản lý tên, địa chỉ, liên hệ',
            Icons.store_rounded,
          ),
          _buildSettingItem(
            'Thanh toán',
            'Cấu hình tài khoản ngân hàng',
            Icons.payment_rounded,
          ),
          _buildSettingItem(
            'Chính sách',
            'Điều kiện dịch vụ, hoàn trả',
            Icons.policy_rounded,
          ),
          _buildSettingItem(
            'Nhật ký hoạt động',
            'Xem lịch sử giao dịch',
            Icons.history_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildComingSoonCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 64, color: AppTheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
