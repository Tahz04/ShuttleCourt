import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/features/matchmaking/services/matchmaking_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/models/badminton_court.dart';
import 'package:shuttlecourt/services/court_service.dart';
import 'package:intl/intl.dart';
import 'package:shuttlecourt/services/api_booking_service.dart';
import 'package:shuttlecourt/services/socket_service.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  String _level = 'Trung bình';
  final DateTime _selectedDate = DateTime.now();
  int _capacity = 4;
  double _price = 0;
  String _description = '';

  // Dữ liệu sân thật
  List<BadmintonCourt> _courts = [];
  BadmintonCourt? _selectedCourt;
  bool _loadingCourts = true;

  // Dữ liệu Slots
  String _selectedSlot = '';
  List<String> _bookedSlots = [];
  bool _loadingSlots = false;

  final Map<String, List<String>> _timeSlotsByCategory = {
    'Đêm / Khuya': [
      '00:00 - 01:00',
      '01:00 - 02:00',
      '02:00 - 03:00',
      '03:00 - 04:00',
      '04:00 - 05:00',
      '05:00 - 06:00',
    ],
    'Sáng': [
      '06:00 - 07:00',
      '07:00 - 08:00',
      '08:00 - 09:00',
      '09:00 - 10:00',
      '10:00 - 11:00',
      '11:00 - 12:00',
    ],
    'Chiều': [
      '12:00 - 13:00',
      '13:00 - 14:00',
      '14:00 - 15:00',
      '15:00 - 16:00',
      '16:00 - 17:00',
      '17:00 - 18:00',
    ],
    'Tối': [
      '18:00 - 19:00',
      '19:00 - 20:00',
      '20:00 - 21:00',
      '21:00 - 22:00',
      '22:00 - 23:00',
      '23:00 - 24:00',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadCourts();

    SocketService().connect();
    SocketService().onBookingUpdated((data) {
      if (mounted && _selectedCourt != null) {
        if (data != null && data['court_name'] == _selectedCourt!.name) {
          _fetchBookedSlots();
        }
      }
    });
  }

  @override
  void dispose() {
    SocketService().offBookingUpdated();
    super.dispose();
  }

  Future<void> _fetchBookedSlots() async {
    if (_selectedCourt == null) return;
    setState(() => _loadingSlots = true);
    try {
      final slots = await ApiBookingService.getBookedSlots(
        _selectedCourt!.name,
        _selectedDate,
      );
      if (mounted) {
        setState(() {
          _bookedSlots = slots;
          _loadingSlots = false;
          if (_bookedSlots.contains(_selectedSlot)) {
            _selectedSlot = '';
          }
        });
      }
    } catch (e) {
      debugPrint('Lỗi lấy lịch trống: $e');
      if (mounted) {
        setState(() => _loadingSlots = false);
      }
    }
  }

  Future<void> _loadCourts() async {
    final courts = await CourtService.getAllCourts();
    // Nếu API trả về rỗng, dùng danh sách mẫu
    final finalCourts = courts.isNotEmpty ? courts : sampleBadmintonCourts;
    if (mounted) {
      setState(() {
        _courts = finalCourts;
        _loadingCourts = false;
        if (_courts.isNotEmpty) {
          _selectedCourt = _courts[0];
          _price = _courts[0].pricePerHour;
        }
      });
      _fetchBookedSlots();
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
                      initialValue: _selectedCourt,
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
                            _selectedSlot = '';
                          });
                          _fetchBookedSlots();
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
                      initialValue: _level,
                      decoration: _inputDecoration('', Icons.bolt_rounded),
                      items: ['Mới chơi', 'Trung bình', 'Khá', 'Pro'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      onChanged: (v) => setState(() => _level = v!),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Ngày đánh'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: _boxDecoration().copyWith(
                        color: Colors.grey.shade100,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 20, color: AppTheme.textMuted),
                          const SizedBox(width: 10),
                          Text(
                            'Hôm nay (${DateFormat('dd/MM/yyyy').format(_selectedDate)})',
                            style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Chọn khung giờ chơi'),
                    if (_loadingSlots)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(color: AppTheme.accent),
                        ),
                      )
                    else if (_selectedCourt == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Vui lòng chọn sân trước',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      )
                    else ...[
                      ..._timeSlotsByCategory.entries.map(
                        (entry) => _buildTimeSlotGroup(entry.key, entry.value),
                      ),
                    ],
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
    if (_selectedSlot.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khung giờ chơi!'), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final auth = Provider.of<AuthService>(context, listen: false);
      if (!auth.isAuthenticated || _selectedCourt == null) return;

      final startTimeStr = '${_selectedSlot.split(' - ')[0].trim()}:00';
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      final success = await MatchmakingService.createMatch(
        hostId: int.parse(auth.user!.id),
        courtName: _selectedCourt!.name,
        level: _level,
        matchDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        startTime: startTimeStr,
        capacity: _capacity,
        price: _price,
        description: _description,
      );

      if (success) {
        messenger.showSnackBar(const SnackBar(content: Text('✅ Đã tạo kèo thành công!'), backgroundColor: AppTheme.success));
        navigator.pop(true);
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('❌ Lỗi khi tạo kèo. Thử lại sau!'), backgroundColor: AppTheme.error));
      }
    }
  }

  Widget _buildTimeSlotGroup(String category, List<String> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            category,
            style: TextStyle(
              color: AppTheme.accent.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            bool isSelected = _selectedSlot == slots[index];
            bool isBooked = _bookedSlots.contains(slots[index]);

            bool isPast = false;
            final now = DateTime.now();
            if (_selectedDate.year == now.year &&
                _selectedDate.month == now.month &&
                _selectedDate.day == now.day) {
              String startTimeStr = slots[index].split(' - ')[0];
              List<String> parts = startTimeStr.split(':');
              if (parts.length == 2) {
                int hour = int.tryParse(parts[0]) ?? 0;
                int minute = int.tryParse(parts[1]) ?? 0;
                if (hour < now.hour ||
                    (hour == now.hour && minute <= now.minute)) {
                  isPast = true;
                }
              }
            }

            bool isDisabled = isBooked || isPast;

            return InkWell(
              onTap: isDisabled
                  ? null
                  : () => setState(() => _selectedSlot = slots[index]),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.matchmakingGradient : null,
                  color: isDisabled
                      ? Colors.grey.shade100
                      : (isSelected ? null : Colors.grey.shade50),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.grey.shade200,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    isDisabled
                        ? 'Hết'
                        : slots[index],
                    style: TextStyle(
                      color: isDisabled
                          ? AppTheme.textMuted
                          : (isSelected
                                ? Colors.white
                                : AppTheme.textSecondary),
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      decoration: isDisabled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
