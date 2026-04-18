import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:quynh/config/api_config.dart';
import 'package:quynh/theme/app_theme.dart';

class EditCourtScreen extends StatefulWidget {
  final dynamic court;
  const EditCourtScreen({super.key, required this.court});

  @override
  State<EditCourtScreen> createState() => _EditCourtScreenState();
}

class _EditCourtScreenState extends State<EditCourtScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isGlobalBusy = false;
  final List<bool> _isUploading = [false, false, false];

  late String _name;
  late String _address;
  late double _latitude;
  late double _longitude;
  late double _price;
  late String _description;
  
  String? _mainImageUrl;
  String? _descImageUrl1;
  String? _descImageUrl2;
  
  String? _mainLocalPath;
  String? _descLocalPath1;
  String? _descLocalPath2;

  late String _status;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final c = widget.court;
    _name = c['name'] ?? '';
    _address = c['address'] ?? '';
    _latitude = double.tryParse(c['latitude']?.toString() ?? '0') ?? 0.0;
    _longitude = double.tryParse(c['longitude']?.toString() ?? '0') ?? 0.0;
    _price = double.tryParse(c['price_per_hour']?.toString() ?? '0') ?? 0.0;
    _description = c['description'] ?? '';
    _mainImageUrl = c['main_image'];
    _descImageUrl1 = c['desc_image1'];
    _descImageUrl2 = c['desc_image2'];
    _status = c['status'] ?? 'active';
  }

  Future<void> _handleImageSelection(int index) async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (file == null) return;

      setState(() {
        if (index == 0) _mainLocalPath = file.path;
        else if (index == 1) _descLocalPath1 = file.path;
        else if (index == 2) _descLocalPath2 = file.path;
        _isUploading[index] = true;
      });

      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadUrl));
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (index == 0) _mainImageUrl = data['imageUrl'];
          else if (index == 1) _descImageUrl1 = data['imageUrl'];
          else if (index == 2) _descImageUrl2 = data['imageUrl'];
        });
      }
    } catch (e) {
      _showStatus('Lỗi tải ảnh!', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading[index] = false);
    }
  }

  void _showStatus(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppTheme.error : AppTheme.primary, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Chỉnh Sửa Sân', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary)),
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildSectionHeader('HÌNH ẢNH SÂN'),
              const SizedBox(height: 20),
              _buildLargePicker(),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSmallPicker(1, 'Mô tả 1', _descImageUrl1, _descLocalPath1),
                  const SizedBox(width: 16),
                  _buildSmallPicker(2, 'Mô tả 2', _descImageUrl2, _descLocalPath2),
                ],
              ),
              const SizedBox(height: 40),
              _buildSectionHeader('THÔNG TIN CHI TIẾT'),
              const SizedBox(height: 20),
              _buildInput(label: 'Tên sân', initial: _name, onSaved: (v) => _name = v!),
              _buildInput(label: 'Địa chỉ', initial: _address, onSaved: (v) => _address = v!),
              _buildInput(label: 'Giá thuê', initial: _price.toInt().toString(), onSaved: (v) => _price = double.tryParse(v!) ?? 0),
              const SizedBox(height: 48),
              _buildSubmit(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)), child: Text(title, style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w900)));
  }

  Widget _buildLargePicker() {
    bool loading = _isUploading[0];
    bool hasImage = _mainImageUrl != null || _mainLocalPath != null;
    return GestureDetector(
      onTap: loading ? null : () => _handleImageSelection(0),
      child: Container(
        height: 180, width: double.infinity,
        decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(24), border: Border.all(color: hasImage ? AppTheme.primary : AppTheme.borderLight)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(alignment: Alignment.center, children: [
            if (_mainLocalPath != null) Image.file(File(_mainLocalPath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            if (_mainImageUrl != null && _mainLocalPath == null) Image.network(_mainImageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            if (!hasImage && !loading) const Icon(Icons.add_a_photo, color: AppTheme.primary, size: 32),
            if (loading) Container(color: Colors.black26, child: const CircularProgressIndicator(color: Colors.white)),
            if (hasImage && !loading) const Positioned(bottom: 12, right: 12, child: Icon(Icons.check_circle, color: Colors.green, size: 24)),
          ]),
        ),
      ),
    );
  }

  Widget _buildSmallPicker(int index, String label, String? url, String? localPath) {
    bool loading = _isUploading[index];
    bool hasImage = url != null || localPath != null;
    return Expanded(
      child: GestureDetector(
        onTap: loading ? null : () => _handleImageSelection(index),
        child: Container(
          height: 120, decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: hasImage ? AppTheme.primary : AppTheme.borderLight)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(alignment: Alignment.center, children: [
              if (localPath != null) Image.file(File(localPath), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              if (url != null && localPath == null) Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              if (!hasImage && !loading) Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              if (loading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
              if (hasImage && !loading) const Positioned(bottom: 8, right: 8, child: Icon(Icons.check_circle, color: Colors.green, size: 18)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({required String label, String? initial, void Function(String?)? onSaved}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
      child: TextFormField(
        initialValue: initial, onSaved: onSaved,
        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), border: InputBorder.none, contentPadding: const EdgeInsets.all(18)),
      ),
    );
  }

  Widget _buildSubmit() {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.premiumShadow),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        onPressed: _isGlobalBusy ? null : _submit,
        child: _isGlobalBusy ? const CircularProgressIndicator(color: Colors.white) : const Text('LƯU THAY ĐỔI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isGlobalBusy = true);
      try {
        await http.put(
          Uri.parse('${ApiConfig.courtsUrl}/update/${widget.court['id']}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': _name, 'address': _address, 'latitude': _latitude, 'longitude': _longitude,
            'price': _price, 'description': _description, 'main_image': _mainImageUrl,
            'desc_image1': _descImageUrl1, 'desc_image2': _descImageUrl2, 'status': _status,
          }),
        );
        Navigator.pop(context, true);
      } catch (e) {
        _showStatus('Lỗi: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isGlobalBusy = false);
      }
    }
  }
}
