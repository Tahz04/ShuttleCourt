import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quynh/models/badminton_court.dart';

class MapScreen extends StatefulWidget {
  final String? searchQuery;
  final bool isGlobalSearch;

  const MapScreen({
    super.key,
    this.searchQuery,
    this.isGlobalSearch = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<BadmintonCourt> filteredCourts = [];
  BadmintonCourt? selectedCourt;

  final MapController mapController = MapController();

  double? userLat;
  double? userLng;
  bool isSearching = false;
  String currentKeyword = '';
  static final LatLng center = LatLng(21.0285, 105.8542);

  List<Marker> markers = [];

  // Polyline cho đường đi
  List<LatLng> routePoints = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _search(widget.searchQuery!);
      });
    }
  }

  void _zoomToFirstResult() {
    if (filteredCourts.isNotEmpty) {
      final first = filteredCourts.first;

      mapController.move(
        LatLng(first.latitude, first.longitude),
        14,
      );
    }
  }

  /// 📍 LẤY VỊ TRÍ USER
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();

    // ✅ FIX: cập nhật state đúng cách
    setState(() {
      userLat = position.latitude;
      userLng = position.longitude;
    });

    // ✅ logic giữ nguyên
    if (!isSearching) {
      _filterNearbyCourts();

      mapController.move(
        LatLng(userLat!, userLng!),
        14,
      );
    } else {
      _initializeMarkers();
    }
  }
  /// 🔥 LỌC 5KM
  void _filterNearbyCourts() {
    if (userLat == null || userLng == null) return;

    setState(() {
      filteredCourts = sampleBadmintonCourts.where((court) {
        if (widget.isGlobalSearch) return true; // 🔥 không giới hạn

        final distance = court.distanceTo(userLat!, userLng!);
        return distance <= 5;
      }).toList();

      // 🔥 sort
      if (userLat != null && userLng != null) {
        filteredCourts.sort((a, b) =>
            a.distanceTo(userLat!, userLng!)
                .compareTo(b.distanceTo(userLat!, userLng!)));
      }
    });

    _initializeMarkers();
  }

  /// 🔥 MARKER
  void _initializeMarkers() {
    final List<Marker> newMarkers = [];

    // 👉 marker sân
    for (var court in sampleBadmintonCourts) {
      final isSelected = selectedCourt?.id == court.id;

      newMarkers.add(
        Marker(
          point: LatLng(court.latitude, court.longitude),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedCourt = court;
              });

              _moveToCourt(court);
              _showCourtDetails(context, court);
              _initializeMarkers();
            },
            child: Column(
              children: [
                Icon(
                  Icons.location_on,
                  size: 35,
                  color: isSelected ? Colors.red : Colors.green,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  color: Colors.white,
                  child: Text(
                    '${(court.pricePerHour / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(fontSize: 10),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    // 👉 marker user
    if (userLat != null && userLng != null) {
      newMarkers.add(
        Marker(
          point: LatLng(userLat!, userLng!),
          width: 80,
          height: 80,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 35,
          ),
        ),
      );
    }

    setState(() {
      markers = newMarkers;
    });
  }

  /// 🔍 SEARCH (vẫn giữ)
  void _search(String value) {
    final keyword = value.trim().toLowerCase();

    // 👉 nếu clear search → quay lại nearby
    if (keyword.isEmpty) {
      setState(() {
        isSearching = false;
        currentKeyword = '';
      });

      _filterNearbyCourts();
      return;
    }

    final results = sampleBadmintonCourts.where((court) {
      return court.name.toLowerCase().contains(keyword) ||
          court.address.toLowerCase().contains(keyword);
    }).toList();

    if (results.isEmpty) {
      setState(() {
        isSearching = true;
        currentKeyword = keyword;
        filteredCourts = [];
      });
      return;
    }

    final first = results.first;

    // ✅ update list
    setState(() {
      isSearching = true;
      currentKeyword = keyword;
      filteredCourts = results;
      selectedCourt = first;
    });

    // ✅ zoom
    mapController.move(
      LatLng(first.latitude, first.longitude),
      15,
    );

    _initializeMarkers();
  }

  /// 🎯 MOVE
  void _moveToCourt(BadmintonCourt court) {
    mapController.move(
      LatLng(court.latitude, court.longitude),
      15,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🌍 MAP
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.yourname.baitap.quynh',
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.blue,
                      strokeWidth: 6,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),

          /// 🔍 SEARCH
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // TODO: withOpacity deprecated, but .withValues() not available for Color directly. Safe to ignore for now.
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }

                  return sampleBadmintonCourts
                      .map((e) => e.name)
                      .where((name) => name
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _search(selection);
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (value) {
                          if (value.isEmpty) {
                            _search('');
                          }
                        },
                        // ✅ chỉ search khi nhấn Enter
                        onSubmitted: (value) {
                          _search(value);
                        },

                        decoration: const InputDecoration(
                          hintText: 'Tìm sân cầu lông...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      );
                },
              ),
            ),
          ),

          /// 📋 LIST
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Sân cầu lông (${filteredCourts.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: filteredCourts.isEmpty
                        ? const Center(
                      child: Text('Không tìm thấy sân nào'),
                    )
                        : ListView.builder(
                      itemCount: filteredCourts.length,
                      itemBuilder: (context, index) {
                        final court = filteredCourts[index];
                        return _buildCourtCard(context, court);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📦 CARD GIỐNG GOOGLE MAP
  Widget _buildCourtCard(BuildContext context, BadmintonCourt court) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedCourt = court;
        });

        _moveToCourt(court);
        _showCourtDetails(context, court);
        _initializeMarkers();
      },
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sports_tennis,
                    color: Colors.green, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      court.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 14),
                        Text(
                          ' ${court.rating} (${court.reviews})',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(court.pricePerHour / 1000).toStringAsFixed(0)}k/giờ',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }


  /// 📄 BOTTOM SHEET CHI TIẾT
  void _showCourtDetails(BuildContext context, BadmintonCourt court) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          court.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            Text(
                              ' ${court.rating} (${court.reviews} đánh giá)',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Địa chỉ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(court.address,
                        style: const TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Liên hệ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Text(court.phone,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Giá cước',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${(court.pricePerHour / 1000).toStringAsFixed(0)}k/giờ',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tiện ích',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: court.amenities.map((amenity) {
                  return Chip(
                    label: Text(amenity),
                    backgroundColor: Colors.green[50],
                    side: BorderSide(color: Colors.green[200]!),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đặt sân ${court.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đặt Sân Ngay',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.alt_route, color: Colors.white),
                  label: const Text(
                    'Xem đường đi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showRouteToCourt(court);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRouteToCourt(BadmintonCourt court) async {
    if (userLat == null || userLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không xác định được vị trí của bạn.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Xóa route cũ
    setState(() {
      routePoints = [];
    });

    final start = '$userLng,$userLat';
    final end = '${court.longitude},${court.latitude}';
    final url =
        'https://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        final points = coords
            .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
            .toList();
        setState(() {
          routePoints = points;
        });
        // Zoom fit route
        if (points.isNotEmpty) {
          mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(points),
              padding: const EdgeInsets.all(60),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không lấy được đường đi.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lấy đường đi: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
