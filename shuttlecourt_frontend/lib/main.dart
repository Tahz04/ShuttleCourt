import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/booking/booking_screen.dart';
import 'package:shuttlecourt/auth/register_screen.dart';
import 'package:shuttlecourt/map/map_screen.dart';
import 'package:shuttlecourt/features/matchmaking/screens/matchmaking_screen.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/auth/profile_screen.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/features/owner/screens/owner_dashboard_screen.dart';
import 'package:shuttlecourt/features/shop/screens/shop_screen.dart';
import 'package:shuttlecourt/features/booking/screens/booking_history_screen.dart';
import 'package:shuttlecourt/services/notification_service.dart';
import 'package:shuttlecourt/features/notifications/notification_screen.dart';
import 'package:shuttlecourt/features/reviews/screens/user_review_history_screen.dart';
import 'package:shuttlecourt/services/location_service.dart';
import 'package:shuttlecourt/web/web_home_page.dart';
import 'package:shuttlecourt/web/web_booking_page.dart';
import 'package:shuttlecourt/web/web_search_page.dart';
import 'package:shuttlecourt/web/web_map_page.dart';
import 'package:shuttlecourt/web/web_matchmaking_page.dart';
import 'package:shuttlecourt/web/web_profile_page.dart';

void main() {
  debugPrint('--- APP STARTING ---');
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

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
  String? _mapSearchQuery;

  List<Widget> get _screens => [
    HomeScreen(onTabChange: _onItemTapped),
    MapScreen(searchQuery: _mapSearchQuery),
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

  void _onItemTapped(int index, {String? query}) {
    if (_selectedIndex != index || query != null) {
      _fadeController.reset();
      _fadeController.forward();
      setState(() {
        _selectedIndex = index;
        _mapSearchQuery = query;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ DETECT WEB PLATFORM: Use kIsWeb (web package detection)
    if (kIsWeb) {
      return _buildWebPlatformLayout();
    } else {
      // Mobile/Android/Windows/iOS uses the original layout
      final isWide = MediaQuery.of(context).size.width > 900;
      return isWide ? _buildWebLayout() : _buildMobileLayout();
    }
  }

  // ── WEB PLATFORM: New optimized web UI ──────────────────
  Widget _buildWebPlatformLayout() {
    // For web, render the appropriate web page based on selected index
    List<Widget> webScreens = [
      WebHomePage(onTabChange: _onItemTapped),
      WebSearchPage(initialQuery: _mapSearchQuery, onTabChange: _onItemTapped),
      WebMapPage(searchQuery: _mapSearchQuery, onTabChange: _onItemTapped),
      WebBookingPage(onTabChange: _onItemTapped),
      WebMatchmakingPage(onTabChange: _onItemTapped),
      WebProfilePage(onTabChange: _onItemTapped),
    ];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: FadeTransition(
        opacity: CurvedAnimation(
          parent: _fadeController,
          curve: Curves.easeOut,
        ),
        child: webScreens[_selectedIndex],
      ),
    );
  }

  // ── Mobile: BottomNavigationBar (logic gốc giữ nguyên) ──────
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: FadeTransition(
        opacity: CurvedAnimation(
          parent: _fadeController,
          curve: Curves.easeOut,
        ),
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
                _buildNavItem(
                  Icons.home_rounded,
                  Icons.home_outlined,
                  'Trang chủ',
                  0,
                ),
                _buildNavItem(
                  Icons.map_rounded,
                  Icons.map_outlined,
                  'Bản đồ',
                  1,
                ),
                _buildNavItem(
                  Icons.calendar_month_rounded,
                  Icons.calendar_month_outlined,
                  'Lịch sử',
                  2,
                ),
                _buildNavItem(
                  Icons.person_rounded,
                  Icons.person_outlined,
                  'Tài khoản',
                  3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Web (> 900px): NavigationRail bên trái ──────────────────
  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              border: const Border(
                right: BorderSide(color: AppTheme.borderLight),
              ),
              boxShadow: AppTheme.softShadow,
            ),
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => _onItemTapped(i),
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.transparent,
              minWidth: 80,
              selectedIconTheme: const IconThemeData(
                color: AppTheme.primary,
                size: 24,
              ),
              unselectedIconTheme: const IconThemeData(
                color: AppTheme.textMuted,
                size: 22,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: AppTheme.primary.withOpacity(0.08),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: Text('Trang chủ'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map_rounded),
                  label: Text('Bản đồ'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: Text('Lịch sử'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outlined),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: Text('Tài khoản'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeController,
                curve: Curves.easeOut,
              ),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int index,
  ) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withOpacity(0.08)
              : Colors.transparent,
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
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function(int, {String? query})? onTabChange;
  const HomeScreen({super.key, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<CourtWithDistance>> _nearestCourtsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _nearestCourtsFuture = LocationService.getNearestCourts(maxResults: 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: RefreshIndicator(
        onRefresh: () async {
          _refresh();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeroHeader(auth),
            _buildSearchSection(),
            _buildNearbySection(),
            _buildFeatureSection(auth),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(AuthService auth) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.of(context).padding.top + 20,
          24,
          32,
        ),
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
                    const Text(
                      'Chào bạn! 👋',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      auth.isAuthenticated ? auth.user!.fullName : 'Khách chơi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
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
          child: TextField(
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                widget.onTabChange?.call(1, query: value.trim());
              }
            },
            decoration: const InputDecoration(
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
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => widget.onTabChange?.call(1),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sân gần bạn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Xem bản đồ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppTheme.primary.withOpacity(0.7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<CourtWithDistance>>(
              future: _nearestCourtsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'Không tìm thấy sân nào gần đây',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  );
                }
                return _HorizontalCourtCarousel(
                  courts: list,
                  onCourtTap: (court) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingScreen(initialCourt: court),
                    ),
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
            const Text(
              'Khám phá thêm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _FeatureCard(
                  Icons.groups_rounded,
                  'Tìm đồng đội',
                  'Ghép sân ngay',
                  AppTheme.primaryGradient,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MatchmakingScreen(),
                    ),
                  ),
                ),
                _FeatureCard(
                  Icons.person_add_rounded,
                  'Đăng kí ngay',
                  'Tham gia ngay',
                  AppTheme.primaryGradient,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                ),
                _FeatureCard(
                  Icons.shopping_bag_rounded,
                  'Cửa hàng',
                  'Dụng cụ thể thao',
                  AppTheme.primaryGradient,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopScreen()),
                  ),
                ),
                _FeatureCard(
                  auth.user?.role == 'owner'
                      ? Icons.inventory_2_rounded
                      : Icons.star_rate_rounded,
                  auth.user?.role == 'owner' ? 'Quản lý sân' : 'Đánh giá sân',
                  auth.user?.role == 'owner'
                      ? 'Bảng điều khiển'
                      : 'Lịch sử đánh giá',
                  AppTheme.primaryGradient,
                  () {
                    if (auth.user?.role == 'owner') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OwnerDashboardScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserReviewHistoryScreen(),
                        ),
                      );
                    }
                  },
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
  final IconData icon;
  final String title;
  final String sub;
  final Gradient grad;
  final VoidCallback onTap;
  const _FeatureCard(this.icon, this.title, this.sub, this.grad, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: grad,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
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

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) return;
    final list = await NotificationService.getNotifications(
      auth.user!.id.toString(),
    );
    if (mounted)
      setState(() {
        _unreadCount = list.where((n) => !n.isRead).length;
      });
  }

  Future<void> _openNotifications() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để xem thông báo')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openNotifications,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          if (_unreadCount > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void showUpgradeDialog(BuildContext context, AuthService authService) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(
        'Become Owner',
        style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary),
      ),
      content: const Text(
        'Do you want to become a court owner and manage your business?',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Later',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final success = await authService.upgradeToOwner();
            if (success && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()),
              );
            }
          },
          child: const Text('Upgrade NOW'),
        ),
      ],
    ),
  );
}

