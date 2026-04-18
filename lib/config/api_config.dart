import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Cấu hình API tập trung - Thay đổi IP ở đây khi đổi mạng
class ApiConfig {
  // ════════════════════════════════════════════════════════
  // 🔧 THAY ĐỔI IP Ở ĐÂY KHI ĐỔI MẠNG
  // ════════════════════════════════════════════════════════
  static const String serverIp = '10.121.66.20';
  static const int serverPort = 3000;

  // ════════════════════════════════════════════════════════
  // TỰ ĐỘNG CHỌN HOST THEO MÔI TRƯỜNG
  // ════════════════════════════════════════════════════════
  static String get baseUrl {
    // Sử dụng localhost cho Web và Windows Desktop khi chạy local
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://localhost:$serverPort/api';
    } else {
      // Android/iOS dùng IP thật để kết nối từ thiết bị/giả lập
      return 'http://$serverIp:$serverPort/api';
    }
  }

  // Quick URLs
  static String get courtsUrl => '$baseUrl/courts';
  static String get bookingsUrl => '$baseUrl/bookings';
  static String get matchmakingUrl => '$baseUrl/matchmaking';
  static String get ownerRequestsUrl => '$baseUrl/owner-requests';
  static String get productsUrl => '$baseUrl/products';
  static String get notificationsUrl => '$baseUrl/notifications';
  static String get authUrl => baseUrl;
  static String get uploadUrl => '$baseUrl/upload';

  // Raw base URL for static files (uploads)
  static String get rawBaseUrl {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://localhost:$serverPort';
    } else {
      return 'http://$serverIp:$serverPort';
    }
  }

  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
