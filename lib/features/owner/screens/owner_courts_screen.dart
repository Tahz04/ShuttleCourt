import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:quynh/auth/auth_service.dart';
import 'package:quynh/config/api_config.dart';
import 'package:quynh/theme/app_theme.dart';
import 'package:quynh/features/owner/screens/edit_court_screen.dart';

class OwnerCourtsScreen extends StatefulWidget {
  const OwnerCourtsScreen({super.key});

  @override
  State<OwnerCourtsScreen> createState() => _OwnerCourtsScreenState();
}

class _OwnerCourtsScreenState extends State<OwnerCourtsScreen> {
  List<dynamic> _courts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCourts();
  }

  Future<void> _fetchCourts() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    if (user == null) {
      if(mounted) setState(() { _errorMessage = 'Lỗi: Chưa đăng nhập'; _isLoading = false; });
      return;
    }
    try {
      final response = await http.get(Uri.parse('${ApiConfig.courtsUrl}/owner/${user.id}'));
      if (response.statusCode == 200) {
        if(mounted) setState(() { _courts = jsonDecode(response.body); _isLoading = false; });
      } else {
        if(mounted) setState(() { _errorMessage = 'Lỗi tải dữ liệu'; _isLoading = false; });
      }
    } catch (e) {
      if(mounted) setState(() { _errorMessage = 'Lỗi kết nối'; _isLoading = false; });
    }
  }

  Future<void> _toggleMaintenance(dynamic court) async {
    final isCurrentlyMaintenance = court['status'] == 'maintenance';
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.courtsUrl}/maintenance/${court['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isMaintenance': !isCurrentlyMaintenance}),
      );
      if (response.statusCode == 200) {
        _fetchCourts();
      }
    } catch (e) {
      _showError('Lỗi cập nhật trạng thái');
    }
  }

  Future<void> _deleteCourt(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa sân này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(Uri.parse('${ApiConfig.courtsUrl}/delete/$id'));
        if (response.statusCode == 200) {
          _fetchCourts();
          _showError('Đã xóa sân thành công');
        }
      } catch (e) {
        _showError('Lỗi khi xóa sân');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Kho Sân Của Tôi', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary)),
        backgroundColor: AppTheme.scaffoldLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.primary),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCourts,
        color: AppTheme.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _errorMessage != null
                ? _buildErrorState()
                : _courts.isEmpty
                    ? _buildEmptyState()
                    : _buildCourtList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.stadium_rounded, size: 80, color: AppTheme.primary.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          const Text('Chưa có sân nào', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary)),
          const SizedBox(height: 8),
          const Text('Hãy thêm sân mới để bắt đầu kinh doanh nhé!', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          TextButton(onPressed: _fetchCourts, child: const Text('Thử lại', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildCourtList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      itemCount: _courts.length,
      itemBuilder: (context, index) => _buildCourtCard(_courts[index]),
    );
  }

  Widget _buildCourtCard(dynamic court) {
    final isMaintenance = court['status'] == 'maintenance';
    final mainImage = court['main_image'] ?? 'https://images.unsplash.com/photo-1599427303058-f04cbcf4753f?q=80&w=2070&auto=format&fit=crop';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(mainImage),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.6)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 16, right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isMaintenance ? Icons.warning_rounded : Icons.check_circle_rounded, 
                                 color: isMaintenance ? AppTheme.error : Colors.green, size: 14),
                            const SizedBox(width: 4),
                            Text(isMaintenance ? 'Bảo trì' : 'Đang hoạt động', 
                                 style: TextStyle(color: isMaintenance ? AppTheme.error : Colors.green, fontSize: 10, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16, left: 20,
                      child: Text(
                        court['name'] ?? 'Tên sân',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(court['address'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPriceTag(court['price_per_hour'].toString()),
                      Row(
                        children: [
                          _actionBtn(Icons.build_rounded, isMaintenance ? Colors.green.withOpacity(0.1) : AppTheme.error.withOpacity(0.1), 
                                     isMaintenance ? Colors.green : AppTheme.error, 
                                     () => _toggleMaintenance(court)),
                          const SizedBox(width: 8),
                          _actionBtn(Icons.edit_rounded, AppTheme.primary.withOpacity(0.05), AppTheme.primary, 
                                     () async {
                                       final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditCourtScreen(court: court)));
                                       if (res == true) _fetchCourts();
                                     }),
                          const SizedBox(width: 8),
                          _actionBtn(Icons.delete_outline_rounded, AppTheme.error.withOpacity(0.05), AppTheme.error, 
                                     () => _deleteCourt(court['id'])),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTag(String price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Giá thuê', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        Text(
          '${double.tryParse(price)?.toInt().toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}đ',
          style: const TextStyle(color: AppTheme.accent, fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}