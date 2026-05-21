import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shuttlecourt/models/badminton_court.dart';
import 'package:shuttlecourt/config/api_config.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/features/reviews/screens/court_reviews_screen.dart';
import 'package:shuttlecourt/booking/booking_screen.dart';

class MapScreen extends StatefulWidget {
  final String? searchQuery;
  final bool isGlobalSearch;

  const MapScreen({super.key, this.searchQuery, this.isGlobalSearch = false});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  List<BadmintonCourt> allCourtsFromDB = [];
  List<BadmintonCourt> filteredCourts = [];
  BadmintonCourt? selectedCourt;

  final MapController mapController = MapController();
  double? userLat;
  double? userLng;
  bool isLoading = true;
  List<LatLng> routePoints = [];
  double? routeDistanceKm;
  int? routeDurationMin;
  bool isLoadingRoute = false;
  bool _isPickingLocation = false;
  static const LatLng defaultCenter = LatLng(21.0285, 105.8542);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _routeInfoController;
  late Animation<double> _routeInfoSlideAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 🌐 WEB: Skip pulse animation to reduce CPU usage
    if (!kIsWeb) {
      _pulseController.repeat(reverse: true);
    }

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _routeInfoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _routeInfoSlideAnimation = CurvedAnimation(
      parent: _routeInfoController,
      curve: Curves.easeOutCubic,
    );

