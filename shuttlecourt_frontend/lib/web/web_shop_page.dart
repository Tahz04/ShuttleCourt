import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shuttlecourt/services/shop_service.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_footer.dart';
import 'package:shuttlecourt/web/web_styles.dart';
import 'package:shuttlecourt/features/shop/screens/checkout_screen.dart';

class WebShopPage extends StatefulWidget {
  final Function(int)? onTabChange;
  const WebShopPage({super.key, this.onTabChange});

  @override
  State<WebShopPage> createState() => _WebShopPageState();
}

class _WebShopPageState extends State<WebShopPage> {
  late Future<List<Product>> _productsFuture;
  String _selectedCategory = 'Tất cả';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  static const _categories = ['Tất cả', 'Vợt', 'Quả cầu', 'Giày', 'Phụ kiện'];

  static const _catIcons = {
    'Tất cả': Icons.grid_view_rounded,
    'Vợt': Icons.sports_tennis_rounded,
    'Quả cầu': Icons.sports_rounded,
    'Giày': Icons.directions_walk_rounded,
    'Phụ kiện': Icons.category_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = ShopService.getProducts();
    });
  }

  List<Product> _filter(List<Product> all) {
    var result = all;
    if (_selectedCategory != 'Tất cả') {
      result = result.where((p) => p.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.description?.toLowerCase() ?? '').contains(q))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebStyles.bg,
      body: Column(
        children: [
          WebNavbar(
            selectedIndex: 5,
            onNavTap: (i) => widget.onTabChange?.call(i),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHero(),
                  FutureBuilder<List<Product>>(
                    future: _productsFuture,
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(child: CircularProgressIndicator(color: WebStyles.brand)),
                        );
                      }
                      final all = snap.data ?? [];
                      final filtered = _filter(all);
                      return Column(
                        children: [
                          _buildFiltersRow(all),
                          filtered.isEmpty
                              ? _buildEmpty()
                              : _buildGrid(filtered),
                        ],
                      );
                    },
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

  // ── Hero ──────────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [WebStyles.dark900, WebStyles.dark800, Color(0xFF1A1200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(40, 52, 40, 52),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: WebStyles.maxWidth),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: WebStyles.cta.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: WebStyles.cta.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.shopping_bag_rounded, size: 13, color: Color(0xFFFBD386)),
                          SizedBox(width: 6),
                          Text(
                            'CỬA HÀNG',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFBD386),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Dụng Cụ\nCầu Lông',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.08,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vợt, quả cầu, giày và phụ kiện chuyên nghiệp\n— chính hãng, bảo đảm chất lượng.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Search bar inline in hero
                    Container(
                      height: 48,
                      constraints: const BoxConstraints(maxWidth: 480),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(WebStyles.rMd),
                        boxShadow: WebStyles.shadowMd,
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm sản phẩm...',
                          prefixIcon: Icon(Icons.search_rounded, color: WebStyles.brand, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          hintStyle: TextStyle(color: WebStyles.inkFaint, fontSize: 14),
                        ),
                        style: const TextStyle(fontSize: 14, color: WebStyles.ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              _buildHeroIllustration(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIllustration() {
    return Container(
      width: 200,
      height: 180,
      decoration: BoxDecoration(
        color: WebStyles.cta.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(WebStyles.rXxl),
        border: Border.all(color: WebStyles.cta.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_tennis_rounded, size: 56, color: WebStyles.cta),
          const SizedBox(height: 10),
          Text(
            'Chính Hãng',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bảo đảm chất lượng',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filters row ───────────────────────────────────────────────────────────────
  Widget _buildFiltersRow(List<Product> all) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      decoration: const BoxDecoration(
        color: WebStyles.surface,
        border: Border(bottom: BorderSide(color: WebStyles.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: WebStyles.maxWidth),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _categories.map((cat) {
                final active = _selectedCategory == cat;
                final icon = _catIcons[cat] ?? Icons.category_rounded;
                final count = cat == 'Tất cả'
                    ? all.length
                    : all.where((p) => p.category == cat).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(WebStyles.rMd),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: active
                          ? BoxDecoration(
                              gradient: WebStyles.brandGrad,
                              borderRadius: BorderRadius.circular(WebStyles.rMd),
                            )
                          : BoxDecoration(
                              color: WebStyles.surface,
                              borderRadius: BorderRadius.circular(WebStyles.rMd),
                              border: Border.all(color: WebStyles.border),
                            ),
                      child: Row(
                        children: [
                          Icon(icon, size: 15, color: active ? Colors.white : WebStyles.inkLight),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                              color: active ? Colors.white : WebStyles.inkMid,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : WebStyles.border,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: active ? Colors.white : WebStyles.inkFaint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Product grid ──────────────────────────────────────────────────────────────
  Widget _buildGrid(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: WebStyles.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${products.length} sản phẩm',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: WebStyles.inkFaint,
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (ctx, bc) {
                  final cols = bc.maxWidth > 1200
                      ? 4
                      : bc.maxWidth > 900
                          ? 3
                          : bc.maxWidth > 600
                              ? 2
                              : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: products.length,
                    itemBuilder: (ctx, i) => _ProductCard(
                      product: products[i],
                      onBuy: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(product: products[i]),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: WebStyles.cta.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 36, color: WebStyles.cta),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không tìm thấy sản phẩm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: WebStyles.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
              style: TextStyle(fontSize: 14, color: WebStyles.inkFaint),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _selectedCategory = 'Tất cả';
                  _searchQuery = '';
                });
              },
              style: WebStyles.ghostBtn(),
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product card ─────────────────────────────────────────────────────────────
class _ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onBuy;
  const _ProductCard({required this.product, required this.onBuy});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovered = false;

  static const _catIcons = {
    'Vợt': Icons.sports_tennis_rounded,
    'Quả cầu': Icons.sports_rounded,
    'Giày': Icons.directions_walk_rounded,
    'Phụ kiện': Icons.category_rounded,
  };

  static const _catColors = {
    'Vợt': Color(0xFF059669),
    'Quả cầu': Color(0xFF0284C7),
    'Giày': Color(0xFFD97706),
    'Phụ kiện': Color(0xFF7C3AED),
  };

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final icon = _catIcons[p.category] ?? Icons.shopping_bag_rounded;
    final catColor = _catColors[p.category] ?? WebStyles.brand;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: _hovered ? WebStyles.cardActive(catColor) : WebStyles.card,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(WebStyles.rLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 168,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _hovered
                        ? [catColor, Color.lerp(catColor, Colors.black, 0.3)!]
                        : [WebStyles.dark800, WebStyles.dark900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: AnimatedScale(
                        scale: _hovered ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          icon,
                          size: 56,
                          color: Colors.white.withValues(alpha: _hovered ? 1.0 : 0.65),
                        ),
                      ),
                    ),
                    // Category badge top-right
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(WebStyles.rSm),
                        ),
                        child: Text(
                          p.category,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name + description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: WebStyles.cardTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((p.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              p.description ?? '',
                              style: WebStyles.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),

                      // Price + button
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(p.price)}đ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: catColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: widget.onBuy,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _hovered ? catColor : WebStyles.brand,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(WebStyles.rMd),
                                ),
                              ),
                              child: const Text(
                                'Mua ngay',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                              ),
                            ),
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
      ),
    );
  }
}
