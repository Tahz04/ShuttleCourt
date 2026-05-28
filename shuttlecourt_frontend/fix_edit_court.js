const fs = require('fs');
let c = fs.readFileSync('lib/features/owner/screens/edit_court_screen.dart', 'utf8');

if (!c.includes('TextEditingController _addressCtrl')) {
  c = c.replace("String _description;", "String _description;\n  final TextEditingController _addressCtrl = TextEditingController();\n  final TextEditingController _latCtrl = TextEditingController();\n  final TextEditingController _lngCtrl = TextEditingController();");
  
  c = c.replace("void _initializeFields() {", `void _initializeFields() {
    // delay to wait for widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addressCtrl.text = widget.court['address'] ?? '';
      _latCtrl.text = widget.court['latitude']?.toString() ?? '0';
      _lngCtrl.text = widget.court['longitude']?.toString() ?? '0';
    });`);

  const replacementInput = `Widget _buildModernInput({required String label, IconData? icon, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator, required void Function(String?) onSaved, TextEditingController? controller}) {
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
  }`;
  c = c.replace("Widget _buildInput({required String label, String? initial, void Function(String?)? onSaved}) {", replacementInput + "\n\n  Widget _buildInput({required String label, String? initial, void Function(String?)? onSaved}) {");

  c = c.replace("_buildInput(label: 'Địa chỉ', initial: _address, onSaved: (v) => _address = v!),", `_buildModernInput(label: 'Địa chỉ', icon: Icons.location_on_rounded, controller: _addressCtrl, validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null, onSaved: (v) => _address = v!),
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
              const SizedBox(height: 16),`);

  const func = `
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
`;
  c = c.replace("Future<void> _submit() async {", func + "\n  Future<void> _submit() async {");

  fs.writeFileSync('lib/features/owner/screens/edit_court_screen.dart', c);
  console.log("Updated edit_court_screen.dart");
} else {
  console.log("Already updated");
}
