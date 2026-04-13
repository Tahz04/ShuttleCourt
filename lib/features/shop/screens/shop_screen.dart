import 'package:flutter/material.dart';
import 'package:quynh/services/shop_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:quynh/auth/auth_service.dart';
import 'package:quynh/theme/app_theme.dart';
import 'package:quynh/features/shop/screens/checkout_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'Tất cả';
  final List<String> _categories = ['Tất cả', 'Vợt', 'Quả cầu', 'Giày', 'Phụ kiện'];
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final prods = await ShopService.getProducts();
    setState(() {
      _products = prods;
      _isLoading = false;
    });
  }

  Future<void> _handleOrder(Product product) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckoutScreen(product: product)),
    );
  }

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _selectedCategory == 'Tất cả'
        ? _products
        : _products.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildCategories()),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              )
            else if (filteredProducts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text('Chưa có sản phẩm nào', style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildProductCard(filteredProducts[index]),
                    childCount: filteredProducts.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('CỬA HÀNG', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6441A5), Color(0xFF2a0845)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(Icons.shopping_bag_rounded, size: 200, color: Colors.white.withOpacity(0.1)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ưu đãi lên đến 30%', 
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  Text('Dành riêng cho thành viên ShuttleCourt', 
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == _categories[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = _categories[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? AppTheme.glowShadow : AppTheme.cardShadow,
                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
              ),
              alignment: Alignment.center,
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData getIcon(String category) {
    switch (category) {
      case 'Vợt': return Icons.sports_tennis_rounded;
      case 'Quả cầu': return Icons.circle_outlined;
      case 'Giày': return Icons.nordic_walking_rounded;
      default: return Icons.shopping_bag_outlined;
    }
  }

  Widget _buildProductCard(Product product) {
    Widget buildProductImage() {
      if (product.imageUrl != null && product.imageUrl!.startsWith('data:image')) {
        try {
          String base64String = product.imageUrl!.split(',').last;
          
          // Tự động thêm padding nếu cần
          while (base64String.length % 4 != 0) {
            base64String += '=';
          }
          
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(base64Decode(base64String), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          );
        } catch (e) {
          return Icon(getIcon(product.category), size: 50, color: AppTheme.primary);
        }
      } else if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(product.imageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
        );
      }
      return Icon(getIcon(product.category), size: 50, color: AppTheme.primary);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Hero(
                  tag: 'prod_${product.id}',
                  child: buildProductImage(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.category,
                  style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary, height: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  _currencyFormat.format(product.price),
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 15),
                ),
                if (product.stock < 5)
                  Text(
                    'Chỉ còn ${product.stock} sản phẩm',
                    style: const TextStyle(color: AppTheme.error, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: product.stock > 0 ? () => _handleOrder(product) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  product.stock > 0 ? 'MUA NGAY' : 'HẾT HÀNG', 
                  style: const TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
