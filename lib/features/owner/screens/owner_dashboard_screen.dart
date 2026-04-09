import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quynh/auth/auth_service.dart';
import 'package:quynh/features/owner/screens/add_court_screen.dart';
import 'package:quynh/features/owner/screens/owner_courts_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Bảng Quản Lý Chủ Sân', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lời chào Chủ sân
            Text(
              'Xin chào, ${user?.fullName ?? 'Chủ sân'}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
            ),
            const SizedBox(height: 4),
            const Text('Hôm nay sân của bạn hoạt động thế nào?', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // Các thẻ Thống kê nhanh
            Row(
              children: [
                Expanded(child: _buildStatCard('Doanh thu tháng', '0đ', Icons.attach_money, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Lịch chờ duyệt', '0', Icons.pending_actions, Colors.orange)),
              ],
            ),
            const SizedBox(height: 24),

            // Menu Quản lý
            const Text('Công cụ quản lý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _buildMenuOption(
              context,
              icon: Icons.add_business,
              title: 'Thêm Sân Mới',
              subtitle: 'Đăng thông tin sân cầu lông của bạn lên hệ thống',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddCourtScreen())
                );
              },
            ),

            _buildMenuOption(
              context,
              icon: Icons.stadium,
              title: 'Danh sách Sân của bạn',
              subtitle: 'Chỉnh sửa giá, cập nhật trạng thái hoạt động',
              color: Colors.purple,
              onTap: () {
                // ĐÃ SỬA: Chuyển hướng sang màn hình Danh Sách Sân
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OwnerCourtsScreen()),
                );
              },
            ),

            _buildMenuOption(
              context,
              icon: Icons.calendar_month,
              title: 'Quản lý Lịch Đặt',
              subtitle: 'Xem và Duyệt/Từ chối khách đặt sân',
              color: Colors.teal,
              onTap: () {
                // TODO: Chuyển hướng sang trang Quản lý Lịch Đặt
              },
            ),

            _buildMenuOption(
              context,
              icon: Icons.star_rate,
              title: 'Đánh giá từ khách hàng',
              subtitle: 'Xem các bình luận và điểm sao',
              color: Colors.amber,
              onTap: () {
                // TODO: Xem đánh giá
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget vẽ thẻ thống kê
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  // Widget vẽ menu chức năng
  Widget _buildMenuOption(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}