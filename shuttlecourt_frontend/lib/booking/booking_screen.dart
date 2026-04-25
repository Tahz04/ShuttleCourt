import 'package:flutter/material.dart';
import 'screens/checkout_screen.dart';
import 'package:shuttlecourt/services/court_service.dart';
import 'package:shuttlecourt/models/badminton_court.dart';
import 'package:intl/intl.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/features/matchmaking/screens/matchmaking_screen.dart';
import 'package:shuttlecourt/main.dart';

class BookingScreen extends StatefulWidget {
  final BadmintonCourt? initialCourt;
  const BookingScreen({super.key, this.initialCourt});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with TickerProviderStateMixin {
  final List<String> _timeSlots = [
    '05:00 - 06:00', '06:00 - 07:00', '07:00 - 08:00',
    '17:00 - 18:00', '18:00 - 19:00', '19:00 - 20:00',
    '20:00 - 21:00', '21:00 - 22:00'
  ];

  String _selectedSlot = '';
  BadmintonCourt? _selectedCourt;
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animController;
  int _selectedPlayers = 2; // Default: 2 people
  
  List<BadmintonCourt> _courts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCourt = widget.initialCourt;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _loadCourts();
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
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        title: Text(
          _selectedCourt == null ? 'Đặt Sân Cầu Lông' : 'Thông Tin Đặt Sân',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_selectedCourt != null) {
              setState(() => _selectedCourt = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedCourt == null ? _buildCourtSelection() : _buildBookingDetails(),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lựa chọn sân phù hợp',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo tên hoặc địa chỉ...',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : filteredCourts.isEmpty
              ? const Center(child: Text('Không tìm thấy sân phù hợp', style: TextStyle(color: AppTheme.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredCourts.length,
                  itemBuilder: (context, index) {
                    final court = filteredCourts[index];
                    return _buildCourtListItem(court);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCourtListItem(BadmintonCourt court) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => setState(() => _selectedCourt = court),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.2), AppTheme.primary.withValues(alpha: 0.05)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_tennis_rounded, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(court.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(court.address, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: AppTheme.accentGold),
                            const SizedBox(width: 2),
                            Text('${court.rating}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(
                          '${(court.pricePerHour / 1000).toStringAsFixed(0)}k/h',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
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
        // Court Summary Card
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade100, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.sports_tennis_rounded, color: AppTheme.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedCourt!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(_selectedCourt!.address, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.payments_rounded, size: 14, color: AppTheme.accentGold),
                        const SizedBox(width: 6),
                        Text(
                          '${(_selectedCourt!.pricePerHour / 1000).toStringAsFixed(0)}kđ / Giờ',
                          style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  if (picked != null) setState(() => _selectedDate = picked);
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
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Số lượng người chơi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildPlayerOption(1, '1 người'),
              const SizedBox(width: 10),
              _buildPlayerOption(2, '2 người'),
              const SizedBox(width: 10),
              _buildPlayerOption(4, '4 người'),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Chọn khung giờ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
        ),
        const SizedBox(height: 14),

        // Time Slots Grid
        Expanded(
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
              return InkWell(
                onTap: () => setState(() => _selectedSlot = _timeSlots[index]),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : AppTheme.cardDark,
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected ? AppTheme.glowShadow : null,
                  ),
                  child: Center(
                    child: Text(
                      _timeSlots[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
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
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: AppTheme.primary.withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('TIẾP TỤC THANH TOÁN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerOption(int count, String label) {
    bool isSelected = _selectedPlayers == count;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPlayers = count),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.05)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  void _showMatchmakingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(Icons.people_alt_rounded, color: AppTheme.primary, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn đang đi 1 mình?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Chúng tôi có dịch vụ "Ghép Kèo" để giúp bạn tìm bạn chơi cùng. Bạn có muốn tham gia không?', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
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
                  child: const Text('KHÔNG, ĐẶT SÂN RIÊNG', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Chuyển sang màn hình Ghép Kèo
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MatchmakingScreen()));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  child: Text('CÓ, GHÉP KÈO NGAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
