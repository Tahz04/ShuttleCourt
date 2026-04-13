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
import 'package:quynh/features/owner/screens/admin_dashboard_screen.dart';
import 'package:quynh/features/owner/screens/owner_registration_screen.dart';
import 'package:quynh/services/api_booking_service.dart';
import 'package:quynh/theme/app_theme.dart';
import 'package:quynh/features/owner/screens/owner_dashboard_screen.dart';
import 'package:quynh/services/court_service.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Loading...')),
      ),
    ),
  );
  
  try {
    debugPrint('--- APP STARTING ---');
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('--- BINDING INITIALIZED ---');
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    
    runApp(
      ChangeNotifierProvider(
        create: (context) => AuthService(),
        child: const BadmintonApp(),
      ),
    );
    debugPrint('--- RUNAPP CALLED ---');
  } catch (e, stack) {
    debugPrint('--- CRASH IN MAIN: $e');
    debugPrint(stack.toString());
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Error: $e')))));
  }
}

class BadmintonApp extends StatelessWidget {
  const BadmintonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShuttleCourt - Đặt Sân Cầu Lông',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
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
    debugPrint('--- BUILDING MAIN SCREEN ---');
    return Scaffold(
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Trang chủ', 0),
                _buildNavItem(Icons.map_rounded, Icons.map_outlined, 'Bản đồ', 1),
                _buildNavItem(Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Lịch đặt', 2),
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
        padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HOME SCREEN - Premium Redesign
// ═══════════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<CourtWithDistance>> _nearestCourtsFuture;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _nearestCourtsFuture = LocationService.getNearestCourts(maxResults: 5);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      body: const CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: HeroHeader()),
          SliverToBoxAdapter(child: SearchBarSection()),
          SliverToBoxAdapter(child: NearbySection()),
          SliverToBoxAdapter(child: FeatureSection()),
          SliverToBoxAdapter(child: PromoBanner()),
          SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class HeroHeader extends StatelessWidget {
  const HeroHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF00A844), Color(0xFF007B33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
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
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Consumer<AuthService>(
                      builder: (context, auth, _) {
                        return Text(
                          auth.isAuthenticated ? auth.user!.fullName : 'Vận động viên 🏸',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Consumer<AuthService>(
                builder: (context, auth, _) {
                  return GestureDetector(
                    onTap: () {
                      if (!auth.isAuthenticated) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickStatItem(value: '40+', label: 'Sân cầu lông', icon: Icons.stadium_rounded),
                _QuickStatItem(value: '24/7', label: 'Đặt sân online', icon: Icons.schedule_rounded),
                _QuickStatItem(value: '⭐ 5.0', label: 'Đánh giá', icon: null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchBarSection extends StatefulWidget {
  const SearchBarSection({super.key});

  @override
  State<SearchBarSection> createState() => _SearchBarSectionState();
}

class _SearchBarSectionState extends State<SearchBarSection> {
  List<BadmintonCourt> _allCourts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    final courts = await CourtService.getAllCourts();
    if (mounted) {
      setState(() {
        _allCourts = courts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Autocomplete<BadmintonCourt>(
          displayStringForOption: (option) => option.name,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<BadmintonCourt>.empty();
            }
            return _allCourts.where((court) => 
                court.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                court.address.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (BadmintonCourt selection) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(searchQuery: selection.name)));
          },
          fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              onSubmitted: (value) {
                if (value.trim().isEmpty) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(searchQuery: value)));
              },
              decoration: InputDecoration(
                hintText: _isLoading ? 'Đang tải danh sách sân...' : 'Tìm sân cầu lông gần bạn...',
                hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.7), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppTheme.textMuted, size: 20),
                  onPressed: () {
                    final value = controller.text;
                    if (value.trim().isEmpty) return;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(searchQuery: value, isGlobalSearch: true)));
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            );
          },
        ),
      ),
    );
  }
}

class NearbySection extends StatefulWidget {
  const NearbySection({super.key});

  @override
  State<NearbySection> createState() => _NearbySectionState();
}

class _NearbySectionState extends State<NearbySection> {
  late Future<List<CourtWithDistance>> _nearestCourtsFuture;

  @override
  void initState() {
    super.initState();
    _nearestCourtsFuture = LocationService.getNearestCourts(maxResults: 5);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sân Gần Bạn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.3),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Xem tất cả', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<CourtWithDistance>>(
            future: _nearestCourtsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox(
                  height: 160,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_rounded, size: 40, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        const Text('Không tìm thấy sân gần bạn', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }

              final nearestCourts = snapshot.data!;
              return SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: nearestCourts.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: index < nearestCourts.length - 1 ? 12 : 0),
                      child: CourtCard(data: nearestCourts[index]),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class FeatureSection extends StatelessWidget {
  const FeatureSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dịch Vụ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.3),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: FeatureCard(
                icon: Icons.sports_tennis_rounded,
                title: 'Đặt sân ngay',
                subtitle: 'Nhanh & tiện lợi',
                gradient: AppTheme.warmGradient,
                onTap: () {
                  final auth = Provider.of<AuthService>(context, listen: false);
                  if (auth.isAuthenticated) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen()));
                  } else {
                    showLoginRequiredDialog(context);
                  }
                },
              )),
              const SizedBox(width: 12),
              Expanded(child: FeatureCard(
                icon: Icons.group_rounded,
                title: 'Tìm kèo ghép',
                subtitle: 'Chơi cùng bạn bè',
                gradient: AppTheme.matchmakingGradient,
                onTap: () {
                  final auth = Provider.of<AuthService>(context, listen: false);
                  if (auth.isAuthenticated) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchmakingScreen()));
                  } else {
                    showLoginRequiredDialog(context);
                  }
                },
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: FeatureCard(
                icon: Icons.store_rounded,
                title: 'Chủ sân',
                subtitle: 'Quản lý kinh doanh',
                gradient: AppTheme.ownerGradient,
                onTap: () {
                  final auth = Provider.of<AuthService>(context, listen: false);
                  if (!auth.isAuthenticated) {
                    showLoginRequiredDialog(context);
                    return;
                  }
                  
                  if (auth.user?.role == 'admin') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                  } else if (auth.user?.role == 'owner') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerRegistrationScreen()));
                  }
                },
              )),
              const SizedBox(width: 12),
              Expanded(child: FeatureCard(
                icon: Icons.star_rounded,
                title: 'Đánh giá',
                subtitle: 'Chia sẻ trải nghiệm',
                gradient: const LinearGradient(colors: [Color(0xFFFFAB00), Color(0xFFFF6D00)]),
                onTap: () {},
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2232), Color(0xFF0F1923)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ưu đãi mới! 🎉',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Giảm 20% cho lần đặt sân đầu tiên. Dùng mã SHUTTLE20',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.8), height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Đặt ngay →',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.local_offer_rounded, color: AppTheme.primary, size: 32),
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color shadowColor = Colors.black12;
    if (gradient is LinearGradient) {
      shadowColor = (gradient as LinearGradient).colors.first.withOpacity(0.3);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showUpgradeDialog(BuildContext context, AuthService authService) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: AppTheme.ownerGradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Đăng ký Đối tác', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17))),
        ],
      ),
      content: const Text(
        'Nâng cấp lên Đối tác/Chủ sân để quản lý sân và tiếp cận khách hàng!',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Để sau', style: TextStyle(color: AppTheme.textMuted))),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang xử lý nâng cấp...')));
            final success = await authService.upgradeToOwner();
            if (!context.mounted) return;
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🎉 Chúc mừng! Bạn đã trở thành Đối tác.'), backgroundColor: AppTheme.success),
              );
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(authService.errorMessage ?? 'Nâng cấp thất bại'), backgroundColor: AppTheme.error),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAA00FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Đăng ký ngay'),
        ),
      ],
    ),
  );
}

void showLoginRequiredDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.lock_rounded, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Yêu cầu đăng nhập', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17)),
        ],
      ),
      content: const Text('Bạn cần đăng nhập để sử dụng tính năng này.', style: TextStyle(color: AppTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: AppTheme.textMuted))),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())); },
          child: const Text('Đăng nhập'),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════
// QUICK STAT ITEM
// ═══════════════════════════════════════════════════════════════════════
class _QuickStatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;

  const _QuickStatItem({required this.value, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null) Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.65))),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// COURT CARD - Professional Redesign
// ═══════════════════════════════════════════════════════════════════════
class CourtCard extends StatelessWidget {
  final CourtWithDistance data;
  const CourtCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(searchQuery: data.court.name)));
      },
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Container(
              height: 85,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary.withValues(alpha: 0.25), AppTheme.accent.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.sports_tennis_rounded, size: 32, color: Colors.white30)),
                  if (data.distanceKm > 0)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.scaffoldDark.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded, size: 9, color: AppTheme.accent),
                            const SizedBox(width: 3),
                            Text('${data.distanceKm.toStringAsFixed(1)}km', style: const TextStyle(fontSize: 9, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
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
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data.court.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textPrimary, height: 1.3),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: AppTheme.accentGold),
                            const SizedBox(width: 2),
                            Text('${data.court.rating}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(
                          '${(data.court.pricePerHour / 1000).toStringAsFixed(0)}k/h',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12),
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// BOOKING HISTORY SCREEN - Professional Redesign
// ═══════════════════════════════════════════════════════════════════════
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
      backgroundColor: AppTheme.scaffoldDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF00A844), Color(0xFF007B33)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 25, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lịch Đặt Sân',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text('Quản lý và theo dõi đặt sân của bạn', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: FutureBuilder<List<Booking>>(
              future: _bookingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        const Text('Không thể tải dữ liệu', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('${snapshot.error}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  );
                }

                final bookings = snapshot.data ?? [];
                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.calendar_today_rounded, size: 44, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 20),
                        const Text('Chưa có lịch đặt sân', style: TextStyle(fontSize: 17, color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        const Text('Hãy đặt sân để bắt đầu chơi!', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  );
                }

                bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_tennis_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.courtName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(booking.courtAddress, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.scaffoldDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBookingDetail(Icons.calendar_today_rounded, DateFormat('dd/MM/yy').format(booking.date)),
                Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.05)),
                _buildBookingDetail(Icons.access_time_rounded, booking.slot),
                Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.05)),
                _buildBookingDetail(Icons.payment_rounded, booking.paymentMethod.length > 6 ? '${booking.paymentMethod.substring(0, 6)}...' : booking.paymentMethod),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${DateFormat('dd/MM HH:mm').format(booking.createdAt)}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text(
                '${booking.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetail(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 14, color: AppTheme.primary.withValues(alpha: 0.8)),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}