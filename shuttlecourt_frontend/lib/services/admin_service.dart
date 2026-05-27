import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shuttlecourt/config/api_config.dart';

class AdminService {
  static String get ownerRequestsUrl => ApiConfig.ownerRequestsUrl;
  static String get adminUrl => '${ApiConfig.baseUrl}/admin';

  static Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final res = await http.get(Uri.parse('$adminUrl/dashboard-stats'));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) {
      print('Error getting stats: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getAllUsers() async {
    try {
      final res = await http.get(Uri.parse('$adminUrl/users'));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  static Future<bool> toggleUserLock(String userId) async {
    try {
      final res = await http.put(Uri.parse('$adminUrl/users/$userId/toggle-lock'));
      return res.statusCode == 200;
    } catch (e) {
      print('Error toggling user lock: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getAllOwnerRequests() async {
    try {
      final res = await http.get(Uri.parse('$ownerRequestsUrl/all'));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (e) {
      print('Error getting requests: $e');
      return [];
    }
  }

  static Future<bool> approveRequest(String requestId) async {
    try {
      final res = await http.put(Uri.parse('$ownerRequestsUrl/approve/$requestId'));
      return res.statusCode == 200;
    } catch (e) {
      print('Error approving request: $e');
      return false;
    }
  }

  static Future<bool> rejectRequest(String requestId, {String? reason}) async {
    try {
      final res = await http.put(
        Uri.parse('$ownerRequestsUrl/reject/$requestId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error rejecting request: $e');
      return false;
    }
  }
}
