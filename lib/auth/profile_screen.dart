import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'edit_profile_screen.dart';
import 'security_screen.dart';
import 'notification_settings_screen.dart';
import 'package:shuttlecourt/features/owner/screens/owner_dashboard_screen.dart';
import 'language_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (!authService.isAuthenticated) {
          return _buildLoginPrompt(context);
        }

        final user = authService.user!;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldLight,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(user),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildInfoCard(context, user),
                      const SizedBox(height: 24),
                      _buildSettingsSection(context),
                      const SizedBox(height: 32),
                      _buildLogoutButton(context, authService),
                      const SizedBox(height: 50),
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

  Widget _buildHeader(User user) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
              ),
            ),
            Positioned(
              top: 60,
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: const Icon(Icons.person_rounded, size: 50, color: AppTheme.primary),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Builder(
                          builder: (ctx) => GestureDetector(
                            onTap: () => _navigateToEditProfile(ctx, user),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                              child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.fullName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('THÔNG TIN CÁ NHÂN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1.2)),
              GestureDetector(
                onTap: () => _navigateToEditProfile(context, user),
                child: const Text('Chỉnh sửa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accent)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.person_outline_rounded, 'Họ tên', user.fullName),
          const Divider(height: 32),
          _buildInfoRow(Icons.alternate_email_rounded, 'Email', user.email),
          const Divider(height: 32),
          _buildInfoRow(Icons.phone_android_rounded, 'Số điện thoại', user.phone),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text('CÀI ĐẶT & HỖ TRỢ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1.2)),
        ),
        if (user?.role == 'owner')
          _buildSettingTile(context, Icons.dashboard_customize_rounded, 'Bảng điều khiển Chủ sân', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()))),
        _buildSettingTile(context, Icons.shield_outlined, 'Bảo mật & Mật khẩu', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen()))),
        _buildSettingTile(context, Icons.notifications_none_rounded, 'Thông báo', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()))),
        _buildSettingTile(context, Icons.language_rounded, 'Ngôn ngữ', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()))),
        _buildSettingTile(context, Icons.help_outline_rounded, 'Hỗ trợ khách hàng', () => _showComingSoon(context, 'Hỗ trợ')),
      ],
    );
  }

  Widget _buildSettingTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        onTap: onTap,
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context, User user) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)));
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tính năng $feature đang được phát triển!'), backgroundColor: AppTheme.accent),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService auth) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton(
        onPressed: () => _confirmLogout(context, auth),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.error.withOpacity(0.2))),
        ),
        child: const Text('ĐĂNG XUẤT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), shape: BoxShape.circle),
                child: const Icon(Icons.person_add_alt_1_rounded, size: 60, color: AppTheme.primary),
              ),
              const SizedBox(height: 40),
              const Text('Tham gia với chúng tôi!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              const Text(
                'Đăng nhập để quản lý lịch đặt sân và kết nối với cộng đồng lông thủ.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('ĐĂNG NHẬP'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Tạo tài khoản mới', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
            onPressed: () {
              auth.logout();
              Navigator.pop(context);
            },
            child: const Text('Đăng xuất', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
