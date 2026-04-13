import 'package:flutter/material.dart';
import 'package:quynh/theme/app_theme.dart';
import 'admin_request_list_screen.dart';
import 'admin_owner_list_screen.dart';
import 'admin_booking_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('QUẢN TRỊ HỆ THỐNG', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminHero(),
            const SizedBox(height: 28),
            const Text('DANH MỤC QUẢN LÝ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildMenuCard(
                  context,
                  'Quản lý yêu cầu',
                  'Phê duyệt đối tác mới',
                  Icons.how_to_reg_rounded,
                  AppTheme.primaryGradient,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRequestListScreen())),
                ),
                _buildMenuCard(
                  context,
                  'Quản lý chủ sân',
                  'Danh sách các đối tác',
                  Icons.badge_rounded,
                  AppTheme.matchmakingGradient,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOwnerListScreen())),
                ),
                _buildMenuCard(
                  context,
                  'Quản lý lịch đặt',
                  'Tất cả lịch trên hệ thống',
                  Icons.event_note_rounded,
                  AppTheme.warmGradient,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBookingListScreen())),
                ),
                _buildMenuCard(
                  context,
                  'Quản lý thanh toán',
                  'Doanh thu & giao dịch',
                  Icons.payments_rounded,
                  const LinearGradient(colors: [Color(0xFF00B0FF), Color(0xFF0081CB)]),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBookingListScreen())), // Shared view for now
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 42),
          SizedBox(height: 12),
          Text('Xin chào, Admin', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          Text('Chào mừng bạn quay lại bảng điều khiển.', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String sub, IconData icon, Gradient grad, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tính năng $feature sắp ra mắt!'), backgroundColor: AppTheme.accent),
    );
  }
}
