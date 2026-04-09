import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:quynh/auth/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Thêm thư viện nhận diện Web/App

class AddCourtScreen extends StatefulWidget {
  const AddCourtScreen({super.key});

  @override
  State<AddCourtScreen> createState() => _AddCourtScreenState();
}

class _AddCourtScreenState extends State<AddCourtScreen> {
  final _formKey = GlobalKey<FormState>();

  // Các biến để hứng dữ liệu
  String _name = '';
  String _address = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  double _price = 0;
  String _description = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thêm Sân Cầu Lông', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin cơ bản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(height: 16),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Tên sân cầu lông',
                  prefixIcon: const Icon(Icons.sports_tennis),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên sân' : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Địa chỉ (Chữ)',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                onSaved: (value) => _address = value!,
              ),
              const SizedBox(height: 16),

              // --- HAI Ô NHẬP TỌA ĐỘ ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Vĩ độ (Latitude)',
                        hintText: 'VD: 10.776...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onSaved: (value) => _latitude = double.tryParse(value ?? '') ?? 0.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Kinh độ (Longitude)',
                        hintText: 'VD: 106.669...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onSaved: (value) => _longitude = double.tryParse(value ?? '') ?? 0.0,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: Text('Mẹo: Bạn có thể lấy tọa độ này trên Google Maps.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
              // ---------------------------------------------

              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Giá thuê mỗi giờ (VNĐ)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập giá thuê' : null,
                onSaved: (value) => _price = double.tryParse(value!) ?? 0,
              ),
              const SizedBox(height: 16),

              TextFormField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả thêm (Không bắt buộc)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  // --- ĐÃ SỬA: GỌI API THỰC TẾ ---
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      // 1. Lấy thông tin User hiện tại từ Provider
                      final authService = Provider.of<AuthService>(context, listen: false);
                      final user = authService.user;

                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Chưa đăng nhập')));
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang lưu thông tin sân...')));

                      try {
                        // 2. Tự động lấy URL chuẩn (Web dùng localhost, App dùng IP)
                        final String myIp = '10.121.66.20';
                        final String apiUrl = kIsWeb
                            ? 'http://localhost:3000/api/courts/add'
                            : 'http://$myIp:3000/api/courts/add';

                        // 3. Gửi dữ liệu xuống Server Node.js
                        final response = await http.post(
                          Uri.parse(apiUrl),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'ownerId': user.id,
                            'name': _name,
                            'address': _address,
                            'latitude': _latitude,
                            'longitude': _longitude,
                            'price': _price,
                            'description': _description,
                          }),
                        );

                        // 4. Xử lý phản hồi từ Server
                        if (response.statusCode == 201) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Thêm sân thành công!')));
                          // Đóng màn hình này, quay lại Bảng quản lý
                          if (mounted) Navigator.pop(context);
                        } else {
                          final data = jsonDecode(response.body);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Lỗi: ${data['message']}')));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
                      }
                    }
                  },
                  child: const Text('ĐĂNG KÝ SÂN LÊN HỆ THỐNG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}