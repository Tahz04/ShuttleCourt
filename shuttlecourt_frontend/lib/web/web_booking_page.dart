import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/services/court_service.dart';
import 'package:shuttlecourt/models/badminton_court.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_dashboard_widgets.dart';
import 'package:shuttlecourt/web/web_footer.dart';
import 'package:shuttlecourt/booking/screens/checkout_screen.dart';

/// Web-optimized booking page with side-by-side layout
class WebBookingPage extends StatefulWidget {
  final BadmintonCourt? initialCourt;
  final Function(int)? onTabChange;

  const WebBookingPage({super.key, this.initialCourt, this.onTabChange});

  @override
  State<WebBookingPage> createState() => _WebBookingPageState();
}

class _WebBookingPageState extends State<WebBookingPage> {
  final List<String> _timeSlots = [
    '05:00 - 06:00',
    '06:00 - 07:00',
    '07:00 - 08:00',
    '17:00 - 18:00',
    '18:00 - 19:00',
    '19:00 - 20:00',
    '20:00 - 21:00',
    '21:00 - 22:00',
  ];

  List<BadmintonCourt> _courts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  BadmintonCourt? _selectedCourt;
  int _selectedNavIndex = 3;

  @override
  void initState() {
    super.initState();
    _selectedCourt = widget.initialCourt;
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

  void _proceedToCheckout() {
    if (_selectedCourt != null && _selectedSlot != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            selectedSlot: _selectedSlot!,
            selectedCourt: _selectedCourt!,
            selectedDate: _selectedDate,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSideBySide = screenWidth > 1200;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: Column(
        children: [
          WebNavbar(
            selectedIndex: _selectedNavIndex,
            onNavTap: (index) {
              setState(() => _selectedNavIndex = index);
              widget.onTabChange?.call(index);
            },
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 40,
                ),
                child: isSideBySide
                    ? _buildSideBySideLayout()
                    : _buildStackedLayout(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideBySideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Court Selection & Details
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(right: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCourtSelectionSection(),
                if (_selectedCourt != null) ...[
                  const SizedBox(height: 40),
                  _buildDateTimeSelectionSection(),
                ],
              ],
            ),
          ),
        ),

        // Right: Summary
        Expanded(
          flex: 2,
          child: _selectedCourt != null
              ? Column(
                  children: [
                    WebBookingSummaryCard(
                      courtName: _selectedCourt!.name,
                      courtAddress: _selectedCourt!.address,
                      bookingDate: _selectedDate,
                      timeSlot: _selectedSlot ?? 'Chưa chọn',
                      pricePerHour: _selectedCourt!.pricePerHour,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_selectedSlot != null)
                            ? _proceedToCheckout
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          disabledBackgroundColor: AppTheme.textMuted,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Tiếp Tục Thanh Toán',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.cardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Hãy chọn một sân để xem tóm tắt đơn đặt',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStackedLayout() {
    return Column(
      children: [
        _buildCourtSelectionSection(),
        if (_selectedCourt != null) ...[
          const SizedBox(height: 40),
          _buildDateTimeSelectionSection(),
          const SizedBox(height: 40),
          WebBookingSummaryCard(
            courtName: _selectedCourt!.name,
            courtAddress: _selectedCourt!.address,
            bookingDate: _selectedDate,
            timeSlot: _selectedSlot ?? 'Chưa chọn',
            pricePerHour: _selectedCourt!.pricePerHour,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedSlot != null) ? _proceedToCheckout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: AppTheme.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tiếp Tục Thanh Toán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCourtSelectionSection() {
    final filteredCourts = _courts
        .where(
          (court) =>
              court.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              court.address.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'Lựa Chọn Sân Cầu Lông',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),

        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: AppTheme.softShadow,
          ),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc địa chỉ sân...',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.primary,
                size: 24,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
          ),
        ),
        const SizedBox(height: 24),

        // Courts Grid
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          )
        else if (filteredCourts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 48,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không tìm thấy sân phù hợp',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 900
                  ? 3
                  : (constraints.maxWidth > 500 ? 2 : 1);
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.9,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredCourts.length,
                itemBuilder: (context, index) {
                  final court = filteredCourts[index];
                  final isSelected = _selectedCourt?.id == court.id;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCourt = court;
                      _selectedSlot = null;
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withOpacity(0.05)
                            : AppTheme.cardLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.borderLight,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? AppTheme.premiumShadow
                            : AppTheme.softShadow,
                      ),
                      child: Column(
                        children: [
                          // Icon Area
                          Container(
                            width: double.infinity,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.sports_tennis_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),

                          // Info
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    court.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    court.address,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 12,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${court.rating}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${(court.pricePerHour / 1000).toStringAsFixed(0)}k/h',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildDateTimeSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn Ngày và Giờ',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),

        // Date Picker
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.edit_calendar_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Time Slots Grid
        Text(
          'Chọn Khung Giờ',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 800
                ? 4
                : (constraints.maxWidth > 500 ? 3 : 2);
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final slot = _timeSlots[index];
                final isSelected = _selectedSlot == slot;
                return WebDateTimeSlotCard(
                  date: _selectedDate,
                  timeSlot: slot,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedSlot = slot),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
