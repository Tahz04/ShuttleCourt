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
import 'package:shuttlecourt/features/owner/screens/owner_registration_screen.dart';
import 'package:shuttlecourt/features/admin/screens/admin_dashboard_screen.dart';
import 'package:shuttlecourt/features/shop/screens/user_order_history_screen.dart';
import 'package:shuttlecourt/features/reviews/screens/user_review_history_screen.dart';
import 'language_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

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
        if (user?.role == 'admin')
          _buildSettingTile(context, Icons.admin_panel_settings_rounded, 'Bảng điều khiển Admin', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()))),
        if (user?.role == 'owner')
          _buildSettingTile(context, Icons.dashboard_customize_rounded, 'Bảng điều khiển Chủ sân', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()))),
        if (user?.role == 'user') ...[
          _buildSettingTile(context, Icons.shopping_bag_outlined, 'Lịch sử mua hàng', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserOrderHistoryScreen()))),
          _buildSettingTile(context, Icons.star_border_rounded, 'Lịch sử đánh giá', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserReviewHistoryScreen()))),
          _buildSettingTile(context, Icons.business_center_rounded, 'Trở thành Chủ Sân', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerRegistrationScreen()))),
        ],
        _buildSettingTile(context, Icons.shield_outlined, 'Bảo mật & Mật khẩu', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen()))),
        _buildSettingTile(context, Icons.notifications_none_rounded, 'Thông báo', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()))),
        _buildSettingTile(context, Icons.language_rounded, 'Ngôn ngữ', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()))),
        _buildSettingTile(context, Icons.help_outline_rounded, 'Hỗ trợ khách hàng', () => _showSupportBottomSheet(context)),
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

  void _showSupportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headset_mic_rounded,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hỗ trợ khách hàng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Đội ngũ ShuttleCourt luôn đồng hành cùng bạn',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSupportActionTile(
                context,
                icon: Icons.phone_forwarded_rounded,
                title: 'Gọi Hotline hỗ trợ',
                subtitle: '0986049032',
                color: AppTheme.primary,
                onTap: () async {
                  final uri = Uri.parse('tel:0986049032');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    _showToast(context, 'Không thể thực hiện cuộc gọi trực tiếp.');
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildSupportActionTile(
                context,
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Liên hệ Zalo chăm sóc khách hàng',
                subtitle: 'Nhắn tin Zalo trực tiếp',
                color: const Color(0xFF0068FF),
                onTap: () async {
                  final uri = Uri.parse('https://zalo.me/0986049032');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    _showToast(context, 'Không thể kết nối Zalo.');
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildSupportActionTile(
                context,
                icon: Icons.copy_all_rounded,
                title: 'Sao chép số Hotline',
                subtitle: '0986049032',
                color: AppTheme.accent,
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: '0986049032'));
                  Navigator.pop(context);
                  _showToast(context, 'Đã sao chép Hotline: 0986049032');
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Giờ làm việc: 08:00 - 22:00 hàng ngày\nEmail: support@shuttlecourt.com',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppTheme.textPrimary,
      ),
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
