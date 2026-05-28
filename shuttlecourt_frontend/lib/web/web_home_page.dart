import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/auth/register_screen.dart';
import 'package:shuttlecourt/booking/booking_screen.dart';
import 'package:shuttlecourt/services/location_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/web/web_court_card.dart';
import 'package:shuttlecourt/web/web_court_detail_dialog.dart';
import 'package:shuttlecourt/web/web_footer.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_styles.dart';

class WebHomePage extends StatefulWidget {
  final Function(int, {String? query})? onTabChange;
  const WebHomePage({super.key, this.onTabChange});

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  late Future<List<CourtWithDistance>> _courtsFuture;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _courtsFuture = LocationService.getNearestCourts(maxResults: 8);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    if (q.trim().isNotEmpty) widget.onTabChange?.call(1, query: q.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebStyles.dark950,
      body: Column(
        children: [
          WebNavbar(
            selectedIndex: 0,
            onNavTap: (i) => widget.onTabChange?.call(i),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _HeroSection(
                    searchCtrl: _searchCtrl,
                    onSearch: _search,
                    onFindCourts: () => widget.onTabChange?.call(1),
                    onViewMap: () => widget.onTabChange?.call(2),
                  ),
                  _CourtsSection(
                    courtsFuture: _courtsFuture,
                    onViewAll: () => widget.onTabChange?.call(1),
                    onRefresh: () => setState(
                          () => _courtsFuture =
                          LocationService.getNearestCourts(maxResults: 8),
                    ),
                    onTabChange: widget.onTabChange,
                  ),
                  _MapExploreSection(
                    courtsFuture: _courtsFuture,
                    onOpenMap: () => widget.onTabChange?.call(2),
                    onOpenSearch: () => widget.onTabChange?.call(1),
                  ),
                  const _FeaturesSection(),
                  const _StepsSection(),
                  _CtaBanner(
                    onRegister: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                  ),
                  WebFooter(onNavTap: (i) => widget.onTabChange?.call(i)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Hero section stays the same...
class _HeroSection extends StatefulWidget {
  final TextEditingController searchCtrl;
  final Function(String) onSearch;
  final VoidCallback onFindCourts;
  final VoidCallback onViewMap;

  const _HeroSection({
    required this.searchCtrl,
    required this.onSearch,
    required this.onFindCourts,
    required this.onViewMap,
  });

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection>
    with TickerProviderStateMixin {
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final heroH = (screenH - 68).clamp(520.0, 900.0);
    final isWide = MediaQuery.of(context).size.width > 900;

    return SizedBox(
      width: double.infinity,
      height: heroH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [WebStyles.dark900, WebStyles.dark800, Color(0xFF064E3B)],
              ),
            ),
          ),
          Image.network(
            'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=1920&q=70',
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.55),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, _) => CustomPaint(
              painter: _ParticlePainter(_particleCtrl.value),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: WebStyles.brand.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: WebStyles.brand.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: WebStyles.brandLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'PLATFORM CẦU LÔNG #1 VIỆT NAM',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: WebStyles.brandLight,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Đặt Sân Cầu Lông',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [WebStyles.brandLight, WebStyles.brand],
                      ).createShader(bounds),
                      child: const Text(
                        'Nhanh Chóng & Dễ Dàng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tìm và đặt sân cầu lông gần bạn trong vài giây.\nKết nối đồng đội, ghép kèo, mua dụng cụ — tất cả trong một nền tảng.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.7,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 18),
                          const Icon(Icons.search_rounded,
                              color: WebStyles.brand, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: widget.searchCtrl,
                              onSubmitted: widget.onSearch,
                              decoration: InputDecoration(
                                hintText: 'Tìm sân theo tên hoặc địa chỉ...',
                                hintStyle: TextStyle(
                                  color: WebStyles.dark400,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: WebStyles.dark900,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: ElevatedButton(
                              onPressed: () =>
                                  widget.onSearch(widget.searchCtrl.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: WebStyles.brand,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Tìm kiếm',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _QuickTag(
                            '📍 Gần tôi', () => widget.onSearch('Tìm sân gần tôi')),
                        _QuickTag(
                            '💰 Dưới 100k/h', () => widget.onSearch('Giá dưới 100k/h')),
                        _QuickTag(
                            '💡 Có đèn LED', () => widget.onSearch('Sân có đèn LED')),
                        _QuickTag(
                            '🗺️ Xem bản đồ', widget.onViewMap),
                      ],
                    ),
                    const SizedBox(height: 52),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          _StatItem('50+', 'Sân cầu lông'),
                          _StatDivider(),
                          _StatItem('1,200+', 'Lượt đặt sân'),
                          _StatDivider(),
                          _StatItem('4.8★', 'Đánh giá TB'),
                          _StatDivider(),
                          _StatItem('10+', 'Quận / Huyện'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... QuickTag and other Hero helpers stay the same ...
class _QuickTag extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickTag(this.label, this.onTap);

  @override
  State<_QuickTag> createState() => _QuickTagState();
}

class _QuickTagState extends State<_QuickTag> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: _hovered ? 0.4 : 0.2),
            ),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: WebStyles.brandLight,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final _rng = math.Random(42);
  static final _particles = List.generate(
    15,
        (i) => _Particle(
      x: _rng.nextDouble(),
      startY: _rng.nextDouble(),
      size: 2 + _rng.nextDouble() * 3,
      speed: 0.4 + _rng.nextDouble() * 0.6,
      phase: _rng.nextDouble(),
    ),
  );

  const _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = WebStyles.brandLight.withValues(alpha: 0.5);
    for (final p in _particles) {
      final t = ((progress + p.phase) % 1.0);
      final opacity = t < 0.2
          ? t / 0.2
          : t > 0.7
          ? (1.0 - t) / 0.3
          : 0.6;
      final y = (p.startY - t * p.speed) % 1.0;
      paint.color = WebStyles.brandLight
          .withValues(alpha: (opacity * 0.55).clamp(0, 1));
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, startY, size, speed, phase;
  const _Particle({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.phase,
  });
}

// ... _CourtsSection and _FeaturesSection stay same ...

class _CourtsSection extends StatelessWidget {
  final Future<List<CourtWithDistance>> courtsFuture;
  final VoidCallback onViewAll;
  final VoidCallback onRefresh;
  final Function(int, {String? query})? onTabChange;

  const _CourtsSection({
    required this.courtsFuture,
    required this.onViewAll,
    required this.onRefresh,
    this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: WebStyles.dark50,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: WebStyles.brandPale,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: WebStyles.brandLight),
                    ),
                    child: const Text(
                      'SÂN CẦU LÔNG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: WebStyles.brandDark,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Sân Gần Bạn\n',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: WebStyles.dark900,
                            letterSpacing: -1,
                            height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: 'Đặt ngay hôm nay',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: WebStyles.brand,
                            letterSpacing: -1,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Hàng trăm sân cầu lông chất lượng cao đang chờ bạn khám phá',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: WebStyles.dark500,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              FutureBuilder<List<CourtWithDistance>>(
                future: courtsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: CircularProgressIndicator(color: WebStyles.brand),
                    );
                  }
                  final courts = snap.data ?? [];
                  if (courts.isEmpty) {
                    return _EmptyState(
                      icon: Icons.sports_tennis_rounded,
                      msg: 'Chưa có sân nào',
                      sub: 'Không thể tải danh sách sân',
                      onAction: onRefresh,
                      actionLabel: 'Thử lại',
                    );
                  }
                  return _CourtGrid(
                      courts: courts, onTabChange: onTabChange);
                },
              ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                onPressed: onViewAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: WebStyles.brand,
                  side: const BorderSide(color: WebStyles.brand, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text(
                  'Xem tất cả sân',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourtGrid extends StatelessWidget {
  final List<CourtWithDistance> courts;
  final Function(int, {String? query})? onTabChange;

  const _CourtGrid({required this.courts, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w > 1200 ? 4 : (w > 900 ? 3 : (w > 600 ? 2 : 1));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 380,
      ),
      itemCount: courts.length,
      itemBuilder: (context, i) {
        final item = courts[i];
        return WebCourtCard(
          court: item.court,
          distanceKm: item.distanceKm,
          onViewDetails: () => showCourtDetailDialog(
            context, item.court,
            distanceKm: item.distanceKm,
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
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    const features = [
      _FeatureData(
        Icons.flash_on_rounded,
        'Đặt sân tức thì',
        'Chỉ vài thao tác là có sân ngay — không cần gọi điện, không cần chờ đợi.',
        Color(0xFF10B981),
      ),
      _FeatureData(
        Icons.map_rounded,
        'Bản đồ tương tác',
        'Xem sân trên bản đồ, tính khoảng cách, dẫn đường đến sân trong nháy mắt.',
        Color(0xFF3B82F6),
      ),
      _FeatureData(
        Icons.people_rounded,
        'Ghép sân cộng đồng',
        'Tìm đồng đội cùng trình độ, tạo kèo hoặc tham gia kèo có sẵn nhanh chóng.',
        Color(0xFF8B5CF6),
      ),
      _FeatureData(
        Icons.shopping_bag_rounded,
        'Cửa hàng dụng cụ',
        'Mua vợt, cầu, giày và phụ kiện cầu lông chính hãng với giá ưu đãi.',
        Color(0xFFF59E0B),
      ),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              _SectionHeader(
                badge: 'TÍNH NĂNG',
                title: 'Tất cả trong ',
                titleAccent: 'một nền tảng',
                subtitle:
                'ShuttleCourt mang đến trải nghiệm toàn diện cho người chơi cầu lông',
              ),
              const SizedBox(height: 48),
              LayoutBuilder(builder: (context, bc) {
                final cols = bc.maxWidth > 800 ? 4 : (bc.maxWidth > 500 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: cols,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.1,
                  children: features
                      .map((f) => _FeatureCard(feature: f))
                      .toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title, desc;
  final Color color;
  const _FeatureData(this.icon, this.title, this.desc, this.color);
}

class _FeatureCard extends StatefulWidget {
  final _FeatureData feature;
  const _FeatureCard({required this.feature});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.translationValues(0, _hovered ? -8 : 0, 0),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: WebStyles.dark50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovered ? f.color.withValues(alpha: 0.3) : WebStyles.dark200,
          ),
          boxShadow: _hovered
              ? [
            BoxShadow(
              color: f.color.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
            )
          ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: f.color.withValues(alpha: _hovered ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(f.icon, color: f.color, size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              f.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: WebStyles.dark900,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                f.desc,
                style: const TextStyle(
                  fontSize: 14,
                  color: WebStyles.dark500,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ... _StepsSection stays same ...

class _StepsSection extends StatelessWidget {
  const _StepsSection();

  @override
  Widget build(BuildContext context) {
    const steps = [
      _StepData('01', Icons.search_rounded, 'Tìm sân phù hợp',
          'Dùng bộ lọc tìm kiếm theo khu vực, giá, tiện ích để tìm sân ưng ý.'),
      _StepData('02', Icons.calendar_month_rounded, 'Chọn ngày & giờ',
          'Xem lịch trống theo thời gian thực, chọn slot phù hợp với lịch của bạn.'),
      _StepData('03', Icons.check_circle_rounded, 'Xác nhận & đặt sân',
          'Thanh toán nhanh chóng, nhận xác nhận ngay lập tức, sân đã sẵn sàng!'),
    ];

    return Container(
      width: double.infinity,
      color: WebStyles.dark50,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              _SectionHeader(
                badge: 'CÁCH THỨC',
                title: 'Đặt sân chỉ với ',
                titleAccent: '3 bước đơn giản',
                subtitle: 'Quy trình đơn giản, nhanh gọn, không cần tài khoản trước',
              ),
              const SizedBox(height: 56),
              LayoutBuilder(builder: (context, bc) {
                final isWide = bc.maxWidth > 700;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: steps
                        .asMap()
                        .entries
                        .map((e) => Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _StepCard(step: e.value)),
                          if (e.key < steps.length - 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: WebStyles.dark300,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                    ))
                        .toList(),
                  );
                }
                return Column(
                  children: steps
                      .map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _StepCard(step: s),
                  ))
                      .toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepData {
  final String number;
  final IconData icon;
  final String title, desc;
  const _StepData(this.number, this.icon, this.title, this.desc);
}

class _StepCard extends StatelessWidget {
  final _StepData step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebStyles.dark200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: WebStyles.brandGrad,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(step.icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Text(
                step.number,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: WebStyles.brand.withValues(alpha: 0.12),
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: WebStyles.dark900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.desc,
            style: const TextStyle(
              fontSize: 13,
              color: WebStyles.dark500,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

// CTA Banner
class _CtaBanner extends StatelessWidget {
  final VoidCallback onRegister;
  const _CtaBanner({required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: WebStyles.dark50,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 56),
            decoration: BoxDecoration(
              gradient: WebStyles.brandGrad,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: WebStyles.brand.withValues(alpha: 0.35),
                  blurRadius: 50,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  left: -30,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Column(
                  children: [
                    const Text(
                      'Sẵn sàng bước ra sân?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Đăng ký miễn phí ngay hôm nay và đặt sân cầu lông\nchỉ trong vài giây. Không cần thẻ tín dụng.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: onRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: WebStyles.brandDark,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                      label: const Text(
                        'Đăng ký miễn phí',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String badge, title, titleAccent, subtitle;
  const _SectionHeader({
    required this.badge,
    required this.title,
    required this.titleAccent,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: WebStyles.brandPale,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: WebStyles.brandLight),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: WebStyles.brandDark,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: title,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: WebStyles.dark900,
                  letterSpacing: -0.8,
                  height: 1.2,
                ),
              ),
              TextSpan(
                text: titleAccent,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: WebStyles.brand,
                  letterSpacing: -0.8,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: WebStyles.dark500,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

// MAP EXPLORE SECTION (FIXED BLOCK CLICK)
class _MapExploreSection extends StatelessWidget {
  final Future<List<CourtWithDistance>> courtsFuture;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenSearch;

  const _MapExploreSection({
    required this.courtsFuture,
    required this.onOpenMap,
    required this.onOpenSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Container(
      width: double.infinity,
      color: WebStyles.dark900,
      child: isWide
          ? IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: _buildLeftPanel(context)),
            Expanded(flex: 4, child: _buildMapPanel()),
          ],
        ),
      )
          : Column(children: [
        _buildLeftPanel(context),
        SizedBox(height: 320, child: _buildMapPanel()),
      ]),
    );
  }

  Widget _buildLeftPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: WebStyles.brand.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: WebStyles.brand.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'KHÁM PHÁ BẢN ĐỒ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: WebStyles.brandLight,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tìm sân\ngần bạn nhất',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Xem toàn bộ sân cầu lông trên bản đồ tương tác.\nChọn sân, xem chi tiết và đặt ngay chỉ với vài thao tác.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.7,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _MapStat('50+', 'Sân được đánh dấu'),
              const SizedBox(width: 32),
              _MapStat('10+', 'Quận / Huyện'),
              const SizedBox(width: 32),
              _MapStat('5km', 'Bán kính tìm kiếm'),
            ],
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: onOpenMap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WebStyles.brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Mở bản đồ',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              OutlinedButton.icon(
                onPressed: onOpenSearch,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Tìm sân',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 48),
          const Text(
            'SÂN NỔI BẬT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: WebStyles.brandLight,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<CourtWithDistance>>(
            future: courtsFuture,
            builder: (context, snap) {
              final courts = snap.data ?? [];
              if (courts.isEmpty) {
                return Center(
                  child: Text(
                    'Đang tải...',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4)),
                  ),
                );
              }
              return Column(
                children: courts
                    .take(4)
                    .map((item) =>
                    _VerticalCourtItem(item: item, onOpenMap: onOpenMap))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapPanel() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onOpenMap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Map satellite image background
            Image.network(
              'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=900&q=70',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: WebStyles.dark800),
            ),
            // Dark overlay (FIX: Wrapped in IgnorePointer to allow clicks to pass through)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      WebStyles.dark900.withValues(alpha: 0.7),
                      WebStyles.dark900.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
            // Floating pin cards (These will now be clickable as part of the GestureDetector)
            Positioned(
              top: 80,
              right: 40,
              child: _MapPinCard(
                  '⭐ 4.8', 'Mỹ Đình Indoor', '90k/giờ', WebStyles.brand),
            ),
            Positioned(
              top: 200,
              right: 120,
              child: _MapPinCard(
                  '⭐ 4.6', 'Quốc Việt Cầu Lông', '70k/giờ', Colors.blue),
            ),
            Positioned(
              bottom: 120,
              right: 60,
              child: _MapPinCard(
                  '⭐ 4.5', 'Sân Đại học BK', '60k/giờ', const Color(0xFF8B5CF6)),
            ),
            // Open map overlay button
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Nhấn để mở bản đồ tương tác',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapStat extends StatelessWidget {
  final String value, label;
  const _MapStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: WebStyles.brandLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.45),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _VerticalCourtItem extends StatefulWidget {
  final CourtWithDistance item;
  final VoidCallback onOpenMap;
  const _VerticalCourtItem({required this.item, required this.onOpenMap});

  @override
  State<_VerticalCourtItem> createState() => _VerticalCourtItemState();
}

class _VerticalCourtItemState extends State<_VerticalCourtItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final court = widget.item.court;
    final placeholder =
        'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=120&q=60';
    final imageUrl = (court.mainImage != null && court.mainImage!.isNotEmpty)
        ? court.mainImage!
        : placeholder;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onOpenMap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? WebStyles.brand.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 56,
                    height: 56,
                    color: WebStyles.brand.withValues(alpha: 0.2),
                    child: const Icon(Icons.sports_tennis_rounded,
                        color: WebStyles.brand, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      court.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      court.address,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(court.pricePerHour / 1000).toStringAsFixed(0)}k/h',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: WebStyles.brandLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: _hovered
                        ? WebStyles.brand
                        : Colors.white.withValues(alpha: 0.3),
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

class _MapPinCard extends StatelessWidget {
  final String rating, name, price;
  final Color color;
  const _MapPinCard(this.rating, this.name, this.price, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: WebStyles.dark800.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  Text(
                    rating,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFFBBF24),
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    price,
                    style: const TextStyle(
                        fontSize: 10,
                        color: WebStyles.brandLight,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String msg, sub;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _EmptyState({
    required this.icon,
    required this.msg,
    required this.sub,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: WebStyles.brand.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child:
            Icon(icon, size: 36, color: WebStyles.brand.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 18),
          Text(msg,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: WebStyles.dark700)),
          const SizedBox(height: 6),
          Text(sub,
              style: const TextStyle(
                  fontSize: 13, color: WebStyles.dark500)),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: WebStyles.brand,
                side: const BorderSide(color: WebStyles.brand),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}
