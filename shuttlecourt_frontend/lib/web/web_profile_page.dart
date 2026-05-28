import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/auth/login_screen.dart';
import 'package:shuttlecourt/auth/register_screen.dart';
import 'package:shuttlecourt/auth/edit_profile_screen.dart';
import 'package:shuttlecourt/auth/security_screen.dart';
import 'package:shuttlecourt/auth/notification_settings_screen.dart';
import 'package:shuttlecourt/features/owner/screens/owner_dashboard_screen.dart';
import 'package:shuttlecourt/main.dart';
import 'package:shuttlecourt/features/admin/screens/admin_dashboard_screen.dart';
import 'package:shuttlecourt/auth/language_settings_screen.dart';
import 'package:shuttlecourt/models/booking.dart';
import 'package:shuttlecourt/models/match_model.dart';
import 'package:shuttlecourt/services/api_booking_service.dart';
import 'package:shuttlecourt/features/matchmaking/services/matchmaking_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_footer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:shuttlecourt/features/reviews/screens/write_review_screen.dart';

/// Modern tabbed account page integrating profile, booking history, match history, and settings
class WebProfilePage extends StatefulWidget {
  final Function(int)? onTabChange;
  final int initialTab;

  const WebProfilePage({super.key, this.onTabChange, this.initialTab = 0});

  @override
  State<WebProfilePage> createState() => _WebProfilePageState();
}

