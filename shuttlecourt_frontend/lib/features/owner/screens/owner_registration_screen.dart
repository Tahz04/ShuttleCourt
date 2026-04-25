import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/config/api_config.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

class OwnerRegistrationScreen extends StatefulWidget {
  const OwnerRegistrationScreen({super.key});

  @override
  State<OwnerRegistrationScreen> createState() => _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends State<OwnerRegistrationScreen> {
  final _courtNameController = TextEditingController();
  final _courtAddressController = TextEditingController();
  bool _isLoading = false;
  
  XFile? _imageFront;
  XFile? _imageBack;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isFront) {
          _imageFront = image;
        } else {
          _imageBack = image;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đăng ký Đối tác', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('THÔNG TIN SÂN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            _buildTextField('Tên sân', _courtNameController, Icons.business_rounded),
            const SizedBox(height: 16),
            _buildTextField('Địa điểm', _courtAddressController, Icons.location_on_rounded),
            const SizedBox(height: 32),
            const Text('HỒ SƠ XÁC MINH (CCCD)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildUploadBox('Mặt trước CCCD', _imageFront, () => _pickImage(true))),
                const SizedBox(width: 16),
                Expanded(child: _buildUploadBox('Mặt sau CCCD', _imageBack, () => _pickImage(false))),
              ],
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _submitRequest(auth.user?.id),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('GỬI YÊU CẦU ĐĂNG KÝ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Lưu ý: Hệ thống chỉ cho phép duy nhất 1 người làm chủ sân.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildUploadBox(String label, XFile? image, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: image != null ? AppTheme.primary : Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: image != null 
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb 
                ? Image.network(image.path, fit: BoxFit.cover, width: double.infinity) 
                : Image.file(File(image.path), fit: BoxFit.cover, width: double.infinity),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_a_photo_outlined, color: AppTheme.primary),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
      ),
    );
  }

  Future<void> _submitRequest(String? userId) async {
    if (userId == null) return;
    if (_courtNameController.text.isEmpty || _courtAddressController.text.isEmpty || _imageFront == null || _imageBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin và chọn ảnh CCCD.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Chuyển ảnh sang Base64 để gửi qua API JSON
      final bytesFront = await _imageFront!.readAsBytes();
      final bytesBack = await _imageBack!.readAsBytes();
      final base64Front = base64Encode(bytesFront);
      final base64Back = base64Encode(bytesBack);

      final response = await http.post(
        Uri.parse(ApiConfig.ownerRequestsUrl + '/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'courtName': _courtNameController.text,
          'courtAddress': _courtAddressController.text,
          'cccdFront': 'data:image/png;base64,$base64Front',
          'cccdBack': 'data:image/png;base64,$base64Back',
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Chúc mừng! Bạn đã trở thành chủ sân duy nhất.'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gửi yêu cầu thất bại');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: AppTheme.error));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
