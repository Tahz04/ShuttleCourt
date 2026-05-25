import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shuttlecourt/config/api_config.dart';
import 'package:shuttlecourt/models/badminton_court.dart';

class CourtService {
  static Future<List<BadmintonCourt>> getAllCourts() async {
    try {
      final url = '${ApiConfig.courtsUrl}/all';
      print('🔵 Fetching courts from: $url');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      print('🟡 API Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Courts from API: ${data.length} records');
        return data
            .map(
              (json) => BadmintonCourt(
                id: json['id'].toString(),
                name: json['name'] ?? 'Sân Cầu Lông',
                address: json['address'] ?? '',
                latitude:
                    double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
                longitude:
                    double.tryParse(json['longitude']?.toString() ?? '0') ??
                    0.0,
                pricePerHour:
                    double.tryParse(
                      json['price_per_hour']?.toString() ?? '0',
                    ) ??
                    0.0,
                phone: json['phone'] ?? '',
                rating: 4.5,
                reviews: 12,
                amenities: ['Wifi', 'Gửi xe'],
              ),
            )
            .toList();
      }
      print('⚠️ API returned ${response.statusCode}, using sample data');
      return sampleBadmintonCourts;
    } catch (e) {
      print('❌ Error fetching courts: $e');
      return sampleBadmintonCourts;
    }
  }
}
