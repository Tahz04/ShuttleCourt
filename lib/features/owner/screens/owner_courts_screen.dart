import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:quynh/auth/auth_service.dart';
import 'package:quynh/config/api_config.dart';
import 'package:quynh/theme/app_theme.dart';

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
    // Vừa mở màn hình lên là gọi hàm tải dữ liệu ngay
    _fetchCourts();
  }

  // Hàm "hút" dữ liệu từ Backend
  Future<void> _fetchCourts() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user == null) {
      setState(() {
        _errorMessage = 'Lỗi: Chưa đăng nhập';
        _isLoading = false;
      });
      return;
    }

    final String apiUrl = '${ApiConfig.courtsUrl}/owner/${user.id}';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          _courts = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Lỗi tải dữ liệu từ Server';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Danh Sách Sân Của Tôi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Xử lý giao diện tùy theo trạng thái: Đang tải, Bị lỗi, hoặc Trống
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)))
          : _courts.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stadium_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Bạn chưa có sân nào.', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const Text('Hãy thêm sân mới để bắt đầu kinh doanh nhé!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
      // Vẽ danh sách sân nếu có dữ liệu
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _courts.length,
        itemBuilder: (context, index) {
          final court = _courts[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          court['name'] ?? 'Tên sân',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Đang hoạt động', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(court['address'] ?? '', style: TextStyle(color: Colors.grey[700]))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        '${court['price_per_hour']} VNĐ/Giờ',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}