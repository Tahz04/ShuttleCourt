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
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();
  String _paymentMethod = 'Tiền mặt';
  bool _isLoading = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  double get _subtotal => widget.product.price * _quantity;
  double get _discount => _promoController.text == 'shuttlecourt20' ? _subtotal * 0.2 : 0;
  double get _total => _subtotal - _discount;

  Future<void> _placeOrder() async {
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số sân hoặc vị trí của bạn.')));
      return;
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    setState(() => _isLoading = true);

    final success = await ShopService.placeOrder(
      userId: auth.user!.id,
      totalPrice: _total,
      address: _locationController.text,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 50),
        title: const Text('Đã nhận đơn hàng!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('Nhân viên sẽ mang hàng đến vị trí của bạn trong giây lát.', textAlign: TextAlign.center),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('TIẾP TỤC'),
            ),
          ),
        ],
      ),
    );
  }

  void _showQRDialog() {
    const bankId = 'MB';
    const accountNo = '0986049032';
    const accountName = 'NGUYEN VAN DUY';
    final description = 'TT DON HANG ${_total.toInt()}'.replaceAll(' ', '%20');
    final qrUrl = 'https://img.vietqr.io/image/$bankId-$accountNo-compact2.png?amount=${_total.toInt()}&addInfo=$description&accountName=$accountName';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('QUÉT MÃ THANH TOÁN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primary)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade100, width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.network(qrUrl, height: 240, fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Tổng tiền', _currencyFormat.format(_total), isTotal: true),
              const Divider(height: 24),
              Text('Người thụ hưởng: $accountName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSuccessDialog();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('XÁC NHẬN ĐÃ CHUYỂN', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('XÁC NHẬN MUA HÀNG', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PRODUCT COMPACT CARD
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 60, height: 60,
                          color: AppTheme.primary.withOpacity(0.05),
                          child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.primary, size: 30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            Text(_currencyFormat.format(widget.product.price), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _buildQtyBtn(Icons.remove, () { if (_quantity > 1) setState(() => _quantity--); }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('$_quantity', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                          _buildQtyBtn(Icons.add, () { if (_quantity < widget.product.stock) setState(() => _quantity++); }),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // DOMAIN FIX: Vị trí nhận hàng tại sân
                _sectionTitle('Vị trí nhận hàng tại sân'),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Nhập số sân hoặc tên quầy (VD: Sân 5)',
                    prefixIcon: const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
                const SizedBox(height: 20),

                _sectionTitle('Mã giảm giá'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Nhập mã khuyến mãi...',
                          prefixIcon: const Icon(Icons.confirmation_number_rounded, color: AppTheme.accent, size: 18),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('ÁP DỤNG', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _sectionTitle('Thanh toán'),
                const SizedBox(height: 8),
                _buildPaymentOption('Tiền mặt', Icons.payments_rounded),
                _buildPaymentOption('Quét mã QR', Icons.qr_code_scanner_rounded),
                const SizedBox(height: 20),

                // RECEIPT STYLE SUMMARY
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Tạm tính', _currencyFormat.format(_subtotal)),
                      if (_discount > 0)
                        _buildSummaryRow('Giảm giá', '- ${_currencyFormat.format(_discount)}', isDiscount: true),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFEEEEEE))),
                      _buildSummaryRow('Tổng cộng', _currencyFormat.format(_total), isTotal: true),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('XÁC NHẬN MUA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary));

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
        child: Icon(icon, size: 16, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    final isSelected = _paymentMethod == title;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textMuted, size: 20),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 14, color: isSelected ? AppTheme.primary : AppTheme.textPrimary)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? AppTheme.textPrimary : AppTheme.textMuted, fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500, fontSize: isTotal ? 15 : 13)),
          Text(value, style: TextStyle(color: isDiscount ? AppTheme.error : (isTotal ? AppTheme.primary : AppTheme.textPrimary), fontWeight: FontWeight.w800, fontSize: isTotal ? 18 : 13)),
        ],
      ),
    );
  }
}
