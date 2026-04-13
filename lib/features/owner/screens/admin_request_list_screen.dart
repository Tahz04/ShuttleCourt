import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quynh/config/api_config.dart';
import 'package:quynh/theme/app_theme.dart';

class AdminRequestListScreen extends StatefulWidget {
  const AdminRequestListScreen({super.key});

  @override
  State<AdminRequestListScreen> createState() => _AdminRequestListScreenState();
}

class _AdminRequestListScreenState extends State<AdminRequestListScreen> {
  late Future<List<dynamic>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _refreshRequests();
  }

  void _refreshRequests() {
    setState(() {
      _requestsFuture = _fetchRequests();
    });
  }

  Future<List<dynamic>> _fetchRequests() async {
    final response = await http.get(Uri.parse('${ApiConfig.ownerRequestsUrl}/all'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<void> _approveRequest(int requestId) async {
    final response = await http.put(Uri.parse('${ApiConfig.ownerRequestsUrl}/approve/$requestId'));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã phê duyệt đối tác thành công!'), backgroundColor: AppTheme.success));
      _refreshRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Lỗi khi phê duyệt.'), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Phê duyệt đối tác', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 60, color: AppTheme.success),
                  SizedBox(height: 16),
                  Text('Không có yêu cầu chờ xử lý.', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return _buildRequestCard(req);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(dynamic req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ExpansionTile(
        title: Text(req['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Sân: ${req['court_name']}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoLine('Email', req['email']),
                _buildInfoLine('Địa chỉ', req['court_address']),
                const SizedBox(height: 16),
                const Text('HỒ SƠ CCCD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildCCCDImage('Mặt trước', req['cccd_front'])),
                    const SizedBox(width: 8),
                    Expanded(child: _buildCCCDImage('Mặt sau', req['cccd_back'])),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Từ chối'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approveRequest(req['id']),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Phê duyệt'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(text: TextSpan(
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value),
        ],
      )),
    );
  }

  Widget _buildCCCDImage(String side, String? base64Data) {
    bool hasImage = base64Data != null && base64Data.startsWith('data:image');
    
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: hasImage 
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              base64Decode(base64Data.split(',').last),
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: AppTheme.error)),
            ),
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_search_rounded, color: AppTheme.textMuted, size: 24),
                Text(side, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
          ),
    );
  }
}
