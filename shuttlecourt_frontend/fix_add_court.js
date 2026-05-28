const fs = require('fs');
let c = fs.readFileSync('lib/features/owner/screens/add_court_screen.dart', 'utf8');

c = c.replace("import 'package:geocoding/geocoding.dart';", "import 'package:geocoding/geocoding.dart';\nimport 'package:geolocator/geolocator.dart';");

c = c.replace("final String _description = '';", "final String _description = '';\n  \n  final TextEditingController _addressCtrl = TextEditingController();\n  final TextEditingController _latCtrl = TextEditingController();\n  final TextEditingController _lngCtrl = TextEditingController();");

c = c.replace("Widget _buildModernInput({required String label, IconData? icon, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator, required void Function(String?) onSaved}) {", "Widget _buildModernInput({required String label, IconData? icon, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator, required void Function(String?) onSaved, TextEditingController? controller}) {");

c = c.replace("maxLines: maxLines, keyboardType: keyboardType, validator: validator, onSaved: onSaved,", "controller: controller, maxLines: maxLines, keyboardType: keyboardType, validator: validator, onSaved: onSaved,");

c = c.replace("_buildModernInput(label: 'Địa chỉ', icon: Icons.location_on_rounded, validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null, onSaved: (v) => _address = v!),", `_buildModernInput(label: 'Địa chỉ', icon: Icons.location_on_rounded, controller: _addressCtrl, validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null, onSaved: (v) => _address = v!),
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
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location_rounded, color: AppTheme.accent, size: 20),
                label: const Text('Tự động lấy vị trí hiện tại (GPS)', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
              ),`);

const func = `
  Future<void> _getCurrentLocation() async {
    setState(() => _isGlobalBusy = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showStatus('Từ chối quyền vị trí!', isError: true);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showStatus('Quyền vị trí bị từ chối vĩnh viễn!', isError: true);
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latCtrl.text = position.latitude.toString();
        _lngCtrl.text = position.longitude.toString();
      });
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        String addr = '\${p.street}, \${p.subAdministrativeArea}, \${p.administrativeArea}';
        _addressCtrl.text = addr.replaceAll(', ,', ',');
      }
      _showStatus('Đã lấy vị trí thành công!');
    } catch (e) {
      _showStatus('Không thể lấy vị trí!', isError: true);
    } finally {
      setState(() => _isGlobalBusy = false);
    }
  }
`;

c = c.replace("Future<void> _submit() async {", func + "\n  Future<void> _submit() async {");

c = c.replace("List<Location> locations = await locationFromAddress(_address);", `if (_latitude == 0.0 && _longitude == 0.0) {
            List<Location> locations = await locationFromAddress(_address);
            if (locations.isNotEmpty) {
              _latitude = locations.first.latitude;
              _longitude = locations.first.longitude;
            }
          }`);

fs.writeFileSync('lib/features/owner/screens/add_court_screen.dart', c);
console.log('Replaced successfully');
