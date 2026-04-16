import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:quynh/features/owner/screens/owner_registration_screen.dart';
import 'package:quynh/services/api_booking_service.dart';
import 'package:quynh/theme/app_theme.dart';
import 'package:quynh/features/owner/screens/owner_dashboard_screen.dart';
import 'package:quynh/services/court_service.dart';
import 'package:quynh/features/shop/screens/shop_screen.dart';
import 'package:quynh/features/booking/screens/booking_history_screen.dart';
import 'package:quynh/services/notification_service.dart';
import 'package:quynh/features/matchmaking/services/matchmaking_service.dart';

void main() {
  debugPrint('--- APP STARTING ---');
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
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
      title: 'ShuttleCourt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _fadeController;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const BookingHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _fadeController.reset();
      _fadeController.forward();
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          border: const Border(top: BorderSide(color: AppTheme.borderLight)),
          boxShadow: AppTheme.softShadow,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Trang chủ', 0),
                _buildNavItem(Icons.map_rounded, Icons.map_outlined, 'Bản đồ', 1),
                _buildNavItem(Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Lịch sử', 2),
                _buildNavItem(Icons.person_rounded, Icons.person_outlined, 'Tài khoản', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData activeIcon, IconData inactiveIcon, String label, int index) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppTheme.primary : AppTheme.textMuted,
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HOME SCREEN
// ═══════════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<CourtWithDistance>> _nearestCourtsFuture;

  @override
  void initState() {
    super.initState();
    _nearestCourtsFuture = LocationService.getNearestCourts(maxResults: 5);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroHeader(auth),
          _buildSearchSection(),
          _buildNearbySection(),
          _buildFeatureSection(auth),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(AuthService auth) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 32),
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chào bạn, vận động viên! 👋', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(
                      auth.isAuthenticated ? auth.user!.fullName : 'Khách chơi',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                  ],
                ),
                const UserNotificationBell(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow,
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sân cầu lông...',
              prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbySection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text('Sân gần bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary)),
             const SizedBox(height: 16),
             FutureBuilder<List<CourtWithDistance>>(
               future: _nearestCourtsFuture,
               builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
                 final list = snapshot.data ?? [];
                 return SizedBox(
                   height: 180,
                   child: ListView.builder(
                     scrollDirection: Axis.horizontal,
                     itemCount: list.length,
                     itemBuilder: (_, i) => CourtCard(data: list[i]),
                   ),
                 );
               },
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection(AuthService auth) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tiện ích', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _FeatureCard(Icons.sports_tennis_rounded, 'Đặt sân ngay', 'Nhanh chóng & tiện lợi', AppTheme.primaryGradient, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen()))),
                _FeatureCard(Icons.group_rounded, 'Ghép kèo', 'Chơi cùng đồng đội', AppTheme.accentGradient, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchmakingScreen()))),
                _FeatureCard(
                  auth.user?.role == 'owner' ? Icons.dashboard_rounded : Icons.shopping_bag_rounded,
                  auth.user?.role == 'owner' ? 'Quản lý' : 'Cửa hàng',
                  auth.user?.role == 'owner' ? 'Bảng điều khiển' : 'Dụng cụ thi đấu',
                  AppTheme.warmGradient,
                  () {
                    if (auth.user?.role == 'owner') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()));
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
                    }
                  }
                ),
                _FeatureCard(
                  auth.user?.role == 'owner' ? Icons.shopping_bag_rounded : Icons.rocket_launch_rounded,
                  auth.user?.role == 'owner' ? 'Đơn hàng' : 'Trở thành đối tác',
                  auth.user?.role == 'owner' ? 'Sản phẩm & Đơn hàng' : 'Đăng ký chủ sân',
                  AppTheme.primaryGradient,
                  () {
                    if (auth.user?.role == 'owner') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
                    } else {
                      showUpgradeDialog(context, auth);
                    }
                  }
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon; final String title; final String sub; final Gradient grad; final VoidCallback onTap;
  const _FeatureCard(this.icon, this.title, this.sub, this.grad, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class UserNotificationBell extends StatefulWidget {
  const UserNotificationBell({super.key});

  @override
  State<UserNotificationBell> createState() => _UserNotificationBellState();
}

class _UserNotificationBellState extends State<UserNotificationBell> {
  int _unreadCount = 0;
  List<SystemNotification> _notifs = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) return;
    final list = await NotificationService.getNotifications(auth.user!.id.toString());
    if (mounted) setState(() { _notifs = list; _unreadCount = list.where((n) => !n.isRead).length; });
  }

  void _showNotifications() {
    final auth = Provider.of<AuthService>(context, listen: false);
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thông báo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                    TextButton(onPressed: () async { await NotificationService.markAllAsRead(auth.user!.id.toString()); _fetch(); }, child: const Text('Đọc hết', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: sc, padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _notifs.length,
                  itemBuilder: (_, i) {
                    final n = _notifs[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: n.isRead ? Colors.transparent : AppTheme.primary.withOpacity(0.04), borderRadius: BorderRadius.circular(16)),
                      child: Text(n.message, style: TextStyle(color: AppTheme.primary, fontWeight: n.isRead ? FontWeight.normal : FontWeight.w700)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26), onPressed: _showNotifications),
        if (_unreadCount > 0)
          Positioned(right: 8, top: 8, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 8)))),
      ],
    );
  }
}

void showUpgradeDialog(BuildContext context, AuthService authService) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.rocket_launch_rounded, color: AppTheme.primary),
          SizedBox(width: 12),
          Text('Partner Registration', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
      content: const Text('Do you want to become a court owner and manage your business?', style: TextStyle(color: AppTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later', style: TextStyle(color: AppTheme.textMuted))),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final success = await authService.upgradeToOwner();
            if (success && context.mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()));
            }
          },
          child: const Text('Upgrade NOW'),
        ),
      ],
    ),
  );
}

class CourtCard extends StatelessWidget {
  final CourtWithDistance data;
  const CourtCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200, margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.borderLight), boxShadow: AppTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Container(decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data.court.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary)),
              Text('Cách bạn ${data.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]),
          ),
        ],
      ),
    );
  }
}