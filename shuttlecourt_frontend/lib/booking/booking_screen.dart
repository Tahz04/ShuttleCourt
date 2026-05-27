import 'package:flutter/material.dart';
import 'screens/checkout_screen.dart';
import 'package:shuttlecourt/services/court_service.dart';
import 'package:shuttlecourt/models/badminton_court.dart';
import 'package:intl/intl.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/features/matchmaking/screens/matchmaking_screen.dart';
<<<<<<< HEAD
import 'package:shuttlecourt/main.dart';
import 'package:shuttlecourt/services/api_booking_service.dart';
=======
>>>>>>> 5553e45fbf7ac55b80719d357cb2d472872fc8c5

class BookingScreen extends StatefulWidget {
  final BadmintonCourt? initialCourt;
  const BookingScreen({super.key, this.initialCourt});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with TickerProviderStateMixin {
  // Domain: Phân loại ca chơi theo ca Sáng/Chiều/Tối truyền thống của sân cầu lông
  final Map<String, List<String>> _timeSlotsByCategory = {
    'Sáng': ['05:00 - 06:00', '06:00 - 07:00', '07:00 - 08:00', '08:00 - 09:00', '09:00 - 10:00'],
    'Chiều': ['14:00 - 15:00', '15:00 - 16:00', '16:00 - 17:00'],
    'Tối': ['17:00 - 18:00', '18:00 - 19:00', '19:00 - 20:00', '20:00 - 21:00', '21:00 - 22:00']
  };

  String _selectedSlot = '';
  BadmintonCourt? _selectedCourt;
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();
  int _selectedPlayers = 2;

  List<BadmintonCourt> _courts = [];
  bool _isLoading = true;
  List<String> _bookedSlots = [];

  @override
  void initState() {
    super.initState();
    _selectedCourt = widget.initialCourt;
    _loadCourts();
    if (_selectedCourt != null) {
      _fetchBookedSlots();
    }
  }

  Future<void> _fetchBookedSlots() async {
    if (_selectedCourt == null) return;
    try {
      final slots = await ApiBookingService.getBookedSlots(_selectedCourt!.name, _selectedDate);
      if (mounted) {
        setState(() {
          _bookedSlots = slots;
          if (_bookedSlots.contains(_selectedSlot)) {
            _selectedSlot = '';
          }
        });
      }
    } catch (e) {
      debugPrint('Lỗi lấy lịch trống: $e');
    }
  }

  Future<void> _loadCourts() async {
    setState(() => _isLoading = true);
    final data = await CourtService.getAllCourts();
    setState(() {
      _courts = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        title: Text(
          _selectedCourt == null ? 'Đặt Sân' : 'Chi tiết đặt lịch',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_selectedCourt != null && widget.initialCourt == null) {
              setState(() => _selectedCourt = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500), // Fix độ rộng để đẹp trên cả Web và Mobile
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedCourt == null ? _buildCourtSelection() : _buildBookingDetails(),
          ),
        ),
      ),
    );
  }

