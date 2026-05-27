import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/config/api_config.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:intl/intl.dart';

class UserOrderHistoryScreen extends StatefulWidget {
  const UserOrderHistoryScreen({super.key});

  @override
  State<UserOrderHistoryScreen> createState() => _UserOrderHistoryScreenState();
}

class _UserOrderHistoryScreenState extends State<UserOrderHistoryScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyOrders();
  }

  Future<void> _fetchMyOrders() async {
    final userId = Provider.of<AuthService>(context, listen: false).user?.id;
    if (userId == null) return;
    
    try {
      final response = await http.get(Uri.parse('${ApiConfig.productsUrl}/orders/user/$userId'));
      if (response.statusCode == 200) {
        setState(() {
          _orders = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi fetch đơn hàng: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('LỊCH SỬ MUA HÀNG', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _orders.isEmpty
              ? _buildEmptyState()
              : _buildOrderList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: AppTheme.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Bạn chưa mua món hàng nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Vào Shop để tìm đồ nghề phù hợp nhé!', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return RefreshIndicator(
      onRefresh: _fetchMyOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          final dt = DateTime.parse(order['created_at']).toLocal();
          final formattedDate = DateFormat('dd/MM/yyyy - HH:mm').format(dt);

          Color statusColor;
          IconData statusIcon;
          if (order['status'] == 'Chờ xử lý') {
            statusColor = AppTheme.highlight;
            statusIcon = Icons.hourglass_empty_rounded;
          } else if (order['status'] == 'Đã duyệt' || order['status'] == 'Đang giao') {
            statusColor = AppTheme.primary;
            statusIcon = Icons.local_shipping_rounded;
          } else if (order['status'] == 'Đã giao' || order['status'] == 'Hoàn thành') {
            statusColor = Colors.green;
            statusIcon = Icons.check_circle_rounded;
          } else {
            statusColor = AppTheme.error;
            statusIcon = Icons.cancel_rounded;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mã ĐH: #${order['id']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(order['status'] ?? 'Chờ xử lý', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(Icons.shopping_basket_rounded, 'Mặt hàng:', order['items'] ?? ''),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_rounded, 'Giao đến:', order['address'] ?? ''),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.payment_rounded, 'Thanh toán:', order['payment_method'] ?? ''),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time_rounded, 'Thời gian đặt:', formattedDate),
                
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TỔNG TIỀN', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    Text('${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(double.tryParse(order['total_price'].toString()) ?? 0.0)}', 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.accent)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
              children: [
                TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
