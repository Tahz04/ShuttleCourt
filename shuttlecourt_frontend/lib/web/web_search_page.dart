import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/booking/booking_screen.dart';
import 'package:shuttlecourt/services/location_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/web/web_court_card.dart';
import 'package:shuttlecourt/web/web_footer.dart';
import 'package:shuttlecourt/web/web_navbar.dart';

/// Web search/browse courts page with filters + responsive grid
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

  // Filters
  double _maxPrice = 300000;
  double _minRating = 0;
  String _sortBy = 'distance'; // distance | price | rating
  String _status = 'all'; // all | active | maintenance
  List<String> _selectedAmenities = [];

  @override
  void initState() {
    super.initState();
    
    // Intercept Quick Booking queries
    final q = widget.initialQuery ?? '';
    if (q == 'Tìm sân gần tôi') {
      _sortBy = 'distance';
    } else if (q == 'Giá dưới 100k/h') {
      _maxPrice = 100000;
    } else if (q == 'Sân có đèn LED') {
      _selectedAmenities = ['Đèn LED'];
    } else if (q == 'Sân có HLV') {
      _selectedAmenities = ['Huấn luyện viên'];
    } else {
      _searchCtrl.text = q;
    }

    _future = LocationService.getNearestCourts(maxResults: 50);
  }

  @override
  void didUpdateWidget(covariant WebSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery && widget.initialQuery != null) {
      final q = widget.initialQuery!;
      setState(() {
        if (q == 'Tìm sân gần tôi') {
          _sortBy = 'distance';
          _searchCtrl.clear();
        } else if (q == 'Giá dưới 100k/h') {
          _maxPrice = 100000;
          _searchCtrl.clear();
        } else if (q == 'Sân có đèn LED') {
          _selectedAmenities = ['Đèn LED'];
          _searchCtrl.clear();
        } else if (q == 'Sân có HLV') {
          _selectedAmenities = ['Huấn luyện viên'];
          _searchCtrl.clear();
        } else {
          _searchCtrl.text = q;
        }
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
      if (_selectedAmenities.isNotEmpty) {
        // Court must have all selected amenities
        for (final amenity in _selectedAmenities) {
          if (!c.amenities.any((a) => a.toLowerCase() == amenity.toLowerCase())) {
            matchAmenities = false;
            break;
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: Column(
        children: [
          WebNavbar(
            selectedIndex: 1,
            onNavTap: (i) => widget.onTabChange?.call(i),
          ),
          Expanded(
            child: FutureBuilder<List<CourtWithDistance>>(
              future: _future,
              builder: (context, snap) {
                final all = snap.data ?? [];
                final courts = snap.connectionState == ConnectionState.done
                    ? _filtered(all)
                    : <CourtWithDistance>[];

                final screenWidth = MediaQuery.of(context).size.width;
                final isDesktop = screenWidth > 900;

                final filterPanel = Container(
                  width: isDesktop ? 280 : double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        right: isDesktop ? const BorderSide(color: AppTheme.borderLight) : BorderSide.none,
                        bottom: !isDesktop ? const BorderSide(color: AppTheme.borderLight) : BorderSide.none,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _FilterPanel(
                      maxPrice: _maxPrice,
                      minRating: _minRating,
                      sortBy: _sortBy,
                      status: _status,
                      onMaxPriceChanged: (v) =>
                          setState(() => _maxPrice = v),
                      onMinRatingChanged: (v) =>
                          setState(() => _minRating = v),
                      onSortByChanged: (v) =>
                          setState(() => _sortBy = v),
                      onStatusChanged: (v) =>
                          setState(() => _status = v),
                      selectedAmenities: _selectedAmenities,
                      onAmenitiesChanged: (amenity, isSelected) {
                        setState(() {
                          if (isSelected) {
                            if (!_selectedAmenities.contains(amenity)) {
                              _selectedAmenities.add(amenity);
                            }
                          } else {
                            _selectedAmenities.remove(amenity);
                          }
                        });
                      },
                      onReset: () => setState(() {
                        _maxPrice = 300000;
                        _minRating = 0;
                        _sortBy = 'distance';
                        _status = 'all';
                        _selectedAmenities = [];
                      }),
                    ),
                  ),
                );

                final resultsPanel = Expanded(
                  flex: isDesktop ? 1 : 0,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSearchHeader(courts.length,
                            snap.connectionState == ConnectionState.waiting),
                        if (snap.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.primary),
                            ),
                          )
                        else if (courts.isEmpty)
                          _buildEmpty()
                        else
                          _buildGrid(courts),
                        WebFooter(
                          onNavTap: (i) => widget.onTabChange?.call(i),
                        ),
                      ],
                    ),
                  ),
                );

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      filterPanel,
                      resultsPanel,
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        filterPanel,
                        resultsPanel.child, // take out from Expanded
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(int count, bool loading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.softShadow,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Tìm sân theo tên hoặc địa chỉ...',
                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                loading ? 'Đang tải...' : 'Tìm thấy $count sân',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<CourtWithDistance> courts) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: LayoutBuilder(builder: (context, bc) {
        int cols = bc.maxWidth > 900 ? 3 : (bc.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.82,
          ),
          itemCount: courts.length,
          itemBuilder: (context, i) {
            final item = courts[i];
            return WebCourtCard(
              court: item.court,
              distanceKm: item.distanceKm,
              onViewDetails: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BookingScreen(initialCourt: item.court)),
              ),
              onBookNow: () {
                final auth = Provider.of<AuthService>(context, listen: false);
                if (!auth.isAuthenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Vui lòng đăng nhập để đặt sân'),
                    backgroundColor: AppTheme.error,
                  ));
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BookingScreen(initialCourt: item.court)),
                );
              },
            );
          },
        );
      }),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textMuted),
          SizedBox(height: 16),
          Text('Không tìm thấy sân phù hợp',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary)),
          SizedBox(height: 6),
          Text('Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

// ── Filter Panel ──────────────────────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  final double maxPrice;
  final double minRating;
  final String sortBy;
  final String status;
  final ValueChanged<double> onMaxPriceChanged;
  final ValueChanged<double> onMinRatingChanged;
  final ValueChanged<String> onSortByChanged;
  final ValueChanged<String> onStatusChanged;
  final List<String> selectedAmenities;
  final void Function(String amenity, bool isSelected) onAmenitiesChanged;
  final VoidCallback onReset;

  const _FilterPanel({
    required this.maxPrice,
    required this.minRating,
    required this.sortBy,
    required this.status,
    required this.onMaxPriceChanged,
    required this.onMinRatingChanged,
    required this.onSortByChanged,
    required this.onStatusChanged,
    required this.selectedAmenities,
    required this.onAmenitiesChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bộ lọc',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary)),
            TextButton(
              onPressed: onReset,
              style:
                  TextButton.styleFrom(foregroundColor: AppTheme.textMuted),
              child: const Text('Đặt lại', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const Divider(color: AppTheme.borderLight),
        const SizedBox(height: 16),

        // Sort by
        _FilterLabel('Sắp xếp theo'),
        const SizedBox(height: 10),
        ...[
          ('distance', 'Gần nhất'),
          ('price', 'Giá thấp nhất'),
          ('rating', 'Đánh giá cao nhất'),
        ].map((e) => _RadioItem(
              label: e.$2,
              value: e.$1,
              groupValue: sortBy,
              onChanged: onSortByChanged,
            )),
        const SizedBox(height: 20),
        const Divider(color: AppTheme.borderLight),
        const SizedBox(height: 16),

        // Price
        _FilterLabel('Giá tối đa / giờ'),
        const SizedBox(height: 6),
        Text(
          '${(maxPrice / 1000).toStringAsFixed(0)}k VNĐ',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary,
            thumbColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.borderLight,
            overlayColor: AppTheme.primary.withOpacity(0.1),
          ),
          child: Slider(
            value: maxPrice,
            min: 30000,
            max: 300000,
            divisions: 27,
            onChanged: onMaxPriceChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('30k', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            Text('300k', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: AppTheme.borderLight),
        const SizedBox(height: 16),

        // Min rating
        _FilterLabel('Đánh giá tối thiểu'),
        const SizedBox(height: 10),
        ...[0.0, 3.0, 4.0, 4.5].map((v) {
          return _RadioItem(
            label: v == 0 ? 'Tất cả' : '${v.toStringAsFixed(1)} sao trở lên',
            value: v.toString(),
            groupValue: minRating.toString(),
            onChanged: (s) => onMinRatingChanged(double.parse(s)),
          );
        }),
        const SizedBox(height: 20),
        const Divider(color: AppTheme.borderLight),
        const SizedBox(height: 16),

        // Amenities
        _FilterLabel('Tiện ích'),
        const SizedBox(height: 10),
        ...['Đèn LED', 'Huấn luyện viên', 'Wifi', 'Nước uống', 'Gửi xe'].map((amenity) {
          final isSelected = selectedAmenities.contains(amenity);
          return Theme(
            data: Theme.of(context).copyWith(
              checkboxTheme: CheckboxThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.primary;
                  }
                  return Colors.transparent;
                }),
              ),
            ),
            child: CheckboxListTile(
              title: Text(
                amenity,
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
              value: isSelected,
              onChanged: (val) {
                if (val != null) {
                  onAmenitiesChanged(amenity, val);
                }
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: VisualDensity.compact,
              activeColor: AppTheme.primary,
            ),
          );
        }),
        const SizedBox(height: 20),
        const Divider(color: AppTheme.borderLight),
        const SizedBox(height: 16),

        // Status
        _FilterLabel('Trạng thái sân'),
        const SizedBox(height: 10),
        ...[
          ('all', 'Tất cả'),
          ('active', 'Đang hoạt động'),
          ('maintenance', 'Đang bảo trì'),
        ].map((e) => _RadioItem(
              label: e.$2,
              value: e.$1,
              groupValue: status,
              onChanged: onStatusChanged,
            )),
      ],
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String text;
  const _FilterLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary));
  }
}

class _RadioItem extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  const _RadioItem(
      {required this.label,
      required this.value,
      required this.groupValue,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      selected ? AppTheme.primary : AppTheme.textMuted,
                  width: 2,
                ),
                color: selected ? AppTheme.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 11)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
