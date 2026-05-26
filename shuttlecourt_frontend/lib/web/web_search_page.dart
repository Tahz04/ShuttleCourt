import 'package:flutter/material.dart';
import 'package:shuttlecourt/booking/booking_screen.dart';
import 'package:shuttlecourt/models/badminton_court.dart';
import 'package:shuttlecourt/services/location_service.dart';
import 'package:shuttlecourt/web/web_court_detail_dialog.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_styles.dart';

class WebSearchPage extends StatefulWidget {
  final String? initialQuery;
  final Function(int, {String? query})? onTabChange;

  const WebSearchPage({super.key, this.initialQuery, this.onTabChange});

  @override
  State<WebSearchPage> createState() => _WebSearchPageState();
}

class _WebSearchPageState extends State<WebSearchPage> {
  late Future<List<CourtWithDistance>> _future;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  double _maxPrice = 300000;
  double _minRating = 0;
  String _sortBy = 'distance';
  String _status = 'all';
  List<String> _selectedAmenities = [];

  static const List<String> _amenityOptions = [
    'Wifi', 'Gửi xe', 'Nước uống', 'Đèn LED', 'Máy lạnh', 'Huấn luyện viên',
  ];

  @override
  void initState() {
    super.initState();
    _applyInitialQuery(widget.initialQuery ?? '');
    _future = LocationService.getNearestCourts(maxResults: 50);
  }

  @override
  void didUpdateWidget(covariant WebSearchPage old) {
    super.didUpdateWidget(old);
    if (widget.initialQuery != old.initialQuery && widget.initialQuery != null) {
      setState(() => _applyInitialQuery(widget.initialQuery!));
    }
  }

