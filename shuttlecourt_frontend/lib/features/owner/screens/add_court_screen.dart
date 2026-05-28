import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/config/api_config.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/utils/geocoding_helper.dart';
import 'package:geolocator/geolocator.dart';

class AddCourtScreen extends StatefulWidget {
  const AddCourtScreen({super.key});

  @override
  State<AddCourtScreen> createState() => _AddCourtScreenState();
}

class _AddCourtScreenState extends State<AddCourtScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isGlobalBusy = false;
  final List<bool> _isUploading = [false, false, false];

  String _name = '';
  String _address = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  double _price = 0;
  final String _description = '';
  
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();
  
  // Storage for server URLs
  String? _mainImageUrl;
  String? _descImageUrl1;
  String? _descImageUrl2;

  List<dynamic> _addressSuggestions = [];
  Timer? _debounceTimer;

  void _onAddressChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      final query = value.trim();
      if (query.length < 3) {
        setState(() => _addressSuggestions = []);
        return;
      }
      try {
        final uri = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1');
        final response = await http.get(uri, headers: {
          'User-Agent': 'ShuttleCourtApp/1.0',
        });
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _addressSuggestions = data;
            });
          }
        }
      } catch (e) {
        print('Error fetching address suggestions: $e');
      }
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Storage for local paths for instant preview
  String? _mainLocalPath;
  String? _descLocalPath1;
  String? _descLocalPath2;

  final ImagePicker _picker = ImagePicker();

  Future<void> _handleImageSelection(int index) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Lower quality for faster upload
      );
      
      if (file == null) return;

      // Show local image immediately
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
        final String? serverUrl = data['imageUrl'];
        
        if (serverUrl != null) {
          setState(() {
            if (index == 0) {
              _mainImageUrl = serverUrl;
            } else if (index == 1) _descImageUrl1 = serverUrl;
            else if (index == 2) _descImageUrl2 = serverUrl;
          });
          debugPrint('✅ Uploaded: $serverUrl');
        }
      } else {
        _showStatus('Lỗi tải ảnh (${response.statusCode})', isError: true);
      }
    } catch (e) {
      debugPrint('❌ Upload Error: $e');
      _showStatus('Lỗi kết nối server!', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading[index] = false);
    }
  }

  void _showStatus(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? AppTheme.error : AppTheme.primary, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Đăng Ký Sân Mới', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary)),
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
              _buildSectionHeader('BƯỚC 1: HÌNH ẢNH'),
              const SizedBox(height: 20),
              
              _buildFeaturedPicker(),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  _buildGalleryPicker(1, 'Góc 1', _descImageUrl1, _descLocalPath1),
                  const SizedBox(width: 16),
                  _buildGalleryPicker(2, 'Góc 2', _descImageUrl2, _descLocalPath2),
                ],
              ),
              
              const SizedBox(height: 40),
              _buildSectionHeader('BƯỚC 2: THÔNG TIN'),
              const SizedBox(height: 20),
              _buildModernInput(label: 'Tên sân', icon: Icons.sports_tennis_rounded, validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null, onSaved: (v) => _name = v!),
              const SizedBox(height: 16),
              _buildModernInput(
                label: 'Địa chỉ',
                icon: Icons.location_on_rounded,
                controller: _addressCtrl,
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                onSaved: (v) => _address = v!,
                onChanged: _onAddressChanged,
              ),
              if (_addressSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _addressSuggestions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderLight),
                    itemBuilder: (context, index) {
                      final item = _addressSuggestions[index];
                      final displayName = item['display_name'] ?? '';
                      return ListTile(
                        leading: const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 20),
                        title: Text(
                          displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        ),
                        onTap: () {
                          setState(() {
                            _addressCtrl.text = displayName;
                            _address = displayName;
                            _latCtrl.text = item['lat'] ?? '';
                            _lngCtrl.text = item['lon'] ?? '';
                            _latitude = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
                            _longitude = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
                            _addressSuggestions = [];
                          });
                          _showStatus('Đã lấy tọa độ từ địa điểm được chọn!');
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildModernInput(label: 'Vĩ độ (Lat)', controller: _latCtrl, keyboardType: TextInputType.number, onSaved: (v) => _latitude = double.tryParse(v ?? '') ?? 0)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildModernInput(label: 'Kinh độ (Lng)', controller: _lngCtrl, keyboardType: TextInputType.number, onSaved: (v) => _longitude = double.tryParse(v ?? '') ?? 0)),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _getLocationFromAddress,
                icon: const Icon(Icons.travel_explore_rounded, color: AppTheme.accent, size: 20),
                label: const Text('Lấy tọa độ từ Địa chỉ đã nhập', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              _buildModernInput(label: 'Giá mỗi giờ', icon: Icons.payments_rounded, keyboardType: TextInputType.number, onSaved: (v) => _price = double.tryParse(v!) ?? 0),
              
              const SizedBox(height: 48),
              _buildPremiumSubmit(),
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

  Widget _buildFeaturedPicker() {
    bool loading = _isUploading[0];
    bool hasImage = _mainImageUrl != null || _mainLocalPath != null;
    
    return GestureDetector(
      onTap: loading ? null : () => _handleImageSelection(0),
      child: Container(
        height: 180, width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: hasImage ? AppTheme.primary : AppTheme.borderLight, width: hasImage ? 2 : 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_mainLocalPath != null) 
                Image.file(File(_mainLocalPath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              if (_mainImageUrl != null && _mainLocalPath == null)
                Image.network(_mainImageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              
              if (!hasImage && !loading)
                const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: AppTheme.primary, size: 32), SizedBox(height: 8), Text('ẢNH CHÍNH', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))]),
              
              if (loading) Container(color: Colors.black26, child: const CircularProgressIndicator(color: Colors.white)),
              if (hasImage && !loading) 
                Positioned(bottom: 12, right: 12, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 16))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryPicker(int index, String label, String? url, String? localPath) {
    bool loading = _isUploading[index];
    bool hasImage = url != null || localPath != null;
    
    return Expanded(
      child: GestureDetector(
        onTap: loading ? null : () => _handleImageSelection(index),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: hasImage ? AppTheme.primary : AppTheme.borderLight),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (localPath != null) Image.file(File(localPath), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                if (url != null && localPath == null) Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                
                if (!hasImage && !loading) Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                if (loading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                if (hasImage && !loading) const Positioned(bottom: 8, right: 8, child: Icon(Icons.check_circle, color: Colors.green, size: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInput({required String label, IconData? icon, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator, required void Function(String?) onSaved, TextEditingController? controller, ValueChanged<String>? onChanged}) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
      child: TextFormField(
        controller: controller, maxLines: maxLines, keyboardType: keyboardType, validator: validator, onSaved: onSaved, onChanged: onChanged,
        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), prefixIcon: icon != null ? Icon(icon, color: AppTheme.primary, size: 18) : null, border: InputBorder.none, contentPadding: const EdgeInsets.all(18)),
      ),
    );
  }

  Widget _buildPremiumSubmit() {
    return Container(
      width: double.infinity, height: 64,
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.premiumShadow),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        onPressed: _isGlobalBusy ? null : _submit,
        child: _isGlobalBusy ? const CircularProgressIndicator(color: Colors.white) : const Text('HOÀN TẤT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
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
      if (_mainImageUrl == null) { _showStatus('Vui lòng đợi ảnh tải lên xong!', isError: true); return; }
      setState(() => _isGlobalBusy = true);
      final auth = Provider.of<AuthService>(context, listen: false);
      try {
        // Tự động tìm vị trí (lat, lng) từ địa chỉ thủ công
        try {
          if (_latitude == 0.0 && _longitude == 0.0) {
            List<Location> locations = await locationFromAddress(_address);
            if (locations.isNotEmpty) {
              _latitude = locations.first.latitude;
              _longitude = locations.first.longitude;
            }
          }
        } catch (_) {
          // Bỏ qua nếu không tìm thấy, giữ nguyên giá trị cũ (0.0 hoặc mặc định)
        }

        final response = await http.post(
          Uri.parse('${ApiConfig.courtsUrl}/add'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'ownerId': auth.user!.id, 'name': _name, 'address': _address, 'latitude': _latitude, 'longitude': _longitude,
            'price': _price, 'description': _description, 'main_image': _mainImageUrl, 'desc_image1': _descImageUrl1, 'desc_image2': _descImageUrl2,
          }),
        );
        if (response.statusCode == 201) Navigator.pop(context, true);
      } catch (e) { _showStatus('Lỗi: $e', isError: true); } finally { if (mounted) setState(() => _isGlobalBusy = false); }
    }
  }
}