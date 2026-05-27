import 'package:shuttlecourt/services/location_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shuttlecourt/booking/booking_screen.dart';
import 'package:shuttlecourt/config/api_config.dart';
import 'package:shuttlecourt/models/badminton_court.dart';
import 'package:shuttlecourt/web/web_court_detail_dialog.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_styles.dart';

class WebMapPage extends StatefulWidget {
  final String? searchQuery;
  final Function(int, {String? query})? onTabChange;

  const WebMapPage({super.key, this.searchQuery, this.onTabChange});

  @override
  State<WebMapPage> createState() => _WebMapPageState();
}

class _WebMapPageState extends State<WebMapPage>
    with TickerProviderStateMixin {
  // ── Data ─────────────────────────────────────────────────────────────────────
  List<BadmintonCourt> _allCourts = [];
  List<BadmintonCourt> _filteredCourts = [];
  BadmintonCourt? _selectedCourt;
  bool _isLoading = true;

  // ── Map ──────────────────────────────────────────────────────────────────────
  final MapController _mapCtrl = MapController();
  static const LatLng _defaultCenter = LatLng(21.0285, 105.8542);
  double? _userLat, _userLng;

  // ── Route ────────────────────────────────────────────────────────────────────
  List<LatLng> _routePoints = [];
  double? _routeDistKm;
  int? _routeDurationMin;
  bool _isLoadingRoute = false;

  // ── Location input ───────────────────────────────────────────────────────────
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLocating = false;

  // ── Pulse animation for user marker ──────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _fetchCourts();
  }

  @override
  void didUpdateWidget(WebMapPage old) {
    super.didUpdateWidget(old);
    if (widget.searchQuery != old.searchQuery &&
        widget.searchQuery != null) {
      _filterBySearch(widget.searchQuery!);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _locationCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Fetch courts ─────────────────────────────────────────────────────────────

  Future<void> _fetchCourts() async {
    try {
      final resp = await http
          .get(Uri.parse('${ApiConfig.courtsUrl}/all'))
          .timeout(ApiConfig.connectionTimeout);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        final courts = data.map((j) => BadmintonCourt(
              id: j['id'].toString(),
              name: j['name'] ?? 'Sân Cầu Lông',
              address: j['address'] ?? '',
              latitude:
                  double.tryParse(j['latitude']?.toString() ?? '0') ?? 0.0,
              longitude:
                  double.tryParse(j['longitude']?.toString() ?? '0') ?? 0.0,
              pricePerHour:
                  double.tryParse(j['price_per_hour']?.toString() ?? '0') ??
                      0.0,
              phone: j['phone'] ?? '',
              rating: (j['rating'] ?? 4.5).toDouble(),
              reviews: (j['reviews'] ?? 10).toInt(),
              amenities: ['Wifi', 'Gửi xe', 'Nước uống'],
              mainImage: j['main_image'],
              descImage1: j['desc_image1'],
              descImage2: j['desc_image2'],
              status: j['status'] ?? 'active',
            ))
            .toList();
        if (mounted) {
          setState(() {
            _allCourts = courts;
            _isLoading = false;
          });
          if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
            _filterBySearch(widget.searchQuery!);
          } else {
            _filterCourts();
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Geolocation ───────────────────────────────────────────────────────────────

  Future<void> _autoLocate() async {
    setState(() => _isLocating = true);
    try {
      final pos = await LocationService.getCurrentLocation();
      if (!mounted) return;
      if (pos == null) {
        setState(() => _isLocating = false);
        _showSnack('Không thể lấy vị trí. Hãy nhập địa chỉ thủ công.',
            isSuccess: false);
        return;
      }
      final lat = pos.latitude;
      final lng = pos.longitude;
      setState(() {
        _userLat = lat;
        _userLng = lng;
        _isLocating = false;
      });
      _mapCtrl.move(LatLng(lat, lng), 14);
      _filterCourts();
      _showSnack('Đã xác định vị trí của bạn', isSuccess: true);
    } catch (_) {
      if (mounted) {
        setState(() => _isLocating = false);
        _showSnack('Không thể lấy vị trí. Hãy nhập địa chỉ thủ công.',
            isSuccess: false);
      }
    }
  }

  Future<void> _geocodeAddress(String address) async {
    if (address.trim().isEmpty) return;
    setState(() => _isLocating = true);
    try {
      final url =
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1&accept-language=vi';
      final resp = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'ShuttleCourtApp/1.0'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isNotEmpty && mounted) {
          final lat = double.parse(data[0]['lat'] as String);
          final lng = double.parse(data[0]['lon'] as String);
          setState(() {
            _userLat = lat;
            _userLng = lng;
            _isLocating = false;
          });
          _mapCtrl.move(LatLng(lat, lng), 14);
          _filterCourts();
          _showSnack('Vị trí: ${data[0]['display_name']}', isSuccess: true);
          return;
        }
        _showSnack('Không tìm thấy địa chỉ này', isSuccess: false);
      }
    } catch (_) {
      _showSnack('Lỗi kết nối. Thử lại sau.', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showSnack(String msg, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: isSuccess ? WebStyles.brand : WebStyles.cta,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Filter ────────────────────────────────────────────────────────────────────

  void _filterCourts() {
    if (_userLat != null && _userLng != null) {
      final sorted = [..._allCourts]
        ..sort((a, b) => a
            .distanceTo(_userLat!, _userLng!)
            .compareTo(b.distanceTo(_userLat!, _userLng!)));
      setState(() => _filteredCourts = sorted);
    } else {
      setState(() => _filteredCourts = _allCourts);
    }
  }

  void _filterBySearch(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filteredCourts = _allCourts
          .where((c) =>
              c.name.toLowerCase().contains(lower) ||
              c.address.toLowerCase().contains(lower))
          .toList();
    });
    if (_filteredCourts.isNotEmpty) {
      _mapCtrl.move(
        LatLng(_filteredCourts.first.latitude, _filteredCourts.first.longitude),
        14.5,
      );
    }
  }

  // ── Route ─────────────────────────────────────────────────────────────────────

  Future<void> _getRoute(BadmintonCourt court) async {
    if (_userLat == null) {
      _showSnack('Hãy xác định vị trí của bạn trước', isSuccess: false);
      return;
    }
    setState(() {
      _routePoints = [];
      _routeDistKm = null;
      _routeDurationMin = null;
      _isLoadingRoute = true;
    });
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/$_userLng,$_userLat;${court.longitude},${court.latitude}?overview=full&geometries=geojson';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final route = data['routes'][0];
        final coords = route['geometry']['coordinates'] as List;
        final points = coords
            .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
            .toList();
        if (mounted) {
          setState(() {
            _routePoints = points;
            _routeDistKm = (route['distance'] as num) / 1000.0;
            _routeDurationMin = ((route['duration'] as num) / 60.0).ceil();
            _isLoadingRoute = false;
          });
          _mapCtrl.fitCamera(CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(60),
          ));
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
        _showSnack('Không lấy được đường đi', isSuccess: false);
      }
    }
  }

  void _clearRoute() => setState(() {
        _routePoints = [];
        _routeDistKm = null;
        _routeDurationMin = null;
      });

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebStyles.dark950,
      body: Column(
        children: [
          WebNavbar(
            selectedIndex: 2,
            onNavTap: (i) => widget.onTabChange?.call(i),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 420, child: _buildSidebar()),
                Expanded(child: _buildMap()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: WebStyles.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: WebStyles.brandGrad,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.map_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Khám phá bản đồ',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: WebStyles.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Tìm sân cầu lông gần bạn',
                            style: TextStyle(
                                fontSize: 11, color: WebStyles.inkFaint),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Location input ───────────────────────────────
                _InputBox(
                  controller: _locationCtrl,
                  hintText: 'Nhập địa chỉ của bạn...',
                  leadingIcon: Icons.location_on_rounded,
                  leadingColor: WebStyles.brand,
                  onSubmitted: _geocodeAddress,
                  trailing: _isLocating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: WebStyles.brand),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Auto-detect button
                            GestureDetector(
                              onTap: _autoLocate,
                              child: Tooltip(
                                message: 'Tự động xác định vị trí',
                                child: Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: WebStyles.brand
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.my_location_rounded,
                                    size: 16,
                                    color: WebStyles.brand,
                                  ),
                                ),
                              ),
                            ),
                            // Search button
                            GestureDetector(
                              onTap: () =>
                                  _geocodeAddress(_locationCtrl.text),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  gradient: WebStyles.brandGrad,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Tìm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 8),

                // ── Court search ─────────────────────────────────
                _InputBox(
                  controller: _searchCtrl,
                  hintText: 'Tìm tên sân...',
                  leadingIcon: Icons.search_rounded,
                  leadingColor: WebStyles.inkFaint,
                  onSubmitted: _filterBySearch,
                ),
              ],
            ),
          ),

          // ── Court count badge ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: WebStyles.brand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: WebStyles.brand.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports_tennis_rounded,
                          color: WebStyles.brand, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        _isLoading
                            ? 'Đang tải...'
                            : '${_filteredCourts.length} sân',
                        style: const TextStyle(
                          color: WebStyles.brand,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_userLat != null)
                  Row(
                    children: [
                      const Icon(Icons.near_me_rounded,
                          size: 12, color: WebStyles.inkFaint),
                      const SizedBox(width: 4),
                      const Text('Gần bạn nhất',
                          style: TextStyle(
                              fontSize: 11, color: WebStyles.inkFaint)),
                    ],
                  ),
              ],
            ),
          ),

          // ── Court list ────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: WebStyles.brand,
                      strokeWidth: 2,
                    ),
                  )
                : _filteredCourts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48,
                                color: WebStyles.inkFaint
                                    .withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            const Text('Không tìm thấy sân',
                                style: TextStyle(
                                    color: WebStyles.inkFaint, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: _filteredCourts.length,
                        itemBuilder: (ctx, i) {
                          final court = _filteredCourts[i];
                          return _CourtSidebarItem(
                            court: court,
                            isSelected: _selectedCourt?.id == court.id,
                            userLat: _userLat,
                            userLng: _userLng,
                            onTap: () {
                              setState(() => _selectedCourt = court);
                              _mapCtrl.move(
                                LatLng(court.latitude, court.longitude),
                                15,
                              );
                            },
                            onRoute: () => _getRoute(court),
                            onDetail: () => showCourtDetailDialog(
                              ctx,
                              court,
                              distanceKm: _userLat != null
                                  ? court.distanceTo(_userLat!, _userLng!)
                                  : 0,
                            ),
                            onBook: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookingScreen(initialCourt: court),
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

  // ── Map ───────────────────────────────────────────────────────────────────────

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _userLat != null
                ? LatLng(_userLat!, _userLng!)
                : _defaultCenter,
            initialZoom: 13,
            onTap: (_, __) {
              if (_routePoints.isNotEmpty) _clearRoute();
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.shuttlecourt.app',
            ),
            // Route polylines
            if (_routePoints.isNotEmpty) ...[
              PolylineLayer(polylines: [
                Polyline(
                  points: _routePoints,
                  color: const Color(0x331565C0),
                  strokeWidth: 10,
                ),
              ]),
              PolylineLayer(polylines: [
                Polyline(
                  points: _routePoints,
                  color: const Color(0xFF2196F3),
                  strokeWidth: 5,
                  borderColor: Colors.white,
                  borderStrokeWidth: 1.5,
                ),
              ]),
            ],
            // Markers
            MarkerLayer(markers: [
              // User location
              if (_userLat != null && _userLng != null)
                Marker(
                  point: LatLng(_userLat!, _userLng!),
                  width: 60,
                  height: 60,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 60 * _pulseAnim.value,
                          height: 60 * _pulseAnim.value,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x222196F3),
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0x442196F3),
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2196F3),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x552196F3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Court markers (max 20)
              ..._filteredCourts.take(20).map((court) {
                final isSel = _selectedCourt?.id == court.id;
                final isMaint = court.status == 'maintenance';
                return Marker(
                  point: LatLng(court.latitude, court.longitude),
                  width: isSel ? 52 : 42,
                  height: isSel ? 52 : 42,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedCourt = court);
                      _mapCtrl.move(
                          LatLng(court.latitude, court.longitude), 15);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isMaint
                            ? const Color(0xFFFF5252)
                            : isSel
                                ? WebStyles.brand
                                : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isMaint
                              ? const Color(0xFFD32F2F)
                              : WebStyles.brand,
                          width: isSel ? 0 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSel
                                ? WebStyles.brand.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.18),
                            blurRadius: isSel ? 12 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.sports_tennis_rounded,
                        color: (isSel || isMaint) ? Colors.white : WebStyles.brand,
                        size: isSel ? 22 : 17,
                      ),
                    ),
                  ),
                );
              }),
            ]),
          ],
        ),

        // ── Route info banner ──────────────────────────────────
        if (_routeDistKm != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x331565C0),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.straighten_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${_routeDistKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '~$_routeDurationMin phút',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearRoute,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Loading route ──────────────────────────────────────
        if (_isLoadingRoute)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2196F3)),
                  ),
                  SizedBox(width: 12),
                  Text('Đang tìm đường đi...',
                      style: TextStyle(
                          color: WebStyles.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

        // ── FABs ──────────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 24,
          child: Column(
            children: [
              if (_routePoints.isNotEmpty) ...[
                _MapFab(
                  icon: Icons.close_rounded,
                  color: Colors.red,
                  tooltip: 'Xóa đường đi',
                  onTap: _clearRoute,
                ),
                const SizedBox(height: 10),
              ],
              _MapFab(
                icon: _isLocating
                    ? Icons.hourglass_empty_rounded
                    : Icons.my_location_rounded,
                color: WebStyles.brand,
                tooltip: 'Vị trí của tôi',
                onTap: _userLat != null
                    ? () => _mapCtrl.move(
                        LatLng(_userLat!, _userLng!), 15)
                    : _autoLocate,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COURT SIDEBAR ITEM
// ══════════════════════════════════════════════════════════════════════════════

class _CourtSidebarItem extends StatefulWidget {
  final BadmintonCourt court;
  final bool isSelected;
  final double? userLat, userLng;
  final VoidCallback onTap;
  final VoidCallback onRoute;
  final VoidCallback onDetail;
  final VoidCallback onBook;

  const _CourtSidebarItem({
    required this.court,
    required this.isSelected,
    this.userLat,
    this.userLng,
    required this.onTap,
    required this.onRoute,
    required this.onDetail,
    required this.onBook,
  });

  @override
  State<_CourtSidebarItem> createState() => _CourtSidebarItemState();
}

class _CourtSidebarItemState extends State<_CourtSidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final court = widget.court;
    final isMaint = court.status == 'maintenance';
    final distance = (widget.userLat != null)
        ? court.distanceTo(widget.userLat!, widget.userLng!).toStringAsFixed(1)
        : null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? WebStyles.brand.withValues(alpha: 0.05)
                : _hovered
                    ? WebStyles.bg
                    : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? WebStyles.brand
                  : _hovered
                      ? WebStyles.brand.withValues(alpha: 0.3)
                      : WebStyles.border,
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: _hovered || widget.isSelected
                ? [
                    BoxShadow(
                      color: WebStyles.brand.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Name + status ──────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      court.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: widget.isSelected
                            ? WebStyles.brand
                            : WebStyles.ink,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isMaint
                          ? const Color(0xFFFF5252).withValues(alpha: 0.1)
                          : WebStyles.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isMaint ? 'Bảo trì' : 'Hoạt động',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isMaint
                            ? const Color(0xFFD32F2F)
                            : WebStyles.brandDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Address ────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: WebStyles.inkFaint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      court.address,
                      style: const TextStyle(
                          fontSize: 11, color: WebStyles.inkFaint, height: 1.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Rating + distance + price ──────────────────────
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 13, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 3),
                  Text(
                    court.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: WebStyles.inkMid),
                  ),
                  Text(
                    ' (${court.reviews})',
                    style: const TextStyle(
                        fontSize: 11, color: WebStyles.inkFaint),
                  ),
                  if (distance != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.near_me_rounded,
                        size: 11, color: WebStyles.inkFaint),
                    const SizedBox(width: 3),
                    Text(
                      '${distance}km',
                      style: const TextStyle(
                          fontSize: 11,
                          color: WebStyles.inkFaint,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${(court.pricePerHour / 1000).toStringAsFixed(0)}k/giờ',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: WebStyles.brand,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Action buttons ─────────────────────────────────
              Row(
                children: [
                  // Chi tiết
                  Expanded(
                    child: _SidebarBtn(
                      label: 'Chi tiết',
                      icon: Icons.info_outline_rounded,
                      color: WebStyles.inkMid,
                      bgColor: WebStyles.bg,
                      borderColor: WebStyles.border,
                      onTap: widget.onDetail,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Đường đi
                  Expanded(
                    child: _SidebarBtn(
                      label: 'Đường đi',
                      icon: Icons.directions_rounded,
                      color: const Color(0xFF1565C0),
                      bgColor: const Color(0xFFEFF6FF),
                      borderColor: const Color(0xFFBFDBFE),
                      onTap: widget.onRoute,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Đặt sân
                  Expanded(
                    child: _SidebarBtn(
                      label: 'Đặt ngay',
                      icon: Icons.flash_on_rounded,
                      color: Colors.white,
                      bgColor: WebStyles.brand,
                      borderColor: WebStyles.brand,
                      onTap: isMaint ? () {} : widget.onBook,
                      disabled: isMaint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color, bgColor, borderColor;
  final VoidCallback onTap;
  final bool disabled;

  const _SidebarBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: disabled ? WebStyles.border : bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: disabled ? WebStyles.border : borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 13, color: disabled ? WebStyles.inkFaint : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: disabled ? WebStyles.inkFaint : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INPUT BOX
// ══════════════════════════════════════════════════════════════════════════════

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData leadingIcon;
  final Color leadingColor;
  final Function(String) onSubmitted;
  final Widget? trailing;

  const _InputBox({
    required this.controller,
    required this.hintText,
    required this.leadingIcon,
    required this.leadingColor,
    required this.onSubmitted,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WebStyles.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebStyles.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(leadingIcon, color: leadingColor, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle:
                    const TextStyle(color: WebStyles.inkFaint, fontSize: 13),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 11),
              ),
              style: const TextStyle(fontSize: 13, color: WebStyles.ink),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MAP FAB
// ══════════════════════════════════════════════════════════════════════════════

class _MapFab extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _MapFab({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
