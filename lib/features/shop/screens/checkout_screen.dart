import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/services/shop_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends StatefulWidget {
  final Product product;
  const CheckoutScreen({super.key, required this.product});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _quantity = 1;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();
  String _paymentMethod = 'Tiền mặt';
  bool _isLoading = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  double get _subtotal => widget.product.price * _quantity;
  double get _discount => _promoController.text == 'shuttlecourt20' ? _subtotal * 0.2 : 0;
  double get _total => _subtotal - _discount;

  Future<void> _placeOrder() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập địa chỉ nhận hàng.')));
      return;
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    setState(() => _isLoading = true);

    final success = await ShopService.placeOrder(
      userId: auth.user!.id,
      totalPrice: _total,
      address: _addressController.text,
      paymentMethod: _paymentMethod,
      discountCode: _promoController.text.isNotEmpty ? _promoController.text : null,
      subtotal: _subtotal,
      discountAmount: _discount,
      items: [
        {
          'productId': widget.product.id,
          'quantity': _quantity,
          'price': widget.product.price,
        }
      ],
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        if (_paymentMethod == 'Quét mã QR') {
          _showQRDialog();
        } else {
          _showSuccessDialog();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Đặt hàng thất bại. Vui lòng thử lại.'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 60),
        title: const Text('Đặt hàng thành công!'),
        content: const Text('Đơn hàng của bạn đã được gửi đến chủ sân để xử lý.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to Shop
            },
            child: const Text('QUAY LẠI CỬA HÀNG'),
          ),
        ],
      ),
    );
  }

  void _showQRDialog() {
    // VIETQR CONFIG
    const bankId = 'MB'; // MB Bank
    const accountNo = '0986049032';
    const accountName = 'NGUYEN VAN DUY';
    final description = 'TT DON HANG ${_subtotal.toInt()}'.replaceAll(' ', '%20');
    final qrUrl = 'https://img.vietqr.io/image/$bankId-$accountNo-compact2.png?amount=${_total.toInt()}&addInfo=$description&accountName=$accountName';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text('QUÉT MÃ THANH TOÁN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primary)),
              const SizedBox(height: 8),
              const Text('Sử dụng ứng dụng ngân hàng của bạn để quét', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Image.network(qrUrl, height: 260, fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),
              _buildSummaryRow('Số tiền cần trả', _currencyFormat.format(_total), isTotal: true),
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vui lòng không thay đổi nội dung chuyển khoản để hệ thống xác nhận tự động.',
                        style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    Navigator.pop(context); // Back to Shop
                  },
                  child: const Text('TÔI ĐÃ THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('XÁC NHẬN ĐẶT HÀNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PRODUCT CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sports_tennis_rounded, color: AppTheme.primary, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(_currencyFormat.format(widget.product.price), 
                             style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // QUANTITY
            const Text('Số lượng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQtyBtn(Icons.remove, () { if (_quantity > 1) setState(() => _quantity--); }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _buildQtyBtn(Icons.add, () { if (_quantity < widget.product.stock) setState(() => _quantity++); }),
              ],
            ),
            const SizedBox(height: 24),

            // ADDRESS
            const Text('Địa chỉ nhận hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Nhập địa chỉ của bạn...',
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // PROMO
            const Text('Mã giảm giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      hintText: 'Dùng mã shuttlecourt20...',
                      prefixIcon: const Icon(Icons.confirmation_number_outlined, color: AppTheme.accent),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: () => setState(() {}), child: const Text('ÁP DỤNG')),
              ],
            ),
            const SizedBox(height: 24),

            // PAYMENT METHOD
            const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            _buildPaymentOption('Tiền mặt', Icons.payments_outlined),
            _buildPaymentOption('Quét mã QR', Icons.qr_code_scanner_rounded),
            const SizedBox(height: 24),

            // TOTALS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  _buildSummaryRow('Tạm tính', _currencyFormat.format(_subtotal)),
                  if (_discount > 0)
                    _buildSummaryRow('Giảm giá', '- ${_currencyFormat.format(_discount)}', isDiscount: true),
                  const Divider(height: 24),
                  _buildSummaryRow('Tổng cộng', _currencyFormat.format(_total), isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // PLACE ORDER BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _placeOrder,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ĐẶT HÀNG NGAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    final isSelected = _paymentMethod == title;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? AppTheme.textPrimary : AppTheme.textMuted, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
          Text(value, style: TextStyle(color: isDiscount ? AppTheme.error : (isTotal ? AppTheme.primary : AppTheme.textPrimary), fontWeight: FontWeight.bold, fontSize: isTotal ? 20 : 14)),
        ],
      ),
    );
  }
}
