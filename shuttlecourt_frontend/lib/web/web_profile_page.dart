import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/auth/login_screen.dart';
import 'package:shuttlecourt/auth/register_screen.dart';
import 'package:shuttlecourt/auth/edit_profile_screen.dart';
import 'package:shuttlecourt/auth/security_screen.dart';
import 'package:shuttlecourt/auth/notification_settings_screen.dart';
import 'package:shuttlecourt/features/owner/screens/owner_dashboard_screen.dart';
import 'package:shuttlecourt/auth/language_settings_screen.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_footer.dart';

class WebProfilePage extends StatelessWidget {
  final Function(int, {String? query})? onTabChange;

  const WebProfilePage({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (!authService.isAuthenticated) {
          return Scaffold(
            backgroundColor: AppTheme.scaffoldLight,
            body: Column(
              children: [
                WebNavbar(
                  selectedIndex: 5,
                  onNavTap: (i) => onTabChange?.call(i),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 48,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'Đăng nhập để xem hồ sơ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Quản lý lịch đặt sân, thông tin cá nhân và cài đặt bảo mật của bạn.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textMuted,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'ĐĂNG NHẬP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),
                              child: const Text(
                                'Tạo tài khoản mới',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
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

        final user = authService.user!;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldLight,
          body: Column(
            children: [
              WebNavbar(
                selectedIndex: 5,
                onNavTap: (i) => onTabChange?.call(i),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Profile Area
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        size: 64,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                EditProfileScreen(user: user),
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.accent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.edit_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.fullName,
                                        style: const TextStyle(
                                          fontSize: 32,
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
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            user.email,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          const Icon(
                                            Icons.phone_outlined,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            user.phone,
                                            style: const TextStyle(
                                              fontSize: 14,
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
                      ),

                      // Main Content Area
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 40,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left sidebar (Settings menu)
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.borderLight,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            24,
                                            24,
                                            24,
                                            12,
                                          ),
                                          child: Text(
                                            'CÀI ĐẶT',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.textMuted,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                        if (user.role == 'owner')
                                          _MenuTile(
                                            icon: Icons
                                                .dashboard_customize_rounded,
                                            title: 'Bảng điều khiển',
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const OwnerDashboardScreen(),
                                              ),
                                            ),
                                          ),
                                        _MenuTile(
                                          icon: Icons.person_outline_rounded,
                                          title: 'Chỉnh sửa hồ sơ',
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  EditProfileScreen(user: user),
                                            ),
                                          ),
                                        ),
                                        _MenuTile(
                                          icon: Icons.shield_outlined,
                                          title: 'Bảo mật & Mật khẩu',
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const SecurityScreen(),
                                            ),
                                          ),
                                        ),
                                        _MenuTile(
                                          icon:
                                              Icons.notifications_none_rounded,
                                          title: 'Thông báo',
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const NotificationSettingsScreen(),
                                            ),
                                          ),
                                        ),
                                        _MenuTile(
                                          icon: Icons.language_rounded,
                                          title: 'Ngôn ngữ',
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const LanguageSettingsScreen(),
                                            ),
                                          ),
                                        ),
                                        const Divider(height: 32),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            24,
                                            0,
                                            24,
                                            24,
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: TextButton.icon(
                                              onPressed: () => _confirmLogout(
                                                context,
                                                authService,
                                              ),
                                              icon: const Icon(
                                                Icons.logout_rounded,
                                                size: 20,
                                              ),
                                              label: const Text('ĐĂNG XUẤT'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppTheme.error,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  side: BorderSide(
                                                    color: AppTheme.error
                                                        .withOpacity(0.2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 40),

                                // Right Content
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tổng quan',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final crossAxisCount =
                                              constraints.maxWidth > 600
                                              ? 2
                                              : 1;
                                          return GridView.count(
                                            crossAxisCount: crossAxisCount,
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            crossAxisSpacing: 20,
                                            mainAxisSpacing: 20,
                                            childAspectRatio: 2.2,
                                            children: const [
                                              _StatCard(
                                                title: 'Sân đã đặt',
                                                value: '12',
                                                icon:
                                                    Icons.sports_tennis_rounded,
                                                color: AppTheme.primary,
                                              ),
                                              _StatCard(
                                                title: 'Đánh giá',
                                                value: '5',
                                                icon: Icons.star_rounded,
                                                color: Colors.amber,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      WebFooter(onNavTap: (i) => onTabChange?.call(i)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn thoát tài khoản không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              auth.logout();
              Navigator.pop(context);
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.borderLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
