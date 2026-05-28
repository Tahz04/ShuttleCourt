import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shuttlecourt/config/api_config.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:geocoding/geocoding.dart';

class EditCourtScreen extends StatefulWidget {
  final dynamic court;
  final bool isAdmin;
  const EditCourtScreen({super.key, required this.court, this.isAdmin = false});

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
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();
  
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
    // delay to wait for widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addressCtrl.text = widget.court['address'] ?? '';
      _latCtrl.text = widget.court['latitude']?.toString() ?? '0';
      _lngCtrl.text = widget.court['longitude']?.toString() ?? '0';
    });
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
        if (index == 0) {
          _mainLocalPath = file.path;
        } else if (index == 1) _descLocalPath1 = file.path;
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
          if (index == 0) {
            _mainImageUrl = data['imageUrl'];
          } else if (index == 1) _descImageUrl1 = data['imageUrl'];
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
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.primary), onPressed: () => Navigator.pop(context)),
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
              _buildModernInput(label: 'Địa chỉ', icon: Icons.location_on_rounded, controller: _addressCtrl, validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null, onSaved: (v) => _address = v!),
              Row(
                children: [
                  Expanded(child: _buildModernInput(label: 'Vĩ độ (Lat)', controller: _latCtrl, keyboardType: TextInputType.number, onSaved: (v) => _latitude = double.tryParse(v ?? '') ?? 0)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildModernInput(label: 'Kinh độ (Lng)', controller: _lngCtrl, keyboardType: TextInputType.number, onSaved: (v) => _longitude = double.tryParse(v ?? '') ?? 0)),
                ],
              ),
              TextButton.icon(
                onPressed: _getLocationFromAddress,
                icon: const Icon(Icons.travel_explore_rounded, color: AppTheme.accent, size: 20),
                label: const Text('Lấy tọa độ từ Địa chỉ đã nhập', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
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

  Widget _buildModernInput({required String label, IconData? icon, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator, required void Function(String?) onSaved, TextEditingController? controller}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines, keyboardType: keyboardType, validator: validator, onSaved: onSaved,
        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), prefixIcon: icon != null ? Icon(icon, color: AppTheme.primary, size: 18) : null, border: InputBorder.none, contentPadding: const EdgeInsets.all(18)),
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

  
  Future<void> _getLocationFromAddress() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      _showStatus('Vui lòng nhập địa chỉ trước!', isError: true);
      return;
    }
    setState(() => _isGlobalBusy = true);
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _latCtrl.text = locations.first.latitude.toString();
          _lngCtrl.text = locations.first.longitude.toString();
        });
        _showStatus('Đã lấy tọa độ thành công từ địa chỉ!');
      }
    } catch (e) {
      _showStatus('Không tìm thấy tọa độ cho địa chỉ này!', isError: true);
    } finally {
      setState(() => _isGlobalBusy = false);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isGlobalBusy = true);
      try {
        // Tự động tìm vị trí (lat, lng) từ địa chỉ thủ công
        try {
          List<Location> locations = await locationFromAddress(_address);
          if (locations.isNotEmpty) {
            _latitude = locations.first.latitude;
            _longitude = locations.first.longitude;
          }
        } catch (_) {
          // Bỏ qua nếu không tìm thấy, giữ nguyên giá trị cũ
        }

        await http.put(
          Uri.parse('${ApiConfig.courtsUrl}/update/${widget.court['id']}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': _name, 'address': _address, 'latitude': _latitude, 'longitude': _longitude,
            'price': _price, 'description': _description, 'main_image': _mainImageUrl,
            'desc_image1': _descImageUrl1, 'desc_image2': _descImageUrl2, 'status': _status,
            'isAdmin': widget.isAdmin,
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
