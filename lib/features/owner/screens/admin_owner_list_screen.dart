import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quynh/config/api_config.dart';
import 'package:quynh/theme/app_theme.dart';

class AdminOwnerListScreen extends StatefulWidget {
  const AdminOwnerListScreen({super.key});

  @override
  State<AdminOwnerListScreen> createState() => _AdminOwnerListScreenState();
}

class _AdminOwnerListScreenState extends State<AdminOwnerListScreen> {
  late Future<List<dynamic>> _ownersFuture;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _ownersFuture = _fetchOwners();
  }

  Future<List<dynamic>> _fetchOwners() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.authUrl}/auth/get-owners')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        setState(() => _error = 'Lỗi Server (${response.statusCode})');
        return [];
      }
    } catch (e) {
      setState(() => _error = 'Lỗi kết nối: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Quản lý chủ sân', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _ownersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (_error.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
              ),
            );
          }
          final owners = snapshot.data ?? [];
          if (owners.isEmpty) {
            return const Center(child: Text('Chưa có chủ sân nào.', style: TextStyle(color: AppTheme.textMuted)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: owners.length,
            itemBuilder: (context, index) {
              final owner = owners[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(owner['fullName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(owner['email'], style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        'Sân: ${owner['courts'] ?? 'Chưa có sân'}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Partner', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
