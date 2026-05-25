import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shuttlecourt/config/api_config.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:intl/intl.dart';

class OwnerOrderManagementScreen extends StatefulWidget {
  const OwnerOrderManagementScreen({super.key});

  @override
  State<OwnerOrderManagementScreen> createState() => _OwnerOrderManagementScreenState();
}

class _OwnerOrderManagementScreenState extends State<OwnerOrderManagementScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(ApiConfig.productsUrl + '/orders'));
      if (response.statusCode == 200) {
        setState(() {
          _orders = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.productsUrl + '/orders/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      if (response.statusCode == 200) {
        _loadOrders();
      }
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('QUẢN LÝ ĐƠN HÀNG', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _orders.isEmpty
            ? const Center(child: Text('Chưa có đơn hàng nào.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final status = order['status'] ?? 'pending';
                  final statusText = status == 'pending' ? 'Đang chờ' : (status == 'completed' ? 'Đã giao' : 'Đã hủy');
                  final statusColor = status == 'pending' ? Colors.orange : (status == 'completed' ? AppTheme.success : AppTheme.error);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('HH:mm - dd/MM').format(DateTime.parse(order['created_at'])), 
                                 style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                statusText,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(order['full_name'] ?? 'Khách lẻ', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(order['phone'] ?? 'Không có SĐT', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(order['items'] ?? 'Sản phẩm', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                        const Divider(height: 24),
                        
                        // NEW DETAILS
                        _buildDetailRow(Icons.location_on_outlined, 'Địa chỉ:', order['address'] ?? 'Tại cửa hàng'),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.payments_outlined, 'Thanh toán:', order['payment_method'] ?? 'Tiền mặt'),
                        
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                            Text(_currencyFormat.format(double.tryParse(order['total_price'].toString()) ?? 0), 
                                 style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (status == 'pending')
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _updateStatus(order['id'], 'cancelled'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppTheme.error),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Hủy đơn', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _updateStatus(order['id'], 'completed'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMuted)),
        const SizedBox(width: 4),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
      ],
    );
  }
}
