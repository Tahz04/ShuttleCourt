import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shuttlecourt/models/badminton_court.dart';
import 'package:shuttlecourt/services/court_service.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_styles.dart';
import 'package:shuttlecourt/booking/screens/checkout_screen.dart';

class WebBookingPage extends StatefulWidget {
  final BadmintonCourt? initialCourt;
  final Function(int)? onTabChange;

  const WebBookingPage({super.key, this.initialCourt, this.onTabChange});

  @override
  State<WebBookingPage> createState() => _WebBookingPageState();
}

class _WebBookingPageState extends State<WebBookingPage> {
  static const List<String> _timeSlots = [
    '05:00 - 06:00', '06:00 - 07:00', '07:00 - 08:00',
    '17:00 - 18:00', '18:00 - 19:00', '19:00 - 20:00',
    '20:00 - 21:00', '21:00 - 22:00',
  ];

  List<BadmintonCourt> _courts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  BadmintonCourt? _selectedCourt;

  @override
  void initState() {
    super.initState();
    _selectedCourt = widget.initialCourt;
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    final data = await CourtService.getAllCourts();
    if (mounted) setState(() { _courts = data; _isLoading = false; });
  }

  List<BadmintonCourt> get _filteredCourts {
    if (_searchQuery.isEmpty) return _courts;
    final q = _searchQuery.toLowerCase();
    return _courts.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.address.toLowerCase().contains(q)).toList();
  }

  void _proceedToCheckout() {
    if (_selectedCourt != null && _selectedSlot != null) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          selectedSlot: _selectedSlot!,
          selectedCourt: _selectedCourt!,
          selectedDate: _selectedDate,
        ),
      ));
    }
  }

  int get _currentStep {
    if (_selectedCourt == null) return 0;
    if (_selectedSlot == null) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: WebStyles.bg,
      body: Column(
        children: [
          WebNavbar(
            selectedIndex: 3,
            onNavTap: (i) => widget.onTabChange?.call(i),
          ),
          // ── Dark hero header ────────────────────────────────────
          Container(
            color: WebStyles.dark900,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
                  child: Row(
                    children: [
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: WebStyles.brand.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: WebStyles.brand
                                        .withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_month_rounded,
                                      size: 13,
                                      color: WebStyles.brandLight),
                                  SizedBox(width: 6),
                                  Text('ĐẶT LỊCH SÂN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: WebStyles.brandLight,
                                        letterSpacing: 1.2,
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('Đặt Lịch Sân',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.8,
                                )),
                            const SizedBox(height: 4),
                            Text('Chọn sân, ngày và khung giờ phù hợp với bạn',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.55),
                                )),
                          ],
                        ),
                      ),
                      // Step indicators
                      if (isWide)
                        _StepIndicator(currentStep: _currentStep),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Content ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: _buildMain()),
                              const SizedBox(width: 24),
                              SizedBox(
                                  width: 320,
                                  child: _buildSummaryCard()),
                            ],
                          )
                        : Column(children: [
                            _buildMain(),
                            const SizedBox(height: 24),
                            _buildSummaryCard(),
                          ]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCourtStep(),
        if (_selectedCourt != null) ...[
          const SizedBox(height: 24),
          _buildDateStep(),
          const SizedBox(height: 24),
          _buildTimeStep(),
        ],
      ],
    );
  }

  // ── Step 1: Court selection ───────────────────────────────────────────────

  Widget _buildCourtStep() {
    return _StepCard(
      step: 1,
      title: 'Chọn sân',
      subtitle: _selectedCourt?.name ?? 'Chưa chọn sân',
      isDone: _selectedCourt != null,
      child: Column(
        children: [
          // Search
          Container(
            decoration: BoxDecoration(
              color: WebStyles.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: WebStyles.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.search_rounded,
                    color: WebStyles.inkFaint, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Tìm tên sân hoặc địa chỉ...',
                      hintStyle:
                          TextStyle(color: WebStyles.inkFaint, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                    ),
                    style: const TextStyle(fontSize: 13, color: WebStyles.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                  child: CircularProgressIndicator(
                      color: WebStyles.brand, strokeWidth: 2)),
            )
          else
            SizedBox(
              height: 280,
              child: ListView.builder(
                itemCount: _filteredCourts.length,
                itemBuilder: (ctx, i) {
                  final c = _filteredCourts[i];
                  final isSel = _selectedCourt?.id == c.id;
                  final isMaint = c.status == 'maintenance';
                  return GestureDetector(
                    onTap: isMaint
                        ? null
                        : () => setState(() => _selectedCourt = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSel
                            ? WebStyles.brand.withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? WebStyles.brand : WebStyles.border,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Court image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: c.mainImage != null
                                  ? Image.network(c.mainImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) =>
                                          Container(
                                            color: WebStyles.brand
                                                .withValues(alpha: 0.08),
                                            child: const Icon(
                                                Icons.sports_tennis_rounded,
                                                color: WebStyles.brand,
                                                size: 24),
                                          ))
                                  : Container(
                                      color: WebStyles.brand
                                          .withValues(alpha: 0.08),
                                      child: const Icon(
                                          Icons.sports_tennis_rounded,
                                          color: WebStyles.brand,
                                          size: 24)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(c.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isSel
                                                ? WebStyles.brand
                                                : WebStyles.ink,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    if (isMaint)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text('Bảo trì',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red,
                                                fontWeight:
                                                    FontWeight.w700)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(c.address,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: WebStyles.inkFaint),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(c.pricePerHour / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: WebStyles.brand,
                                ),
                              ),
                              const Text('/giờ',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: WebStyles.inkFaint)),
                            ],
                          ),
                          if (isSel) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: WebStyles.brand,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Step 2: Date selection ────────────────────────────────────────────────

  Widget _buildDateStep() {
    return _StepCard(
      step: 2,
      title: 'Chọn ngày',
      subtitle: DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDate),
      isDone: true,
      child: SizedBox(
        height: 52,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 14,
          itemBuilder: (ctx, i) {
            final date = DateTime.now().add(Duration(days: i));
            final isSel = DateUtils.isSameDay(date, _selectedDate);
            final isToday = i == 0;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedDate = date;
                _selectedSlot = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? WebStyles.brand : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel ? WebStyles.brand : WebStyles.border,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isToday ? 'Hôm nay' : DateFormat('EEE').format(date),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSel
                            ? Colors.white.withValues(alpha: 0.8)
                            : WebStyles.inkFaint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('dd').format(date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isSel ? Colors.white : WebStyles.ink,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Step 3: Time slot selection ───────────────────────────────────────────

  Widget _buildTimeStep() {
    return _StepCard(
      step: 3,
      title: 'Chọn khung giờ',
      subtitle: _selectedSlot ?? 'Chưa chọn giờ',
      isDone: _selectedSlot != null,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _timeSlots.map((slot) {
          final isSel = _selectedSlot == slot;
          return GestureDetector(
            onTap: () => setState(() => _selectedSlot = slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: isSel
                    ? WebStyles.brand
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSel ? WebStyles.brand : WebStyles.border),
                boxShadow: isSel
                    ? [
                        BoxShadow(
                          color: WebStyles.brand.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: isSel
                        ? Colors.white
                        : WebStyles.inkFaint,
                  ),
                  const SizedBox(width: 6),
                  Text(slot,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSel ? Colors.white : WebStyles.inkMid,
                      )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final canBook = _selectedCourt != null && _selectedSlot != null;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebStyles.border),
        boxShadow: WebStyles.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: WebStyles.brandGrad,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Tóm tắt đặt sân',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: WebStyles.ink,
                  )),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: WebStyles.border),
          const SizedBox(height: 16),
          // Court
          _SummaryRow(
            icon: Icons.sports_tennis_rounded,
            label: 'Sân',
            value: _selectedCourt?.name ?? '—',
            isEmpty: _selectedCourt == null,
          ),
          const SizedBox(height: 12),
          // Date
          _SummaryRow(
            icon: Icons.calendar_today_rounded,
            label: 'Ngày',
            value: DateFormat('dd/MM/yyyy').format(_selectedDate),
            isEmpty: false,
          ),
          const SizedBox(height: 12),
          // Time slot
          _SummaryRow(
            icon: Icons.access_time_rounded,
            label: 'Giờ',
            value: _selectedSlot ?? '—',
            isEmpty: _selectedSlot == null,
          ),
          const SizedBox(height: 12),
          // Price
          if (_selectedCourt != null) ...[
            const Divider(color: WebStyles.border),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Giá 1 giờ',
                    style: TextStyle(fontSize: 13, color: WebStyles.inkFaint)),
                Text(
                  '${(_selectedCourt!.pricePerHour / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: WebStyles.brand,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canBook ? _proceedToCheckout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: WebStyles.brand,
                foregroundColor: Colors.white,
                disabledBackgroundColor: WebStyles.border,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                canBook ? 'Tiến hành đặt sân' : 'Chọn sân và giờ',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
          if (!canBook) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                _selectedCourt == null
                    ? 'Bước 1: Chọn sân cầu lông'
                    : 'Bước 3: Chọn khung giờ',
                style: const TextStyle(
                    fontSize: 11, color: WebStyles.inkFaint),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Step Card ─────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final int step;
  final String title, subtitle;
  final bool isDone;
  final Widget child;

  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebStyles.border),
        boxShadow: WebStyles.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color:
                        isDone ? WebStyles.brand : WebStyles.bg,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isDone
                            ? WebStyles.brand
                            : WebStyles.border),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : Text('$step',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: WebStyles.inkFaint,
                            )),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: WebStyles.ink,
                        )),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDone
                              ? WebStyles.brand
                              : WebStyles.inkFaint,
                          fontWeight: isDone
                              ? FontWeight.w600
                              : FontWeight.normal,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: WebStyles.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(n: 1, label: 'Chọn sân', done: currentStep > 0, active: currentStep == 0),
        _StepLine(done: currentStep > 0),
        _StepDot(n: 2, label: 'Chọn ngày', done: currentStep > 1, active: currentStep == 1),
        _StepLine(done: currentStep > 1),
        _StepDot(n: 3, label: 'Chọn giờ', done: currentStep > 2, active: currentStep == 2),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int n;
  final String label;
  final bool done, active;
  const _StepDot({required this.n, required this.label, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    final filled = done || active;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: filled ? WebStyles.brand : Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: filled ? WebStyles.brand : Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text('$n', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: active ? Colors.white : Colors.white.withValues(alpha: 0.4))),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: done ? WebStyles.brand : Colors.white.withValues(alpha: 0.15),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isEmpty;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isEmpty
                ? WebStyles.bg
                : WebStyles.brand.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 16,
              color: isEmpty ? WebStyles.inkFaint : WebStyles.brand),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: WebStyles.inkFaint)),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isEmpty ? WebStyles.inkFaint : WebStyles.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
