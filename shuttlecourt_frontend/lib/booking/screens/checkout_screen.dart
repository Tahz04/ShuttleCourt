import 'package:flutter/material.dart';
import 'package:shuttlecourt/models/badminton_court.dart';
import 'package:shuttlecourt/models/booking.dart';
import 'package:uuid/uuid.dart';
import 'package:shuttlecourt/services/api_booking_service.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends StatefulWidget {
  final String selectedSlot;
  final BadmintonCourt selectedCourt;
  final DateTime selectedDate;

  const CheckoutScreen({
    super.key,
    required this.selectedSlot,
    required this.selectedCourt,
    required this.selectedDate,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPaymentMethod = 1; // 1: Cash, 2: VietQR
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Xác nhận đặt sân', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500), // Giới hạn độ rộng để đẹp trên Web
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Tóm tắt đặt sân'),
                const SizedBox(height: 12),
                
                // COMPACT TICKET CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                       _buildSummaryRow(Icons.sports_tennis_rounded, 'Sân', widget.selectedCourt.name, AppTheme.primary),
                       const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF5F5F5))),
                       _buildSummaryRow(Icons.calendar_month_rounded, 'Ngày', DateFormat('dd/MM/yyyy').format(widget.selectedDate), AppTheme.accentGold),
                       const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF5F5F5))),
                       _buildSummaryRow(Icons.access_time_filled_rounded, 'Khung giờ', widget.selectedSlot, AppTheme.accent),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _sectionTitle('Phương thức thanh toán'),
                const SizedBox(height: 12),

                _buildPaymentOption(1, 'Tiền mặt tại quầy', Icons.payments_rounded, Colors.green),
                const SizedBox(height: 10),
                _buildPaymentOption(2, 'Chuyển khoản VietQR', Icons.qr_code_scanner_rounded, AppTheme.primary),

                const SizedBox(height: 32),
                
                // TOTAL PRICE BAR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng', style: TextStyle(fontSize: 14, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                      Text(
                        currencyFormat.format(widget.selectedCourt.pricePerHour),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => _handleCheckout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('XÁC NHẬN ĐẶT SÂN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
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

  Widget _sectionTitle(String text) => Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary));

  Widget _buildSummaryRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor.withOpacity(0.7), size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildPaymentOption(int value, String title, IconData icon, Color color) {
    bool isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
            const Spacer(),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? color : Colors.grey.shade300,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _handleCheckout(BuildContext context) async {
    if (_selectedPaymentMethod == 2) {
      _showPaymentQR(context);
    } else {
      _processBooking(context, 'Tiền mặt');
    }
  }

  void _showPaymentQR(BuildContext context) {
    const bankBin = "970422"; 
    const bankAccount = "0986049032";
    const bankName = "NGUYEN VAN DUY";
    final amount = widget.selectedCourt.pricePerHour.toInt();
    final description = "Dat San ${widget.selectedCourt.name} ${DateFormat('ddMM').format(widget.selectedDate)}".replaceAll(' ', '');
    
    final qrUrl = "https://img.vietqr.io/image/$bankBin-$bankAccount-compact2.png?amount=$amount&addInfo=${Uri.encodeComponent(description)}&accountName=${Uri.encodeComponent(bankName)}";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('QUÉT MÃ THANH TOÁN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade100), borderRadius: BorderRadius.circular(12)),
              child: Image.network(qrUrl),
            ),
            const SizedBox(height: 12),
            Text(currencyFormat.format(amount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary)),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('ℹ️ Sau khi chuyển khoản thành công, nhấn xác nhận để chúng tôi kiểm tra nhé!', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _processBooking(context, 'Chuyển khoản QR');
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size(double.infinity, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('XÁC NHẬN ĐÃ CHUYỂN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processBooking(BuildContext context, String paymentMethod) async {
    print("====== [DEBUG] _processBooking BẮT ĐẦU ======");
    print("Payment Method: $paymentMethod");
    
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.user == null) {
      print("====== [DEBUG] LỖI: User bị null ======");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Bạn chưa đăng nhập hoặc phiên đăng nhập hết hạn.'), backgroundColor: Colors.red));
      return;
    }
    
    int currentUserId;
    try {
      currentUserId = int.parse(auth.user!.id);
      print("====== [DEBUG] User ID parse thành công: $currentUserId ======");
    } catch (e) {
      print("====== [DEBUG] LỖI parse ID: $e ======");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi ID người dùng: ${auth.user!.id}'), backgroundColor: Colors.red));
      return;
    }

    final booking = Booking(
      id: const Uuid().v4(),
      courtName: widget.selectedCourt.name,
      courtAddress: widget.selectedCourt.address,
      slot: widget.selectedSlot,
      date: widget.selectedDate,
      price: widget.selectedCourt.pricePerHour,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );

    print("====== [DEBUG] Hiển thị Loading Dialog ======");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)),
    );

    try {
      print("====== [DEBUG] Đang gọi ApiBookingService.createBooking... ======");
      await ApiBookingService.createBooking(currentUserId, booking);
      print("====== [DEBUG] ApiBookingService thành công! ======");
      
      if (mounted) {
        Navigator.pop(context); // Tắt loading
        _showSuccessDialog(context);
      }
    } catch (e) {
      print("====== [DEBUG] EXCEPTION BẮT ĐƯỢC: $e ======");
      if (mounted) {
        Navigator.pop(context); // Tắt loading dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 50),
        content: const Text('Yêu cầu đã được gửi! Vui lòng chờ thông báo xác nhận từ chủ sân nhé.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('HOÀN TẤT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
