import 'package:flutter/material.dart';
import 'package:shuttlecourt/models/booking.dart';
import 'package:shuttlecourt/services/api_booking_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:shuttlecourt/models/match_model.dart';
import 'package:shuttlecourt/features/matchmaking/services/matchmaking_service.dart';

class OwnerBookingManagementScreen extends StatefulWidget {
  const OwnerBookingManagementScreen({super.key});

  @override
  State<OwnerBookingManagementScreen> createState() => _OwnerBookingManagementScreenState();
}

class _OwnerBookingManagementScreenState extends State<OwnerBookingManagementScreen> {
  List<Booking> _bookings = [];
  List<MatchModel> _matches = [];
  bool _isLoading = true;
  bool _showPendingOnly = true;
  DateTime _selectedDate = DateTime.now();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiBookingService.getAllBookings(),
        MatchmakingService.getAllMatches(),
      ]);
      
      if (mounted) {
        setState(() {
          _bookings = List<Booking>.from(results[0]);
          _matches = List<MatchModel>.from(results[1]);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    final success = await ApiBookingService.updateBookingStatus(id, newStatus);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Đã cập nhật: $newStatus'),
          backgroundColor: AppTheme.primaryDeep,
          behavior: SnackBarBehavior.floating,
        ));
        _loadAllData();
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = _bookings.where((b) {
      bool dateMatch = b.date.year == _selectedDate.year && 
                       b.date.month == _selectedDate.month && 
                       b.date.day == _selectedDate.day;
      return _showPendingOnly ? b.status == 'Chờ duyệt' : dateMatch;
    }).toList();
    
    final filteredMatches = _matches.where((m) {
      bool dateMatch = m.matchDate.year == _selectedDate.year && 
                       m.matchDate.month == _selectedDate.month && 
                       m.matchDate.day == _selectedDate.day;
      return !_showPendingOnly && dateMatch;
    }).toList();

    filteredBookings.sort((a, b) => a.slot.compareTo(b.slot));
    filteredMatches.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          _buildFilterTabs(),
          if (!_showPendingOnly) _buildDateDisplay(),
          SliverToBoxAdapter(
            child: _isLoading 
              ? const Padding(padding: EdgeInsets.only(top: 100), child: Center(child: CircularProgressIndicator(color: AppTheme.primary)))
              : (filteredBookings.isEmpty && filteredMatches.isEmpty)
                ? _buildEmptyState()
                : _buildContentList(filteredBookings, filteredMatches),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surfaceDark,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('QUẢN LÝ LỊCH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.primaryDeep.withValues(alpha: 0.5), AppTheme.scaffoldDark],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadAllData),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            _TabButton('Chờ xử lý', _showPendingOnly, () => setState(() => _showPendingOnly = true)),
            const SizedBox(width: 12),
            _TabButton('Theo ngày', !_showPendingOnly, () => setState(() => _showPendingOnly = false)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDisplay() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE, dd/MM').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                    Text('Tháng ${DateFormat('MM / yyyy').format(_selectedDate)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
                const Icon(Icons.calendar_month_rounded, color: AppTheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentList(List<Booking> bookings, List<MatchModel> matches) {
    return Column(
      children: [
        if (bookings.isNotEmpty) ...[
          _SectionHeader(_showPendingOnly ? 'ĐÒN ĐẶT CHỜ DUYỆT' : 'ĐẶT SÂN RIÊNG'),
          ...bookings.map((b) => _BookingItem(b, (status) => _updateStatus(b.id, status), currencyFormat)),
        ],
        if (matches.isNotEmpty) ...[
          const _SectionHeader('KÈO GHÉP THÀNH CÔNG'),
          ...matches.map((m) => _MatchItem(m, currencyFormat)),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Column(
        children: [
          Icon(_showPendingOnly ? Icons.verified_user_rounded : Icons.event_busy_rounded, size: 80, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            _showPendingOnly ? 'Tuyệt vời! Đã xử lý hết' : 'Không có lịch cho ngày này',
            style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? AppTheme.primary : AppTheme.borderDark),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: active ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _BookingItem extends StatelessWidget {
  final Booking b;
  final Function(String) onUpdate;
  final NumberFormat format;
  const _BookingItem(this.b, this.onUpdate, this.format);

  @override
  Widget build(BuildContext context) {
    bool isPending = b.status == 'Chờ duyệt';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: isPending ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.borderDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.userName ?? 'Khách', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(b.courtName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
              _StatusBadge(b.status),
            ],
          ),
          const Divider(height: 32, color: AppTheme.borderDark),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _info(Icons.access_time_rounded, b.slot),
              _info(Icons.payments_outlined, format.format(b.price)),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _actionBtn('TỪ CHỐI', AppTheme.error, () => onUpdate('Đã hủy'), false)),
                const SizedBox(width: 12),
                Expanded(child: _actionBtn('DUYỆT LỊCH', AppTheme.primary, () => onUpdate('Đã duyệt'), true)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _info(IconData icon, String val) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Text(val, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap, bool filled) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: filled ? color : Colors.transparent,
        side: filled ? null : BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: TextStyle(color: filled ? Colors.black : color, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color = AppTheme.primary;
    if (status == 'Đã hủy') color = AppTheme.error;
    if (status == 'Chờ duyệt') color = Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _MatchItem extends StatelessWidget {
  final MatchModel m;
  final NumberFormat format;
  const _MatchItem(this.m, this.format);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.people_alt_rounded, color: AppTheme.accent, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.hostName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                Text('${m.courtName} • ${m.startTime}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(format.format(m.price), style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 13)),
              Text('${m.joinedCount}/${m.capacity} Slot', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
