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

  static Future<bool> requestJoin({
    required int userId,
    required int matchId,
    required int hostId,
    required String senderName,
    required String courtName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.matchmakingUrl}/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'matchId': matchId,
          'hostId': hostId,
          'senderName': senderName,
          'courtName': courtName,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error joining match: $e');
      return false;
    }
  }

  static Future<bool> respondToRequest({
    required int notificationId,
    required int requesterId,
    required int matchId,
    required String action,
    required String hostName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.matchmakingUrl}/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'notificationId': notificationId,
          'requesterId': requesterId,
          'matchId': matchId,
          'action': action,
          'hostName': hostName,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error responding to matchmaking request: $e');
      return false;
    }
  }

  static Future<List<MatchModel>> getUserMatches(int userId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.matchmakingUrl}/user/$userId'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MatchModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching user matches: $e');
      return [];
    }
  }
}
