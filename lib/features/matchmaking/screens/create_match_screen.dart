import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/features/matchmaking/services/matchmaking_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/models/badminton_court.dart';
import 'package:shuttlecourt/services/court_service.dart';
import 'package:intl/intl.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  String _level = 'Trung bình';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _capacity = 4;
  double _price = 0;
  String _description = '';

  // Dữ liệu sân thật
  List<BadmintonCourt> _courts = [];
  BadmintonCourt? _selectedCourt;
  bool _loadingCourts = true;

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    final courts = await CourtService.getAllCourts();
    // Nếu API trả về rỗng, dùng danh sách mẫu
    final finalCourts = courts.isNotEmpty ? courts : sampleBadmintonCourts;
    setState(() {
      _courts = finalCourts;
      _loadingCourts = false;
      if (_courts.isNotEmpty) {
        _selectedCourt = _courts[0];
        _price = _courts[0].pricePerHour;
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tạo Kèo Ghép Mới', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _loadingCourts
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Chọn sân'),
                    DropdownButtonFormField<BadmintonCourt>(
                      value: _selectedCourt,
                      isExpanded: true,
                      decoration: _inputDecoration('', Icons.stadium_rounded),
                      items: _courts.map((court) => DropdownMenuItem(
                        value: court,
                        child: Text(court.name, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (court) {
                        if (court != null) {
                          setState(() {
                            _selectedCourt = court;
                            _price = court.pricePerHour;
                          });
                        }
                      },
                      validator: (v) => v == null ? 'Vui lòng chọn sân' : null,
                    ),
                    if (_selectedCourt != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_selectedCourt!.address} • ${NumberFormat('#,###').format(_selectedCourt!.pricePerHour)}đ/giờ',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    _buildLabel('Trình độ yêu cầu'),
                    DropdownButtonFormField<String>(
                      value: _level,
                      decoration: _inputDecoration('', Icons.bolt_rounded),
                      items: ['Mới chơi', 'Trung bình', 'Khá', 'Pro'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      onChanged: (v) => setState(() => _level = v!),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Ngày đánh'),
                              InkWell(
                                onTap: _selectDate,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: _boxDecoration(),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, size: 20, color: AppTheme.accent),
                                      const SizedBox(width: 10),
                                      Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Giờ bắt đầu'),
                              InkWell(
                                onTap: _selectTime,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: _boxDecoration(),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 20, color: AppTheme.accent),
                                      const SizedBox(width: 10),
                                      Text(_selectedTime.format(context)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Số người tối đa'),
                              TextFormField(
                                initialValue: '4',
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('', Icons.group_rounded),
                                onSaved: (v) => _capacity = int.tryParse(v!) ?? 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Giá sân/giờ'),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: _boxDecoration(),
                                child: Row(
                                  children: [
                                    const Icon(Icons.payments_rounded, size: 20, color: AppTheme.accent),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${NumberFormat('#,###').format(_price)}đ',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Mô tả thêm'),
                    TextFormField(
                      maxLines: 3,
                      decoration: _inputDecoration('Ghi chú về tiền sân, nước uống...', Icons.description_rounded),
                      onSaved: (v) => _description = v ?? '',
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _submit,
                        child: const Text('ĐĂNG KÈO NGAY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.accent, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent, width: 2)),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final auth = Provider.of<AuthService>(context, listen: false);
      if (!auth.isAuthenticated || _selectedCourt == null) return;

      final success = await MatchmakingService.createMatch(
        hostId: int.parse(auth.user!.id),
        courtName: _selectedCourt!.name,
        level: _level,
        matchDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        startTime: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00',
        capacity: _capacity,
        price: _price,
        description: _description,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã tạo kèo thành công!'), backgroundColor: AppTheme.success));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Lỗi khi tạo kèo. Thử lại sau!'), backgroundColor: AppTheme.error));
      }
    }
  }
}