class _WebProfilePageState extends State<WebProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _loadHistory();
  }

  void _loadHistory() {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated || auth.user == null) {
      _historyFuture = Future.value({'bookings': [], 'matches': []});
      return;
    }
    int userId = int.parse(auth.user!.id);
    _historyFuture =
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    if (widget.onTabChange != null) {
      widget.onTabChange!(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (!authService.isAuthenticated) {
          return _buildUnauthenticatedView();
        }

        final user = authService.user!;
        return Scaffold(
          backgroundColor: AppTheme.scaffoldLight,
          body: Column(
            children: [
              WebNavbar(selectedIndex: 6, onNavTap: _onNavTap),
              Expanded(
                child: Column(
                  children: [
                    _buildProfileHeader(user),
                    _buildTabNavigation(),
                    Expanded(child: _buildTabContent(user, authService)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnauthenticatedView() {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: Column(
        children: [
          WebNavbar(selectedIndex: 6, onNavTap: _onNavTap),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 40,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Đăng nhập để tiếp tục',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Quản lý lịch sử đặt sân, kèo ghép, và cài đặt tài khoản.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ĐĂNG NHẬP',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ĐĂNG KÝ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
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

  Widget _buildProfileHeader(dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.phone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Tổng quan'),
              Tab(text: 'Lịch sử đặt sân'),
              Tab(text: 'Lịch sử ghép sân'),
              Tab(text: 'Cài đặt'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(dynamic user, AuthService authService) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(user, authService),
        _buildBookingsTab(),
        _buildMatchesTab(),
        _buildSettingsTab(user, authService),
      ],
    );
  }

  Widget _buildOverviewTab(dynamic user, AuthService authService) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin tài khoản',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow('Họ tên', user.fullName),
                                  const Divider(height: 20, color: AppTheme.borderLight),
                                  _buildInfoRow('Email', user.email),
                                  const Divider(height: 20, color: AppTheme.borderLight),
                                  _buildInfoRow('Số điện thoại', user.phone),
                                  const Divider(height: 20, color: AppTheme.borderLight),
                                  _buildInfoRow(
                                    'Loại tài khoản',
                                    user.role == 'owner'
                                        ? '👑 Chủ sân'
                                        : (user.role == 'admin'
                                            ? '🛠️ Quản trị viên'
                                            : 'Người chơi'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Hành động nhanh',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                if (user.role == 'owner' || user.role == 'admin') ...[
                                  Expanded(
                                    child: _buildQuickActionButton(
                                      icon: Icons.dashboard_rounded,
                                      label: 'Bảng điều khiển',
                                      color: AppTheme.accent,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => user.role == 'admin'
                                              ? const AdminDashboardScreen()
                                              : const OwnerDashboardScreen(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: _buildQuickActionButton(
                                    icon: Icons.edit_rounded,
                                    label: 'Chỉnh sửa thông tin',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditProfileScreen(user: user),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickActionButton(
                                    icon: Icons.logout_rounded,
                                    label: 'Đăng xuất',
                                    color: AppTheme.error,
                                    onTap: () => _confirmLogout(authService),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                WebFooter(onNavTap: _onNavTap),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBookingsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        final bookings =
            (snapshot.data?['bookings'] as List?)?.cast<Booking>() ?? [];

        if (bookings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_note_rounded,
                    size: 60,
                    color: AppTheme.primary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có lịch sử đặt sân',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            child: Column(
                              children: List.generate(
                                bookings.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildBookingCard(bookings[index]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    WebFooter(onNavTap: _onNavTap),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildMatchesTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        final matches =
            (snapshot.data?['matches'] as List?)?.cast<MatchModel>() ?? [];

        if (matches.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 60,
                    color: AppTheme.primary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có lịch sử ghép sân',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            child: Column(
                              children: List.generate(
                                matches.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildMatchCard(matches[index]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    WebFooter(onNavTap: _onNavTap),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildSettingsTab(dynamic user, AuthService authService) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          children: [
                            if (user.role == 'owner' || user.role == 'admin')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildSettingsTile(
                                  icon: Icons.dashboard_customize_rounded,
                                  title: 'Bảng điều khiển',
                                  subtitle: user.role == 'admin'
                                      ? 'Bảng điều khiển quản trị viên'
                                      : 'Quản lý sân, đặt phòng, sản phẩm',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => user.role == 'admin'
                                          ? const AdminDashboardScreen()
                                          : const OwnerDashboardScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildSettingsTile(
                                icon: Icons.person_outline_rounded,
                                title: 'Chỉnh sửa thông tin',
                                subtitle: 'Cập nhật tên, email, số điện thoại',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(user: user),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildSettingsTile(
                                icon: Icons.shield_outlined,
                                title: 'Bảo mật & Mật khẩu',
                                subtitle: 'Quản lý mật khẩu và xác thực',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SecurityScreen()),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildSettingsTile(
                                icon: Icons.notifications_none_rounded,
                                title: 'Thông báo',
                                subtitle: 'Cài đặt thông báo và email',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationSettingsScreen(),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildSettingsTile(
                                icon: Icons.language_rounded,
                                title: 'Ngôn ngữ',
                                subtitle: 'Chọn ngôn ngữ hiển thị',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LanguageSettingsScreen(),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildSettingsTile(
                                icon: Icons.help_outline_rounded,
                                title: 'Hỗ trợ khách hàng',
                                subtitle: 'Hotline: 0986049032 (Zalo/Gọi trực tiếp)',
                                onTap: () => _showSupportDialog(context),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _buildSettingsTile(
                                icon: Icons.logout_rounded,
                                title: 'Đăng xuất',
                                subtitle: 'Thoát khỏi tài khoản của bạn',
                                color: AppTheme.error,
                                onTap: () => _confirmLogout(authService),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                WebFooter(onNavTap: _onNavTap),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppTheme.primary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = AppTheme.primary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
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
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final bool isConfirmed = booking.status == 'Đã duyệt' ||
        booking.status == 'Đã thanh toán' ||
        booking.status == 'Đã hoàn thành';
    final bool isCompleted = booking.status == 'Đã hoàn thành';
    
    Color statusColor = AppTheme.primary;
    if (booking.status == 'Đã hủy' || booking.status == 'Từ chối') {
      statusColor = AppTheme.error;
    } else if (booking.status == 'Chờ duyệt') {
      statusColor = Colors.orangeAccent;
    } else if (booking.status == 'Đã hoàn thành') {
      statusColor = Colors.green;
    }

    bool canCancel = (booking.status == 'Chờ duyệt' || booking.status == 'Đã duyệt');
    bool isTooLateToCancel = false;
    try {
      final startTimeStr = booking.slot.split(' - ')[0];
      final timeParts = startTimeStr.split(':');
      final startDateTime = DateTime(
        booking.date.year,
        booking.date.month,
        booking.date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      final now = DateTime.now();
      
      if (booking.paymentMethod == 'Ghép kèo') {
        if (startDateTime.difference(now).inHours < 1) isTooLateToCancel = true;
      } else {
        if (startDateTime.difference(now).inHours < 12) isTooLateToCancel = true;
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isConfirmed
              ? AppTheme.primary.withOpacity(0.2)
              : AppTheme.borderLight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sports_tennis_rounded,
                  color: statusColor,
                  size: 18,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (booking.courtAddress.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        booking.courtAddress,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${booking.price.toStringAsFixed(0)}đ',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      booking.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(booking.date),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time_rounded,
                size: 12,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                booking.slot,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              if (canCancel)
                OutlinedButton(
                  onPressed: isTooLateToCancel ? null : () => _showCancelBookingDialog(booking),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    disabledForegroundColor: Colors.grey,
                    side: BorderSide(color: isTooLateToCancel ? Colors.grey : AppTheme.error),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    isTooLateToCancel ? 'Sát giờ, không thể hủy' : 'Hủy lịch đặt',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              if (isCompleted)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WriteReviewScreen(
                          courtName: booking.courtName,
                          bookingId: int.tryParse(booking.id),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.star_rate_rounded, size: 14, color: AppTheme.accentGold),
                  label: const Text(
                    'Đánh giá',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentGold,
                    side: const BorderSide(color: AppTheme.accentGold),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final bool isHost = auth.user != null && match.hostId.toString() == auth.user!.id;
    final bool isParticipant = auth.user != null && match.hostId.toString() != auth.user!.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: AppTheme.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.courtName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isHost ? 'Chủ kèo: Bạn' : 'Chủ kèo: ${match.hostName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${NumberFormat('#,###').format(match.price)}đ',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      match.level,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(match.matchDate),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time_rounded,
                size: 12,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                match.startTime.substring(0, 5),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.group_outlined,
                size: 14,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '${match.joinedCount}/${match.capacity}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              if (isHost)
                OutlinedButton.icon(
                  onPressed: () => _showParticipantsDialog(match),
                  icon: const Icon(Icons.group_rounded, size: 14),
                  label: const Text(
                    'Thành viên',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              if (isParticipant)
                OutlinedButton.icon(
                  onPressed: () => _showLeaveMatchDialog(match),
                  icon: const Icon(Icons.exit_to_app_rounded, size: 14),
                  label: const Text(
                    'Rời kèo',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelBookingDialog(Booking b) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy Đặt Sân', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text('Bạn có chắc chắn muốn hủy lịch đặt sân này không? Thao tác này không thể hoàn tác.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy Sân'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final success = await ApiBookingService.cancelBooking(b.id, int.parse(auth.user!.id));
      if (success && mounted) {
        _showWebToast('Đã hủy sân thành công!');
        setState(() { _loadHistory(); });
      } else if (mounted) {
        _showWebToast('Lỗi khi hủy sân. Vui lòng thử lại sau.');
      }
    }
  }

  Future<void> _showLeaveMatchDialog(MatchModel m) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời Kèo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text('Bạn có chắc chắn muốn rời khỏi kèo này không? Hành động này không thể hoàn tác.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rời Kèo'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final success = await MatchmakingService.leaveMatch(
        userId: int.parse(auth.user!.id),
        matchId: m.id,
      );
      if (success && mounted) {
        _showWebToast('Đã rời kèo thành công!');
        setState(() { _loadHistory(); });
      } else if (mounted) {
        _showWebToast('Lỗi khi rời kèo. Vui lòng thử lại.');
      }
    }
  }

  void _showParticipantsDialog(MatchModel m) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: MatchmakingService.getMatchParticipants(m.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                  }
                  final participants = snapshot.data ?? [];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Danh sách thành viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (participants.isEmpty)
                        const Padding(padding: EdgeInsets.all(20), child: Text('Chưa có ai tham gia kèo này.'))
                      else
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: participants.length,
                            itemBuilder: (context, index) {
                              final p = participants[index];
                              final date = DateTime.tryParse(p['joined_at'] ?? '');
                              final dateStr = date != null ? DateFormat('HH:mm dd/MM').format(date) : '';
                              final isReported = p['reported'] == 1 || p['reported'] == true;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.accent.withOpacity(0.2),
                                  child: const Icon(Icons.person, color: AppTheme.accent),
                                ),
                                title: Text(p['full_name'] ?? 'Người chơi', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Tham gia lúc: $dateStr', style: const TextStyle(fontSize: 12)),
                                trailing: isReported 
                                  ? const Text('Đã báo xấu', style: TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.bold))
                                  : IconButton(
                                      icon: const Icon(Icons.report_problem_rounded, color: Colors.orangeAccent),
                                      tooltip: 'Báo vắng mặt (Trừ 10đ uy tín)',
                                      onPressed: () {
                                        Navigator.pop(context); // Close dialog
                                        _showReportDialog(m.id, p['id'], p['full_name']);
                                      },
                                    ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showReportDialog(int matchId, int participantId, String participantName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Báo cáo Vắng mặt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
        content: Text('Bạn xác nhận $participantName đã không đến tham gia kèo này?\n\nNgười này sẽ bị TRỪ 10 ĐIỂM UY TÍN. Nếu điểm dưới 70, tài khoản của họ sẽ bị Admin khóa.\n\nHành động này không thể hoàn tác.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Báo Xấu'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final success = await MatchmakingService.reportNoShow(
        matchId: matchId,
        participantId: participantId,
        hostId: int.parse(auth.user!.id),
      );
      if (success && mounted) {
        _showWebToast('Đã ghi nhận báo cáo thành công!');
        setState(() { _loadHistory(); });
      } else if (mounted) {
        _showWebToast('Lỗi khi gửi báo cáo. Vui lòng thử lại.');
      }
    }
  }

  void _confirmLogout(AuthService auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn thoát tài khoản không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 12,
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.headset_mic_rounded,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Hỗ trợ khách hàng',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Đội ngũ ShuttleCourt luôn sẵn sàng hỗ trợ quý khách giải đáp mọi thắc mắc và xử lý sự cố đặt sân.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Support actions
                  _buildWebSupportTile(
                    icon: Icons.phone_forwarded_rounded,
                    title: 'Gọi Hotline trực tiếp',
                    subtitle: '0986049032',
                    color: AppTheme.primary,
                    onTap: () async {
                      final uri = Uri.parse('tel:0986049032');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        _showWebToast('Không thể thực hiện cuộc gọi từ trình duyệt này.');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildWebSupportTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Trò chuyện qua Zalo',
                    subtitle: 'Liên hệ nhanh qua tài khoản Zalo',
                    color: const Color(0xFF0068FF),
                    onTap: () async {
                      final uri = Uri.parse('https://zalo.me/0986049032');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        _showWebToast('Không thể mở liên kết Zalo.');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildWebSupportTile(
                    icon: Icons.copy_all_rounded,
                    title: 'Sao chép số điện thoại',
                    subtitle: '0986049032',
                    color: AppTheme.accent,
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: '0986049032'));
                      _showWebToast('Đã sao chép Hotline: 0986049032');
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.borderLight),
                  const SizedBox(height: 12),
                  Text(
                    'Giờ làm việc: 08:00 - 22:00 hàng ngày\nEmail hỗ trợ: support@shuttlecourt.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebSupportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade100),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
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
                    const SizedBox(height: 2),
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
              const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showWebToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        width: 360,
        backgroundColor: AppTheme.textPrimary,
      ),
    );
  }
}
