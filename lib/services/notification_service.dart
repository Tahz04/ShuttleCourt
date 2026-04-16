import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quynh/config/api_config.dart';

class SystemNotification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String type;
  final int? senderId;
  final int? relatedId;
  final DateTime createdAt;

  SystemNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.type,
    this.senderId,
    this.relatedId,
    required this.createdAt,
  });

  factory SystemNotification.fromJson(Map<String, dynamic> json) {
    return SystemNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] == 1,
      type: json['type'] ?? 'general',
      senderId: json['sender_id'],
      relatedId: json['related_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationService {
  static Future<List<SystemNotification>> getNotifications(String userId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.notificationsUrl}/$userId'));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => SystemNotification.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  static Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.notificationsUrl}/read/$notificationId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  static Future<bool> markAllAsRead(String userId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.notificationsUrl}/read-all/$userId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }
}
