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
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      _HeroSection(
                        searchCtrl: _searchCtrl,
                        onSearch: _search,
                        onFindCourts: () => widget.onTabChange?.call(1),
                        onBookNow: () => widget.onTabChange?.call(3),
                      ),
                      const Positioned(
                        bottom: -40, // Pull it down to overlap
                        child: _StatsStrip(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // Space for the overlapping stats
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
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          left: isMobile ? 24 : 40,
          right: isMobile ? 24 : 40,
          top: 72,
          bottom: 120), // Bottom padding for overlapping stats
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isMobile
              ? Column(
                  children: [
                    _buildLeftContent(context, auth),
                    const SizedBox(height: 48),
                    _buildRightContent(context),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 11, child: _buildLeftContent(context, auth)),
                    const SizedBox(width: 64),
                    Expanded(flex: 8, child: _buildRightContent(context)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLeftContent(BuildContext context, AuthService auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Text(
            '🏸  Nền tảng đặt sân #1 Việt Nam',
            style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          auth.isAuthenticated
              ? 'Xin chào, ${auth.user!.fullName}! 👋'
              : 'Tìm & Đặt Sân\nCầu Lông Dễ Dàng',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            height: 1.15,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Khám phá hàng trăm sân cầu lông chất lượng gần bạn.\nĐặt sân nhanh chóng, thanh toán an toàn.',
          style: TextStyle(
              color: Colors.white70, fontSize: 17, height: 1.6, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 36),

        // Search bar
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: TextField(
            controller: searchCtrl,
            onSubmitted: onSearch,
            decoration: InputDecoration(
              hintText: 'Tìm sân theo tên hoặc địa chỉ...',
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(Icons.search_rounded, color: AppTheme.primary, size: 24),
              ),
              suffixIcon: GestureDetector(
                onTap: () => onSearch(searchCtrl.text),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
          ),
        ),
        const SizedBox(height: 32),

        // CTAs
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: onFindCourts,
              icon: const Icon(Icons.search_rounded, size: 20),
              label: const Text('Tìm sân ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.highlight,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: onBookNow,
              icon: const Icon(Icons.calendar_month_rounded, size: 20),
              label: const Text('Hướng dẫn đặt'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white60, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 32,
            offset: const Offset(0, 16),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.highlight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flash_on_rounded, color: AppTheme.highlight, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Gợi ý tìm kiếm',
                style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...[
            ('Tìm sân gần tôi', Icons.near_me_rounded),
            ('Sân có đèn LED', Icons.lightbulb_rounded),
            ('Giá dưới 100k/h', Icons.attach_money_rounded),
            ('Sân có HLV', Icons.sports_rounded),
          ].map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => onSearch(e.$1),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Icon(e.$2, color: Colors.white70, size: 18),
                        const SizedBox(width: 12),
                        Text(e.$1,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: Colors.white38),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Stats Strip ───────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 800;

    return Container(
      width: w > 1280 ? 1200 : w - 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
          )
        ],
      ),
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 48, vertical: isMobile ? 24 : 36),
      child: isMobile
          ? Column(
              children: const [
                _StatItem('1,200+', 'Sân hoạt động', Icons.sports_tennis_rounded, AppTheme.primary),
                SizedBox(height: 24),
                _StatItem('5,000+', 'Người dùng', Icons.people_rounded, Color(0xFF3B82F6)),
                SizedBox(height: 24),
                _StatItem('20k+', 'Lượt đặt sân', Icons.check_circle_rounded, Color(0xFF10B981)),
                SizedBox(height: 24),
                _StatItem('50+', 'Thành phố', Icons.location_city_rounded, Color(0xFFF59E0B)),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600)),
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
      Container(width: 1, height: 48, color: AppTheme.borderLight);
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
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'KHÁM PHÁ NGAY',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                                letterSpacing: 1.2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Sân cầu lông gần bạn',
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                              letterSpacing: -1.2)),
                      const SizedBox(height: 8),
                      const Text('Những sân tốt nhất trong khu vực của bạn với dịch vụ hàng đầu',
                          style:
                              TextStyle(fontSize: 16, color: AppTheme.textMuted, fontWeight: FontWeight.w400)),
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
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: -1.2)),
              const SizedBox(height: 12),
              const Text('Giải pháp đặt sân thông minh, hiện đại và tiện lợi nhất cho lông thủ',
                  style:
                      TextStyle(fontSize: 16, color: AppTheme.textMuted, fontWeight: FontWeight.w400)),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
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
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 64),
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 64),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B2038), Color(0xFF2D3250)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3250).withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: Stack(
        children: [
          // Decorative background icon
          Positioned(
            right: -40,
            top: -40,
            child: Icon(
              Icons.sports_tennis_rounded,
              size: 240,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chưa có tài khoản?',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2)),
                    SizedBox(height: 12),
                    Text(
                        'Tham gia cộng đồng ShuttleCourt ngay hôm nay để nhận nhiều ưu đãi độc quyền và kết nối với hàng ngàn lông thủ khác.',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 16, height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(width: 60),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.highlight,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ).copyWith(
                  overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
                ),
                child: const Text('Đăng kí ngay'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