    _initMap();
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery &&
        widget.searchQuery != null) {
      _search(widget.searchQuery!);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _routeInfoController.dispose();
    super.dispose();
  }

  Future<void> _initMap() async {
    // Run both tasks in parallel to speed up initial load
    await Future.wait([_getCurrentLocation(), _fetchAllCourts()]);
  }

  Future<void> _fetchAllCourts() async {
    final String apiUrl = '${ApiConfig.courtsUrl}/all';
    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(ApiConfig.connectionTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<BadmintonCourt> loadedCourts = data.map((json) {
          return BadmintonCourt(
            id: json['id'].toString(),
            name: json['name'] ?? 'Sân Cầu Lông',
            address: json['address'] ?? 'Đang cập nhật địa chỉ',
            latitude:
                double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
            longitude:
                double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
            pricePerHour:
                double.tryParse(json['price_per_hour']?.toString() ?? '0') ??
                0.0,
            phone: json['phone'] ?? 'Liên hệ qua App',
            rating: json['rating']?.toDouble() ?? 4.5,
            reviews: json['reviews']?.toInt() ?? 10,
            amenities: ['Wifi', 'Gửi xe', 'Nước uống'],
            mainImage: json['main_image'],
            descImage1: json['desc_image1'],
            descImage2: json['desc_image2'],
            status: json['status'] ?? 'active',
          );
        }).toList();

        if (mounted) {
          setState(() {
            allCourtsFromDB = loadedCourts;
            isLoading = false;
          });
          if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
            _search(widget.searchQuery!);
          } else {
            _filterNearbyCourts();
          }
        }
      } else {
        // Handle non-200 responses
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // 🌐 Skip geolocator on web (not supported)
      if (kIsWeb) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 3),
          ),
        );
        if (mounted) {
          setState(() {
            userLat = position.latitude;
            userLng = position.longitude;
          });
        }
      }
    } catch (_) {}
  }

  void _filterNearbyCourts() {
    setState(() {
      if (userLat != null && userLng != null && !widget.isGlobalSearch) {
        filteredCourts = allCourtsFromDB
            .where((c) => c.distanceTo(userLat!, userLng!) <= 10)
            .toList();
        filteredCourts.sort(
          (a, b) => a
              .distanceTo(userLat!, userLng!)
              .compareTo(b.distanceTo(userLat!, userLng!)),
        );
      } else {
        filteredCourts = allCourtsFromDB;
      }
    });
  }

  void _search(String query) {
    setState(() {
      filteredCourts = allCourtsFromDB
          .where(
            (court) =>
                court.name.toLowerCase().contains(query.toLowerCase()) ||
                court.address.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });

    if (filteredCourts.isNotEmpty) {
      final first = filteredCourts.first;
      mapController.move(LatLng(first.latitude, first.longitude), 14.5);
      selectedCourt = first;
    }
  }

  void _moveToCourt(BadmintonCourt court) {
    mapController.move(LatLng(court.latitude, court.longitude), 15);
  }

  void _clearRoute() {
    setState(() {
      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
    });
    _routeInfoController.reverse();
  }

  /// 🌐 Optimize marker rendering for web: limit visible markers
  List<BadmintonCourt> _getVisibleCourts() {
    if (kIsWeb && filteredCourts.length > 20) {
      return filteredCourts.take(20).toList();
    }
    return filteredCourts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      body: MouseRegion(
      cursor: _isPickingLocation ? SystemMouseCursors.precise : MouseCursor.defer,
      child: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: userLat != null
                  ? LatLng(userLat!, userLng!)
                  : defaultCenter,
              initialZoom: 13,
              onTap: (_, latlng) {
                if (_isPickingLocation) {
                  setState(() {
                    userLat = latlng.latitude;
                    userLng = latlng.longitude;
                    _isPickingLocation = false;
                    routePoints = [];
                    routeDistanceKm = null;
                    routeDurationMin = null;
                  });
                  _filterNearbyCourts();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Row(children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Expanded(child: Text('Đã đặt vị trí của bạn trên bản đồ')),
                    ]),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ));
                } else if (routePoints.isNotEmpty) {
                  _clearRoute();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.shuttlecourt.app',
              ),
              // Route Polyline with border effect
              if (routePoints.isNotEmpty) ...[
                // Shadow/border polyline
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: const Color(0xFF1565C0).withOpacity(0.3),
                      strokeWidth: 10,
                    ),
                  ],
                ),
                // Main route polyline
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: const Color(0xFF2196F3),
                      strokeWidth: 5,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              ],
              // Markers
              MarkerLayer(
                markers: [
                  // User location marker with pulse animation
                  if (userLat != null && userLng != null)
                    Marker(
                      point: LatLng(userLat!, userLng!),
                      width: 60,
                      height: 60,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer pulse ring
                              Container(
                                width: 60 * _pulseAnimation.value,
                                height: 60 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFF2196F3,
                                  ).withOpacity(0.15),
                                ),
                              ),
                              // Middle ring
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFF2196F3,
                                  ).withOpacity(0.2),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                              // Inner dot
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
                          );
                        },
                      ),
                    ),
                  // Route start marker
                  if (routePoints.isNotEmpty && userLat != null)
                    Marker(
                      point: LatLng(userLat!, userLng!),
                      width: 40,
                      height: 50,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x552196F3),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Bạn',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Court markers (optimized for web with limit)
                  ..._getVisibleCourts().map((court) {
                    final isSelected = selectedCourt?.id == court.id;
                    final isRouteTarget = routePoints.isNotEmpty && isSelected;
                    return Marker(
                      point: LatLng(court.latitude, court.longitude),
                      width: isSelected ? 56 : 44,
                      height: isSelected ? 64 : 52,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedCourt = court);
                          _moveToCourt(court);
                          _showCourtDetails(context, court);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: court.status == 'maintenance'
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFFF5252),
                                          Color(0xFFD32F2F),
                                        ],
                                      )
                                    : isRouteTarget
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF1565C0),
                                          Color(0xFF0D47A1),
                                        ],
                                      )
                                    : isSelected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF00C853),
                                          Color(0xFF009624),
                                        ],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.grey.shade100,
                                        ],
                                      ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: isRouteTarget
                                        ? const Color(0x55FF5252)
                                        : isSelected
                                        ? const Color(0x5500C853)
                                        : const Color(0x33000000),
                                    blurRadius: isSelected ? 12 : 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: isSelected ? 2.5 : 2,
                                ),
                              ),
                            ),
                            // Small triangle pointer
                            CustomPaint(
                              size: const Size(10, 6),
                              painter: _TrianglePainter(
                                color: isRouteTarget
                                    ? const Color(0xFFD32F2F)
                                    : isSelected
                                    ? const Color(0xFF009624)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Top gradient overlay for status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.search_rounded,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onSubmitted: _search,
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tìm sân cầu lông...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // My Location FAB
          Positioned(
            right: 16,
            bottom: 160,
            child: Column(
              children: [
                // Pick location button (manual location setting)
                _buildMapFab(
                  icon: _isPickingLocation
                      ? Icons.location_on_rounded
                      : Icons.edit_location_alt_rounded,
                  color: _isPickingLocation ? AppTheme.highlight : AppTheme.primary,
                  onTap: () => setState(() => _isPickingLocation = !_isPickingLocation),
                  tooltip: 'Đặt vị trí thủ công',
                  marginBottom: 12,
                ),
                // Clear route button
                if (routePoints.isNotEmpty)
                  _buildMapFab(
                    icon: Icons.close_rounded,
                    color: AppTheme.error,
                    onTap: _clearRoute,
                    tooltip: 'Xóa đường đi',
                    marginBottom: 12,
                  ),
                // My location button
                _buildMapFab(
                  icon: Icons.my_location_rounded,
                  color: AppTheme.accent,
                  onTap: () {
                    if (userLat != null && userLng != null) {
                      mapController.move(LatLng(userLat!, userLng!), 15);
                    }
                  },
                  tooltip: 'Vị trí của tôi',
                ),
              ],
            ),
          ),

          // Route Info Panel
          if (routeDistanceKm != null && routeDurationMin != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(_routeInfoSlideAnimation),
                child: FadeTransition(
                  opacity: _routeInfoSlideAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedCourt?.name ?? 'Điểm đến',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildRouteInfoChip(
                                    Icons.straighten_rounded,
                                    '${routeDistanceKm!.toStringAsFixed(1)} km',
                                  ),
                                  const SizedBox(width: 12),
                                  _buildRouteInfoChip(
                                    Icons.access_time_rounded,
                                    '~$routeDurationMin phút',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearRoute,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Loading route indicator
          if (isLoadingRoute)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Đang tìm đường đi...',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Manual location picking mode banner
          if (_isPickingLocation)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.highlight, Color(0xFFD68A5E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.highlight.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Chế độ chọn vị trí thủ công',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Nhấn vào bản đồ để đặt vị trí của bạn',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isPickingLocation = false),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Court List
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.8),
                    Colors.white,
                  ],
                  stops: const [0, 0.3, 0.6],
                ),
              ),
              padding: const EdgeInsets.only(top: 20, bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  else if (filteredCourts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sports_tennis,
                              color: AppTheme.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              kIsWeb && filteredCourts.length > 20
                                  ? '${_getVisibleCourts().length}/${filteredCourts.length} sân hiển thị'
                                  : '${filteredCourts.length} sân gần bạn',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _getVisibleCourts().length,
                        itemBuilder: (context, index) {
                          final court = _getVisibleCourts()[index];
                          final isSelected = selectedCourt?.id == court.id;
                          final distance = userLat != null
                              ? court
                                    .distanceTo(userLat!, userLng!)
                                    .toStringAsFixed(1)
                              : null;
                          return GestureDetector(
                            onTap: () {
                              setState(() => selectedCourt = court);
                              _moveToCourt(court);
                              _showCourtDetails(context, court);
                            },
                            child: AnimatedContainer(
                              duration: kIsWeb
                                  ? Duration.zero
                                  : const Duration(milliseconds: 200),
                              width: 240,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? AppTheme.primary.withOpacity(0.15)
                                        : Colors.black.withOpacity(0.06),
                                    blurRadius: isSelected ? 16 : 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? AppTheme.primaryGradient
                                          : LinearGradient(
                                              colors: [
                                                AppTheme.primary.withOpacity(
                                                  0.1,
                                                ),
                                                AppTheme.primary.withOpacity(
                                                  0.05,
                                                ),
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.sports_tennis,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          court.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: isSelected
                                                ? AppTheme.primary
                                                : const Color(0xFF1A1A1A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFFFB300),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${court.rating}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF666666),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '(${court.reviews})',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (distance != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.near_me_rounded,
                                                size: 12,
                                                color: AppTheme.accent
                                                    .withOpacity(0.7),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${distance}km',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.accent
                                                      .withOpacity(0.8),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${(court.pricePerHour / 1000).toStringAsFixed(0)}k/h',
                                                style: const TextStyle(
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildMapFab({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
    double marginBottom = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildRouteInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _showCourtDetails(BuildContext context, BadmintonCourt court) {
    final distance = userLat != null
        ? court.distanceTo(userLat!, userLng!)
        : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Court Icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.sports_tennis_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                court.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF8E1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFFFB300),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${court.rating}',
                                          style: const TextStyle(
                                            color: Color(0xFFF57F17),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${court.reviews} đánh giá',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Image Gallery
                    if (court.mainImage != null ||
                        court.descImage1 != null ||
                        court.descImage2 != null)
                      SizedBox(
                        height: 140,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            if (court.mainImage != null)
                              _buildGalleryItem(
                                court.mainImage!,
                                'Ảnh chính',
                                isMain: true,
                              ),
                            if (court.descImage1 != null)
                              _buildGalleryItem(court.descImage1!, 'Mô tả 1'),
                            if (court.descImage2 != null)
                              _buildGalleryItem(court.descImage2!, 'Mô tả 2'),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Info Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            Icons.attach_money_rounded,
                            'Giá',
                            '${(court.pricePerHour / 1000).toStringAsFixed(0)}k/giờ',
                            AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInfoCard(
                            Icons.near_me_rounded,
                            'Khoảng cách',
                            distance != null
                                ? '${distance.toStringAsFixed(1)}km'
                                : 'N/A',
                            AppTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInfoCard(
                            Icons.phone_rounded,
                            'Liên hệ',
                            'Gọi ngay',
                            const Color(0xFF9C27B0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Address
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFD32F2F),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Địa chỉ',
                                  style: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  court.address,
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amenities
                    const Text(
                      'Tiện ích',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: court.amenities.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            amenity,
                            style: const TextStyle(
                              color: AppTheme.primaryDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Xem Đánh giá
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourtReviewsScreen(
                                courtId: int.parse(court.id),
                                courtName: court.name,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.star_rate_rounded, size: 20),
                        label: const Text(
                          'XEM ĐÁNH GIÁ (Click để thử)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accentGold,
                          side: BorderSide(
                            color: AppTheme.accentGold.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action Buttons
                    Row(
                      children: [
                        // Route button
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _showRouteToCourt(court);
                            },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1976D2),
                                    Color(0xFF1565C0),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1976D2,
                                    ).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.directions_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Đường đi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Book button
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookingScreen(initialCourt: court),
                                ),
                              );
                            },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flash_on_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Đặt Sân Ngay',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryItem(String url, String label, {bool isMain = false}) {
    return Container(
      width: isMain ? 220 : 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _showRouteToCourt(BadmintonCourt court) async {
    if (userLat == null || userLng == null) {
      if (mounted) {
        setState(() => _isPickingLocation = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.edit_location_alt_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text('Nhấn vào bản đồ để đặt vị trí của bạn trước.')),
              ],
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
      isLoadingRoute = true;
    });
    _routeInfoController.reverse();

    final start = '$userLng,$userLat';
    final end = '${court.longitude},${court.latitude}';
    final url =
        'https://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];
        final coords = route['geometry']['coordinates'] as List;
        final points = coords
            .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
            .toList();
        final distanceMeters = route['distance'] as num;
        final durationSeconds = route['duration'] as num;

        if (mounted) {
          setState(() {
            routePoints = points;
            routeDistanceKm = distanceMeters / 1000.0;
            routeDurationMin = (durationSeconds / 60.0).ceil();
            isLoadingRoute = false;
          });
          _routeInfoController.forward();
          if (points.isNotEmpty) {
            mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(points),
                padding: const EdgeInsets.fromLTRB(60, 160, 60, 180),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => isLoadingRoute = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Không lấy được đường đi.'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingRoute = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lấy đường đi: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

// Custom triangle painter for marker pointers
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