class _HorizontalCourtCarousel extends StatefulWidget {
  final List<CourtWithDistance> courts;
  final void Function(dynamic court) onCourtTap;
  const _HorizontalCourtCarousel({
    required this.courts,
    required this.onCourtTap,
  });

  @override
  State<_HorizontalCourtCarousel> createState() =>
      _HorizontalCourtCarouselState();
}

class _HorizontalCourtCarouselState extends State<_HorizontalCourtCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) setState(() => _currentPage = page);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.courts.length,
            itemBuilder: (_, i) {
              final isActive = i == _currentPage;
              return AnimatedScale(
                scale: isActive ? 1.0 : 0.93,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: CourtCard(
                    data: widget.courts[i],
                    onTap: () => widget.onCourtTap(widget.courts[i].court),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.courts.length, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary
                    : AppTheme.primary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class CourtCard extends StatelessWidget {
  final CourtWithDistance data;
  final VoidCallback? onTap;
  const CourtCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isMaintenance = data.court.status == 'maintenance';
    const String placeholder =
        'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60';
    final String imageToShow =
        (data.court.mainImage != null && data.court.mainImage!.isNotEmpty)
        ? data.court.mainImage!
        : placeholder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageToShow,
                      fit: BoxFit.cover,
                      loadingBuilder: (c, child, p) => p == null
                          ? child
                          : Container(
                              color: AppTheme.primary.withOpacity(0.05),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                      errorBuilder: (c, e, s) => Container(
                        color: AppTheme.primary.withOpacity(0.05),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    if (isMaintenance)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black54,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.build_rounded,
                                  color: AppTheme.error,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'BẢO TRÌ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(data.court.pricePerHour / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.court.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppTheme.primary,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              size: 10,
                              color: AppTheme.accent,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${data.distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isMaintenance ? 'OFFLINE' : 'ACTIVE',
                          style: TextStyle(
                            color: isMaintenance
                                ? AppTheme.error
                                : Colors.green,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
