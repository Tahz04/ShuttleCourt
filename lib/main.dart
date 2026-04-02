import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quynh/booking/booking_screen.dart';
import 'package:quynh/map/map_screen.dart';
import 'package:quynh/features/matchmaking/screens/matchmaking_screen.dart';
import 'package:quynh/auth/auth_service.dart';
import 'package:quynh/auth/profile_screen.dart';
import 'package:quynh/auth/login_screen.dart';
import 'package:quynh/models/badminton_court.dart';
import 'package:quynh/services/location_service.dart';
import 'package:quynh/models/booking.dart';
import 'package:intl/intl.dart';
import 'package:quynh/services/api_booking_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const BadmintonApp(),
    ),
  );
}

class BadmintonApp extends StatelessWidget {
  const BadmintonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhóm 9 - Đặt Sân Cầu Lông',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const BookingHistoryScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Bản đồ'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Lịch đặt'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<CourtWithDistance>> _nearestCourtsFuture;

  @override
  void initState() {
    super.initState();
    _nearestCourtsFuture = LocationService.getNearestCourts(maxResults: 5);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chào buổi sáng,', style: TextStyle(fontSize: 14, color: Colors.white70)),
            Text('Vợt Thủ Nhóm 6', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.green),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Autocomplete<String>(
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreen(searchQuery: selection),
                  ),
                );
              },

              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {


                return TextField(
                  controller: controller,
                  focusNode: focusNode,

                  onSubmitted: (value) {
                    if (value.trim().isEmpty) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreen(searchQuery: value),
                      ),
                    );
                  },

                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sân cầu lông...',
                    prefixIcon: const Icon(Icons.search),

                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        final value = controller.text;

                        if (value.trim().isEmpty) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapScreen(
                              searchQuery: value,
                              isGlobalSearch: true,
                            ),
                          ),
                        );
                      },
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sân Gần Bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Xem bản đồ',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<CourtWithDistance>>(
              future: _nearestCourtsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(
                        'Không tìm thấy sân gần bạn',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  );
                }

                final nearestCourts = snapshot.data!;

                return SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: nearestCourts.length,
                    itemBuilder: (context, index) {
                      return CourtCard(data: nearestCourts[index]);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Khám phá tính năng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                // Nút Đặt sân ngay - Bắt buộc đăng nhập
                InkWell(
                  onTap: () {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    if (authService.isAuthenticated) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BookingScreen()),
                      );
                    } else {
                      _showLoginRequiredDialog(context);
                    }
                  },
                  child: _buildFeatureButton(Icons.sports_tennis, 'Đặt sân ngay', Colors.orange),
                ),
                // Nút Tìm người ghép - Bắt buộc đăng nhập
                InkWell(
                  onTap: () {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    if (authService.isAuthenticated) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MatchmakingScreen()),
                      );
                    } else {
                      _showLoginRequiredDialog(context);
                    }
                  },
                  child: _buildFeatureButton(Icons.group, 'Tìm người ghép', Colors.blue),
                ),
                _buildFeatureButton(Icons.store, 'Dành cho Chủ sân', Colors.purple),
                _buildFeatureButton(Icons.star, 'Đánh giá sân', Colors.amber),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu đăng nhập'),
        content: const Text('Bạn cần đăng nhập để sử dụng tính năng này. Vui lòng đăng nhập hoặc đăng ký tài khoản.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Đăng nhập', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class CourtCard extends StatelessWidget {
  final CourtWithDistance data;

  const CourtCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapScreen(searchQuery: data.court.name),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: const Center(
                child: Icon(Icons.sports_tennis, size: 40, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.court.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${data.court.rating} (${data.court.reviews})',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.distanceKm == 0
                        ? 'Không xác định vị trí'
                        : '${data.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${data.court.pricePerHour.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ/giờ',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  late Future<List<Booking>> _bookingsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBookings();
  }
  @override
  void didUpdateWidget(covariant BookingHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadBookings();
  }
  void _loadBookings() {
    final auth = Provider.of<AuthService>(context, listen: false);

    if (auth.user == null) {
      _bookingsFuture = Future.value([]);
      return;
    }

    int userId = int.parse(auth.user!.id);

    _bookingsFuture = ApiBookingService.getBookings(userId).then((data) {
      return data.map<Booking>((json) {
        return Booking(
          id: json['id'].toString(),
          courtName: json['court_name'],
          courtAddress: json['court_address'],
          slot: json['slot'],
          date: DateTime.tryParse(json['booking_date']) ?? DateTime.now(),
          price: double.parse(json['price'].toString()),
          paymentMethod: json['payment_method'] ?? '',
          createdAt: DateTime.parse(json['created_at']).toLocal(),
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Đặt Sân', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Booking>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}', style: TextStyle(color: Colors.red)),
            );
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có lịch đặt sân nào',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // Sắp xếp theo ngày tạo, mới nhất trước
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sports_tennis, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.courtName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        booking.courtAddress,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Ngày: ${DateFormat('dd/MM/yyyy').format(booking.date)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Khung giờ: ${booking.slot}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.payment, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Thanh toán: ${booking.paymentMethod}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${booking.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\\d)(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]},')}đ',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đặt lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(booking.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
