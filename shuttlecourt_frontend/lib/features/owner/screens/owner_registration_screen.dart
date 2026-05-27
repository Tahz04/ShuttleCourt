import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/config/api_config.dart';
import 'package:shuttlecourt/theme/app_theme.dart';

class OwnerRegistrationScreen extends StatefulWidget {
  const OwnerRegistrationScreen({super.key});

  @override
  State<OwnerRegistrationScreen> createState() => _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends State<OwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isBusy = false;
  
  String _fullName = '';
  String _idNumber = '';
  
  String? _cccdFrontUrl;
  String? _cccdBackUrl;
  
  String? _cccdFrontLocal;
  String? _cccdBackLocal;
  
  bool _isUploadingFront = false;
  bool _isUploadingBack = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (file == null) return;

      setState(() {
        if (isFront) {
          _cccdFrontLocal = file.path;
          _isUploadingFront = true;
        } else {
          _cccdBackLocal = file.path;
          _isUploadingBack = true;
        }
      });

      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadUrl));
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (isFront) _cccdFrontUrl = data['imageUrl'];
          else _cccdBackUrl = data['imageUrl'];
        });
      } else {
        _showError('Lỗi tải ảnh lên máy chủ');
      }
    } catch (e) {
      _showError('Lỗi kết nối');
    } finally {
      setState(() {
        if (isFront) _isUploadingFront = false;
        else _isUploadingBack = false;
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.error));
  }
  
  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    if (_cccdFrontUrl == null || _cccdBackUrl == null) {
      _showError('Vui lòng tải lên mặt trước và mặt sau CCCD');
      return;
    }
    
    setState(() => _isBusy = true);
    final user = Provider.of<AuthService>(context, listen: false).user;
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.ownerRequestsUrl}/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user!.id,
          'fullName': _fullName,
          'idNumber': _idNumber,
          'cccdFront': _cccdFrontUrl,
          'cccdBack': _cccdBackUrl,
        }),
      );
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        _showSuccess(data['message'] ?? 'Gửi yêu cầu thành công!');
        Navigator.pop(context);
      } else {
        _showError(data['message'] ?? 'Lỗi gửi yêu cầu');
      }
    } catch (e) {
      _showError('Lỗi máy chủ');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Trở thành Chủ Sân', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.primary), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.primary),
                    SizedBox(width: 12),
                    Expanded(child: Text('Vui lòng cung cấp thông tin sân và CCCD để quản trị viên xác thực hồ sơ của bạn.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('THÔNG TIN CÁ NHÂN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
              const SizedBox(height: 12),
              _buildInput(label: 'Họ và tên (như trên CCCD)', icon: Icons.person_rounded, onSaved: (v) => _fullName = v!),
              _buildInput(label: 'Số CCCD / CMND', icon: Icons.badge_rounded, onSaved: (v) => _idNumber = v!),
              
              const SizedBox(height: 24),
              const Text('CĂN CƯỚC CÔNG DÂN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildImagePicker(true, 'Mặt trước', _cccdFrontLocal, _cccdFrontUrl, _isUploadingFront),
                  const SizedBox(width: 16),
                  _buildImagePicker(false, 'Mặt sau', _cccdBackLocal, _cccdBackUrl, _isUploadingBack),
                ],
              ),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _isBusy ? null : _submitRequest,
                  child: _isBusy 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GỬI YÊU CẦU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({required String label, required IconData icon, required void Function(String?) onSaved}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
      child: TextFormField(
        onSaved: onSaved,
        validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          border: InputBorder.none, contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildImagePicker(bool isFront, String label, String? localPath, String? url, bool isUploading) {
    bool hasImage = localPath != null || url != null;
    return Expanded(
      child: GestureDetector(
        onTap: isUploading ? null : () => _pickImage(isFront),
        child: Container(
          height: 120,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: hasImage ? AppTheme.primary : AppTheme.borderLight)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (localPath != null) Image.file(File(localPath), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                if (url != null && localPath == null) Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                if (!hasImage && !isUploading) Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_rounded, color: AppTheme.textMuted), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold))]),
                if (isUploading) const CircularProgressIndicator(color: AppTheme.primary),
                if (hasImage && !isUploading) const Positioned(bottom: 8, right: 8, child: Icon(Icons.check_circle, color: Colors.green, size: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
