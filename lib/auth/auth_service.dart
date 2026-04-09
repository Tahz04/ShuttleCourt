import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

class User {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    this.role = 'user',
  });
}

class AuthService extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  // --- SỬA LỖI DẤU CÁCH Ở ĐÂY ---
  final String _myIp = '10.121.66.20';

  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else {
      // Dùng IP máy tính cho cả máy ảo và máy thật
      return 'http://$_myIp:3000/api';
    }
  }

  // --- Đăng nhập ---
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Lưu ý: data['user']['fullName'] phải khớp với key Backend trả về
        _user = User(
          id: data['user']['id'].toString(),
          email: data['user']['email'],
          fullName: data['user']['fullName'] ?? data['user']['full_name'] ?? 'Người dùng',
          phone: data['user']['phone'] ?? '',
          role: data['user']['role'] ?? 'user',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Đăng nhập thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối server: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Đăng ký ---
  Future<bool> register(String email, String password, String fullName, String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Đăng ký thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối server';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Nâng cấp tài khoản (Chủ Sân) ---
  Future<bool> upgradeToOwner() async {
    if (_user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/upgrade-to-owner'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _user!.id,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Cập nhật lại quyền cục bộ để giao diện thay đổi ngay
        _user = User(
          id: _user!.id,
          email: _user!.email,
          fullName: _user!.fullName,
          phone: _user!.phone,
          role: 'owner',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Nâng cấp thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi hệ thống: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}