  Widget _buildCourtSelection() {
    final filteredCourts = _courts.where((court) =>
    court.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        court.address.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      key: const ValueKey('selection'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Tìm nhanh tên sân hoặc khu vực...',
                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredCourts.length,
            itemBuilder: (context, index) => _buildCourtListItem(filteredCourts[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCourtListItem(BadmintonCourt court) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
<<<<<<< HEAD
        onTap: () {
          setState(() => _selectedCourt = court);
          _fetchBookedSlots();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
=======
        onTap: () => setState(() => _selectedCourt = court),
        borderRadius: BorderRadius.circular(12),
>>>>>>> 5553e45fbf7ac55b80719d357cb2d472872fc8c5
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 44, height: 44,
                  color: AppTheme.primary.withOpacity(0.1),
                  child: const Icon(Icons.sports_tennis_rounded, color: AppTheme.primary, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(court.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
                    Text(court.address, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text('${(court.pricePerHour / 1000).toStringAsFixed(0)}k/h', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Column(
      key: const ValueKey('details'),
      children: [
        // Court Summary Card - Tinh gọn đúng domain
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedCourt!.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text(_selectedCourt!.address, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
<<<<<<< HEAD
              )
            ],
          ),
        ),

        // Date Selection
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn ngày đặt', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    _fetchBookedSlots();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, dd/MM/yyyy').format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_rounded, color: AppTheme.textMuted, size: 18),
                    ],
                  ),
                ),
=======
>>>>>>> 5553e45fbf7ac55b80719d357cb2d472872fc8c5
              ),
              Text('${(_selectedCourt!.pricePerHour / 1000).toStringAsFixed(0)}k/h', style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),

        Expanded(
<<<<<<< HEAD
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _timeSlots.length,
            itemBuilder: (context, index) {
              bool isSelected = _selectedSlot == _timeSlots[index];
              bool isBooked = _bookedSlots.contains(_timeSlots[index]);
              return InkWell(
                onTap: isBooked ? null : () => setState(() => _selectedSlot = _timeSlots[index]),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: (isSelected && !isBooked) ? AppTheme.primaryGradient : null,
                    color: isBooked ? Colors.grey.withOpacity(0.1) : (isSelected ? null : AppTheme.cardDark),
                    border: Border.all(color: (isSelected && !isBooked) ? Colors.transparent : Colors.white.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: (isSelected && !isBooked) ? AppTheme.glowShadow : null,
                  ),
                  child: Center(
                    child: Text(
                      _timeSlots[index],
                      style: TextStyle(
                        color: isBooked ? Colors.white30 : (isSelected ? Colors.white : AppTheme.textSecondary),
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        decoration: isBooked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
=======
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _sectionTitle('Ngày đặt'),
                _buildDateSelector(),

                const SizedBox(height: 16),
                _sectionTitle('Số người chơi'),
                Row(
                  children: [
                    _buildPlayerOption(1, '1 Người'),
                    const SizedBox(width: 8),
                    _buildPlayerOption(2, '2 Người'),
                    const SizedBox(width: 8),
                    _buildPlayerOption(4, '4 Người'),
                  ],
>>>>>>> 5553e45fbf7ac55b80719d357cb2d472872fc8c5
                ),

                const SizedBox(height: 16),
                _sectionTitle('Khung giờ'),
                ..._timeSlotsByCategory.entries.map((entry) => _buildTimeSlotGroup(entry.key, entry.value)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        _buildBottomActionBar(),
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
  );

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 60)),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.primary),
            const SizedBox(width: 10),
            Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotGroup(String category, List<String> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(category, style: TextStyle(color: AppTheme.primary.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Domain: 3 cột cực kỳ gọn gàng
            childAspectRatio: 2.4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            bool isSelected = _selectedSlot == slots[index];
            bool isBooked = index == 1 && category == 'Tối'; // Giả lập sân hết ca

            return InkWell(
              onTap: isBooked ? null : () => setState(() => _selectedSlot = slots[index]),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isBooked ? Colors.white.withOpacity(0.05) : (isSelected ? null : AppTheme.cardDark),
                  border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    isBooked ? 'Hết' : slots[index].split(' ')[0], // Chỉ lấy giờ bắt đầu cho chuyên nghiệp
                    style: TextStyle(
                      color: isBooked ? AppTheme.textMuted : (isSelected ? Colors.white : AppTheme.textSecondary),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      decoration: isBooked ? TextDecoration.lineThrough : null,
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

  Widget _buildPlayerOption(int count, String label) {
    bool isSelected = _selectedPlayers == count;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPlayers = count),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _selectedSlot.isEmpty ? null : () {
            if (_selectedPlayers == 1) {
              _showMatchmakingDialog();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutScreen(
                    selectedSlot: _selectedSlot,
                    selectedCourt: _selectedCourt!,
                    selectedDate: _selectedDate,
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('TIẾP TỤC', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // Nghiệp vụ: Gợi ý ghép kèo nếu khách đi 1 mình
  void _showMatchmakingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.people_alt_rounded, color: AppTheme.primary, size: 40),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tìm bạn chơi cùng?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
            SizedBox(height: 8),
            Text('Bạn đang đặt sân 1 mình. Bạn có muốn sử dụng tính năng "Ghép Kèo" để tìm thêm đồng đội không?', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen(
                      selectedSlot: _selectedSlot,
                      selectedCourt: _selectedCourt!,
                      selectedDate: _selectedDate,
                    )));
                  },
                  child: const Text('ĐẶT RIÊNG', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchmakingScreen()));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('GHÉP KÈO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