  void _applyInitialQuery(String q) {
    if (q == '__focus__') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) FocusScope.of(context).requestFocus(_searchFocus);
      });
      return;
    }
    if (q == 'Tìm sân gần tôi') { _sortBy = 'distance'; }
    else if (q == 'Giá dưới 100k/h') { _maxPrice = 100000; }
    else if (q == 'Sân có đèn LED') { _selectedAmenities = ['Đèn LED']; }
    else if (q == 'Sân có HLV') { _selectedAmenities = ['Huấn luyện viên']; }
    else { _searchCtrl.text = q; }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<CourtWithDistance> _filtered(List<CourtWithDistance> all) {
    final q = _searchCtrl.text.toLowerCase();
    var list = all.where((e) {
      final c = e.court;
      final matchSearch = q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q);
      final matchPrice = c.pricePerHour <= _maxPrice;
      final matchRating = c.rating >= _minRating;
      final matchStatus = _status == 'all' || c.status == _status;
      bool matchAmenities = true;
      for (final a in _selectedAmenities) {
        if (!c.amenities.any((x) => x.toLowerCase() == a.toLowerCase())) {
          matchAmenities = false;
          break;
        }
      }
      return matchSearch && matchPrice && matchRating && matchStatus && matchAmenities;
    }).toList();

    switch (_sortBy) {
      case 'price':
        list.sort((a, b) => a.court.pricePerHour.compareTo(b.court.pricePerHour));
      case 'rating':
        list.sort((a, b) => b.court.rating.compareTo(a.court.rating));
      default:
        list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }
    return list;
  }

  void _resetFilters() => setState(() {
    _maxPrice = 300000;
    _minRating = 0;
    _sortBy = 'distance';
    _status = 'all';
    _selectedAmenities = [];
    _searchCtrl.clear();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebStyles.bg,
      body: Column(
        children: [
          WebNavbar(
            selectedIndex: 1,
            onNavTap: (i) => widget.onTabChange?.call(i),
          ),
          // ── Dark hero header ────────────────────────────────────
          Container(
            color: WebStyles.dark900,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: WebStyles.brand.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: WebStyles.brand.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_rounded,
                                    size: 13, color: WebStyles.brandLight),
                                SizedBox(width: 6),
                                Text('TÌM SÂN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: WebStyles.brandLight,
                                      letterSpacing: 1.2,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tìm Sân Cầu Lông',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Khám phá hàng trăm sân cầu lông chất lượng cao gần bạn',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.55),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Search bar
                      Container(
                        constraints: const BoxConstraints(maxWidth: 560),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            const Icon(Icons.search_rounded,
                                color: WebStyles.brand, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                focusNode: _searchFocus,
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Tìm theo tên sân hoặc địa chỉ...',
                                  hintStyle: TextStyle(
                                    color: WebStyles.dark400,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                style: const TextStyle(
                                    fontSize: 13, color: WebStyles.dark900),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: ElevatedButton(
                                onPressed: () => setState(() {}),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WebStyles.brand,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Tìm',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Main content ────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<CourtWithDistance>>(
              future: _future,
              builder: (context, snap) {
                final all = snap.data ?? [];
                final courts = snap.connectionState == ConnectionState.done
                    ? _filtered(all)
                    : <CourtWithDistance>[];
                final isLoading =
                    snap.connectionState == ConnectionState.waiting;
                final isWide = MediaQuery.of(context).size.width > 1024;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Filter sidebar ────────────────────────────
                    if (isWide)
                      Container(
                        width: 260,
                        color: Colors.white,
                        child: SingleChildScrollView(
                          child: _FilterPanel(
                            maxPrice: _maxPrice,
                            minRating: _minRating,
                            sortBy: _sortBy,
                            status: _status,
                            selectedAmenities: _selectedAmenities,
                            amenityOptions: _amenityOptions,
                            onMaxPriceChanged: (v) =>
                                setState(() => _maxPrice = v),
                            onMinRatingChanged: (v) =>
                                setState(() => _minRating = v),
                            onSortByChanged: (v) =>
                                setState(() => _sortBy = v),
                            onStatusChanged: (v) =>
                                setState(() => _status = v),
                            onAmenitiesChanged: (a, sel) => setState(() {
                              if (sel) {
                                if (!_selectedAmenities.contains(a)) {
                                  _selectedAmenities.add(a);
                                }
                              } else {
                                _selectedAmenities.remove(a);
                              }
                            }),
                            onReset: _resetFilters,
                          ),
                        ),
                      ),
                    // ── Results area ──────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Results bar
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              child: Row(
                                children: [
                                  if (isLoading)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: WebStyles.brand),
                                    )
                                  else ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: WebStyles.brand
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${courts.length} sân',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: WebStyles.brand,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'phù hợp với bộ lọc',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: WebStyles.inkFaint),
                                    ),
                                  ],
                                  const Spacer(),
                                  // Sort dropdown
                                  Row(
                                    children: [
                                      const Text('Sắp xếp: ',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: WebStyles.inkFaint)),
                                      _SortChip(
                                        label: 'Gần nhất',
                                        active: _sortBy == 'distance',
                                        onTap: () => setState(
                                            () => _sortBy = 'distance'),
                                      ),
                                      const SizedBox(width: 6),
                                      _SortChip(
                                        label: 'Giá thấp',
                                        active: _sortBy == 'price',
                                        onTap: () => setState(
                                            () => _sortBy = 'price'),
                                      ),
                                      const SizedBox(width: 6),
                                      _SortChip(
                                        label: 'Đánh giá',
                                        active: _sortBy == 'rating',
                                        onTap: () => setState(
                                            () => _sortBy = 'rating'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: WebStyles.border),
                            // Grid
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 80),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: WebStyles.brand, strokeWidth: 2),
                                ),
                              )
                            else if (courts.isEmpty)
                              _EmptyState(onReset: _resetFilters)
                            else
                              _CourtGrid(
                                courts: courts,
                                onViewDetails: (c, km) =>
                                    showCourtDetailDialog(context, c,
                                        distanceKm: km),
                                onBook: (c) => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          BookingScreen(initialCourt: c)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Panel ─────────────────────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  final double maxPrice, minRating;
  final String sortBy, status;
  final List<String> selectedAmenities, amenityOptions;
  final ValueChanged<double> onMaxPriceChanged, onMinRatingChanged;
  final ValueChanged<String> onSortByChanged, onStatusChanged;
  final Function(String, bool) onAmenitiesChanged;
  final VoidCallback onReset;

  const _FilterPanel({
    required this.maxPrice,
    required this.minRating,
    required this.sortBy,
    required this.status,
    required this.selectedAmenities,
    required this.amenityOptions,
    required this.onMaxPriceChanged,
    required this.onMinRatingChanged,
    required this.onSortByChanged,
    required this.onStatusChanged,
    required this.onAmenitiesChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              const Text(
                'Bộ lọc',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: WebStyles.ink,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onReset,
                child: Text(
                  'Đặt lại',
                  style: TextStyle(
                    fontSize: 12,
                    color: WebStyles.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: WebStyles.border),
        // Price range
        _FilterSection(
          label: 'Giá tối đa',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('0đ',
                      style:
                          TextStyle(fontSize: 11, color: WebStyles.inkFaint)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: WebStyles.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(maxPrice / 1000).toStringAsFixed(0)}k/h',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: WebStyles.brand,
                      ),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: WebStyles.brand,
                  thumbColor: WebStyles.brand,
                  inactiveTrackColor: WebStyles.border,
                  overlayColor: WebStyles.brand.withValues(alpha: 0.1),
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: maxPrice,
                  min: 0,
                  max: 300000,
                  divisions: 30,
                  onChanged: onMaxPriceChanged,
                ),
              ),
            ],
          ),
        ),
        // Rating - FIX: Thay Row bằng Wrap để tránh lỗi vỡ giao diện (Overflow)
        _FilterSection(
          label: 'Đánh giá tối thiểu',
          child: Wrap(
            spacing: 4,
            runSpacing: 8,
            children: [1, 2, 3, 4, 5]
                .map((r) => GestureDetector(
                      onTap: () => onMinRatingChanged(r.toDouble()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: minRating >= r
                              ? WebStyles.brand
                              : WebStyles.bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: minRating >= r
                                ? WebStyles.brand
                                : WebStyles.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 12,
                                color: minRating >= r
                                    ? Colors.white
                                    : const Color(0xFFFBBF24)),
                            const SizedBox(width: 2),
                            Text(
                              '$r+',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: minRating >= r
                                    ? Colors.white
                                    : WebStyles.inkMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        // Status
        _FilterSection(
          label: 'Trạng thái',
          child: Column(
            children: [
              _RadioTile(
                label: 'Tất cả',
                value: 'all',
                groupValue: status,
                onChanged: onStatusChanged,
              ),
              _RadioTile(
                label: 'Đang hoạt động',
                value: 'active',
                groupValue: status,
                onChanged: onStatusChanged,
              ),
              _RadioTile(
                label: 'Đang bảo trì',
                value: 'maintenance',
                groupValue: status,
                onChanged: onStatusChanged,
              ),
            ],
          ),
        ),
        // Amenities
        _FilterSection(
          label: 'Tiện ích',
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: amenityOptions
                .map((a) {
                  final active = selectedAmenities.contains(a);
                  return GestureDetector(
                    onTap: () => onAmenitiesChanged(a, !active),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: active ? WebStyles.brand : WebStyles.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              active ? WebStyles.brand : WebStyles.border,
                        ),
                      ),
                      child: Text(
                        a,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              active ? Colors.white : WebStyles.inkMid,
                        ),
                      ),
                    ),
                  );
                })
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _FilterSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: WebStyles.inkFaint,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 10),
          child,
          const SizedBox(height: 14),
          const Divider(color: WebStyles.border, height: 1),
        ],
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final String label, value, groupValue;
  final ValueChanged<String> onChanged;
  const _RadioTile(
      {required this.label,
      required this.value,
      required this.groupValue,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final active = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? WebStyles.brand : WebStyles.border,
                  width: active ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: active ? WebStyles.ink : WebStyles.inkLight,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Sort chip ─────────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SortChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? WebStyles.brand : WebStyles.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? WebStyles.brand : WebStyles.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : WebStyles.inkMid,
          ),
        ),
      ),
    );
  }
}

// ── Court Grid ────────────────────────────────────────────────────────────────

class _CourtGrid extends StatelessWidget {
  final List<CourtWithDistance> courts;
  final Function(BadmintonCourt, double) onViewDetails;
  final Function(BadmintonCourt) onBook;

  const _CourtGrid({
    required this.courts,
    required this.onViewDetails,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w > 1400 ? 4 : w > 1100 ? 3 : w > 700 ? 2 : 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 360,
        ),
        itemCount: courts.length,
        itemBuilder: (ctx, i) {
          final item = courts[i];
          return _CourtCard(
            court: item.court,
            distanceKm: item.distanceKm,
            onViewDetails: () =>
                onViewDetails(item.court, item.distanceKm),
            onBook: () => onBook(item.court),
          );
        },
      ),
    );
  }
}

