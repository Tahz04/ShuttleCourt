import 'package:flutter/material.dart';
import 'package:shuttlecourt/services/shop_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/features/shop/screens/add_product_screen.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class OwnerShopManagementScreen extends StatefulWidget {
  const OwnerShopManagementScreen({super.key});

  @override
  State<OwnerShopManagementScreen> createState() => _OwnerShopManagementScreenState();
}

class _OwnerShopManagementScreenState extends State<OwnerShopManagementScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final prods = await ShopService.getProducts(showAll: true);
    setState(() {
      _products = prods;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('QUẢN LÝ SẢN PHẨM', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Thêm sản phẩm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _products.isEmpty
            ? const Center(child: Text('Chưa có sản phẩm nào trong cửa hàng.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final prod = _products[index];
                  IconData getIcon() {
                    switch (prod.category) {
                      case 'Vợt': return Icons.sports_tennis_rounded;
                      case 'Quả cầu': return Icons.circle_outlined;
                      case 'Giày': return Icons.nordic_walking_rounded;
                      default: return Icons.shopping_bag_outlined;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: (prod.imageUrl != null && prod.imageUrl!.startsWith('data:image'))
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Builder(
                                  builder: (context) {
                                    try {
                                      String b64 = prod.imageUrl!.split(',').last;
                                      while (b64.length % 4 != 0) { b64 += '='; }
                                      return Image.memory(base64Decode(b64), fit: BoxFit.cover);
                                    } catch (e) {
                                      return Icon(getIcon(), color: AppTheme.primary, size: 30);
                                    }
                                  }
                                ),
                              )
                            : (prod.imageUrl != null && prod.imageUrl!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(prod.imageUrl!, fit: BoxFit.cover),
                                )
                              : Icon(getIcon(), color: AppTheme.primary, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Giá: ${_currencyFormat.format(prod.price)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Kho: ${prod.stock} cái', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppTheme.accent),
                          onPressed: () async {
                            final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(product: prod)));
                            if (updated == true) _loadProducts();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                          onPressed: () => _confirmDelete(prod),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ShopService.deleteProduct(product.id!);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã xóa sản phẩm thành công!'), backgroundColor: AppTheme.success));
          _loadProducts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Lỗi khi xóa sản phẩm.'), backgroundColor: AppTheme.error));
        }
      }
    }
  }
}
