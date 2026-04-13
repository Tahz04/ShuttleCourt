import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quynh/config/api_config.dart';
import 'package:quynh/models/match_model.dart';

class MatchmakingService {
  static Future<List<MatchModel>> getAllMatches() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.matchmakingUrl}/all'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MatchModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching matches: $e');
      return [];
    }
  }

  static Future<bool> createMatch({
    required int hostId,
    required String courtName,
    required String level,
    required String matchDate,
    required String startTime,
    required int capacity,
    required double price,
    String description = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.matchmakingUrl}/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hostId': hostId,
          'courtName': courtName,
          'level': level,
          'matchDate': matchDate,
          'startTime': startTime,
          'capacity': capacity,
          'price': price,
          'description': description,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error creating match: $e');
      return false;
    }
  }
}