// ── Court Card ────────────────────────────────────────────────────────────────

class _CourtCard extends StatefulWidget {
  final BadmintonCourt court;
  final double distanceKm;
  final VoidCallback onViewDetails, onBook;
  const _CourtCard({
    required this.court,
    required this.distanceKm,
    required this.onViewDetails,
    required this.onBook,
  });

  @override
  State<_CourtCard> createState() => _CourtCardState();
}

class _CourtCardState extends State<_CourtCard> {
  bool _hovered = false;

  static const _placeholder =
      'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=600&q=70';

  @override
  Widget build(BuildContext context) {
    final c = widget.court;
    final isMaint = c.status == 'maintenance';
    final img = (c.mainImage != null && c.mainImage!.isNotEmpty)
        ? c.mainImage!
        : _placeholder;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? WebStyles.brand.withValues(alpha: 0.35)
                : WebStyles.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: WebStyles.brand.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ]
              : WebStyles.shadowSm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              SizedBox(
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(img,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Container(
                            color: WebStyles.brand.withValues(alpha: 0.08),
                            child: const Center(
                                child: Icon(Icons.sports_tennis_rounded,
                                    size: 48, color: WebStyles.brand)))),
                    // Gradient
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 70,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Status
                    if (isMaint)
                      Container(
                        color: Colors.black.withValues(alpha: 0.55),
                        child: const Center(
                          child: Text('BẢO TRÌ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1)),
                        ),
                      ),
                    // Price badge
                    Positioned(
                      bottom: 10,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: WebStyles.brand,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(c.pricePerHour / 1000).toStringAsFixed(0)}k/h',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12),
                        ),
                      ),
                    ),
                    // Rating
                    Positioned(
                      bottom: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 13, color: Color(0xFFFBBF24)),
                            const SizedBox(width: 3),
                            Text(c.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: WebStyles.ink,
                              height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: WebStyles.inkFaint),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(c.address,
                                style: const TextStyle(
                                    fontSize: 11, color: WebStyles.inkFaint),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (widget.distanceKm > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: WebStyles.brand
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${widget.distanceKm.toStringAsFixed(1)}km',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: WebStyles.brand),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (c.amenities.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: c.amenities
                              .take(3)
                              .map((a) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: WebStyles.bg,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      border: Border.all(
                                          color: WebStyles.border),
                                    ),
                                    child: Text(a,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: WebStyles.inkLight)),
                                  ))
                              .toList(),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onViewDetails,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: WebStyles.inkMid,
                                side: const BorderSide(
                                    color: WebStyles.border),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 9),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                              child: const Text('Chi tiết',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isMaint ? null : widget.onBook,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: WebStyles.brand,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: WebStyles.border,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 9),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                              child: const Text('Đặt ngay',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12)),
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
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onReset;
  const _EmptyState({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: WebStyles.brand.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 48, color: WebStyles.brand),
            ),
            const SizedBox(height: 20),
            const Text('Không tìm thấy sân phù hợp',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: WebStyles.ink)),
            const SizedBox(height: 8),
            const Text('Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
                style: TextStyle(fontSize: 13, color: WebStyles.inkFaint)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Đặt lại bộ lọc',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: WebStyles.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
