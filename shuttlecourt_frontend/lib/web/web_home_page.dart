import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/booking/booking_screen.dart';
import 'package:shuttlecourt/auth/register_screen.dart';
import 'package:shuttlecourt/services/location_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/web/web_court_card.dart';
import 'package:shuttlecourt/web/web_footer.dart';
import 'package:shuttlecourt/web/web_navbar.dart';

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
      backgroundColor: AppTheme.scaffoldLight,
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
                    onBookNow: () => widget.onTabChange?.call(3),
                  ),
                  const _StatsStrip(),
                  _NearbySection(
                    courtsFuture: _courtsFuture,
                    onViewAll: () => widget.onTabChange?.call(1),
                    onRefresh: () => setState(() {
                      _courtsFuture =
                          LocationService.getNearestCourts(maxResults: 8);
                    }),
                  ),
                  const _FeaturesSection(),
                  _CtaBanner(onFindCourts: () => widget.onTabChange?.call(1)),
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

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final VoidCallback onFindCourts;
  final VoidCallback onBookNow;

  const _HeroSection({
    required this.searchCtrl,
    required this.onSearch,
    required this.onFindCourts,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 72),
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left text
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🏸  Nền tảng đặt sân #1 Việt Nam',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      auth.isAuthenticated
                          ? 'Xin chào, ${auth.user!.fullName}! 👋'
                          : 'Tìm & Đặt Sân\nCầu Lông Dễ Dàng',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Khám phá hàng trăm sân cầu lông chất lượng gần bạn.\nĐặt sân nhanh chóng, thanh toán an toàn.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 32),

                    // Search bar
                    Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.premiumShadow,
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        onSubmitted: onSearch,
                        decoration: InputDecoration(
                          hintText: 'Tìm sân theo tên hoặc địa chỉ...',
                          hintStyle: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppTheme.primary, size: 22),
                          suffixIcon: GestureDetector(
                            onTap: () => onSearch(searchCtrl.text),
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CTAs
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: onFindCourts,
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: const Text('Tìm sân'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.highlight,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: onBookNow,
                          icon: const Icon(Icons.calendar_month_rounded,
                              size: 18),
                          label: const Text('Đặt ngay'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side:
                                const BorderSide(color: Colors.white54, width: 1.5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 60),
              // Right decorative card
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đặt nhanh',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      ...[
                        ('Tìm sân gần tôi', Icons.near_me_rounded),
                        ('Sân có đèn LED', Icons.lightbulb_rounded),
                        ('Giá dưới 100k/h', Icons.attach_money_rounded),
                        ('Sân có HLV', Icons.sports_rounded),
                      ].map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () => onSearch(e.$1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(e.$2,
                                        color: Colors.white70, size: 16),
                                    const SizedBox(width: 10),
                                    Text(e.$1,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 12,
                                        color: Colors.white38),
                                  ],
                                ),
                              ),
                            ),
                          )),
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

// ── Stats Strip ───────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _StatItem('1,200+', 'Sân hoạt động', Icons.sports_tennis_rounded,
                  AppTheme.primary),
              _Divider(),
              _StatItem('5,000+', 'Người dùng', Icons.people_rounded,
                  Color(0xFF3B82F6)),
              _Divider(),
              _StatItem('20k+', 'Lượt đặt sân', Icons.check_circle_rounded,
                  Color(0xFF10B981)),
              _Divider(),
              _StatItem('50+', 'Thành phố', Icons.location_city_rounded,
                  Color(0xFFF59E0B)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatItem(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5)),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: AppTheme.borderLight);
}

// ── Nearby Courts ─────────────────────────────────────────────────────────────

class _NearbySection extends StatelessWidget {
  final Future<List<CourtWithDistance>> courtsFuture;
  final VoidCallback onViewAll;
  final VoidCallback onRefresh;

  const _NearbySection({
    required this.courtsFuture,
    required this.onViewAll,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Sân cầu lông gần bạn',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.8)),
                      SizedBox(height: 4),
                      Text('Những sân tốt nhất trong khu vực của bạn',
                          style:
                              TextStyle(fontSize: 14, color: AppTheme.textMuted)),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Làm mới'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onViewAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Xem tất cả',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Grid
              FutureBuilder<List<CourtWithDistance>>(
                future: courtsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primary)),
                    );
                  }
                  final courts = snap.data ?? [];
                  if (courts.isEmpty) {
                    return _EmptyState(
                      icon: Icons.location_off_outlined,
                      message: 'Không tìm thấy sân gần bạn',
                      sub: 'Hãy thử làm mới hoặc cho phép truy cập vị trí',
                    );
                  }
                  return _CourtsGrid(courts: courts);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourtsGrid extends StatelessWidget {
  final List<CourtWithDistance> courts;
  const _CourtsGrid({required this.courts});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    int cols = w > 1200 ? 4 : (w > 900 ? 3 : (w > 600 ? 2 : 1));

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
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState(
      {required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(icon, size: 56, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Text(sub,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

// ── Features ──────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text('Tại sao chọn ShuttleCourt?',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.8)),
              const SizedBox(height: 8),
              const Text('Giải pháp đặt sân thông minh và tiện lợi nhất',
                  style:
                      TextStyle(fontSize: 14, color: AppTheme.textMuted)),
              const SizedBox(height: 40),
              LayoutBuilder(builder: (context, bc) {
                int cols = bc.maxWidth > 900 ? 4 : (bc.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: cols,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.05,
                  children: const [
                    _FeatureCard(
                        Icons.bolt_rounded,
                        'Đặt sân nhanh',
                        'Chỉ vài bước đơn giản là xong',
                        Color(0xFF3B82F6)),
                    _FeatureCard(
                        Icons.verified_rounded,
                        'Sân đã kiểm duyệt',
                        'Tất cả sân được đánh giá bởi cộng đồng',
                        Color(0xFF10B981)),
                    _FeatureCard(
                        Icons.near_me_rounded,
                        'Gần bạn nhất',
                        'Định vị thông minh tìm sân xung quanh',
                        Color(0xFFF59E0B)),
                    _FeatureCard(
                        Icons.groups_rounded,
                        'Tìm đồng đội',
                        'Ghép đội cùng người chơi trong khu vực',
                        AppTheme.primary),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _FeatureCard(this.icon, this.title, this.desc, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(desc,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textMuted, height: 1.5)),
        ],
      ),
    );
  }
}

// ── CTA Banner ────────────────────────────────────────────────────────────────

class _CtaBanner extends StatelessWidget {
  final VoidCallback onFindCourts;
  const _CtaBanner({required this.onFindCourts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D3250), Color(0xFF424769)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chưa có tài khoản?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8)),
                SizedBox(height: 8),
                Text(
                    'Tham gia cộng đồng ShuttleCourt ngay hôm nay để nhận nhiều ưu đãi.',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 40),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.highlight,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15),
            ),
            child: const Text('Đăng kí ngay'),
          ),
        ],
      ),
    );
  }
}
