import 'package:flutter/material.dart';
import 'package:quynh/models/badminton_court.dart';
import 'package:quynh/models/booking.dart';
import 'package:uuid/uuid.dart';
import 'package:quynh/services/api_booking_service.dart';
import 'package:provider/provider.dart';
import 'package:quynh/auth/auth_service.dart';
import 'package:quynh/theme/app_theme.dart';
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Xác Nhận Đặt Sân', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tóm tắt đặt sân', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            
            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                   _buildSummaryRow(Icons.sports_tennis_rounded, 'Tên sân', widget.selectedCourt.name, AppTheme.primary),
                   const Divider(height: 30, color: Color(0xFFF5F5F5)),
                   _buildSummaryRow(Icons.location_on_rounded, 'Địa chỉ', widget.selectedCourt.address, AppTheme.error),
                   const Divider(height: 30, color: Color(0xFFF5F5F5)),
                   _buildSummaryRow(Icons.calendar_month_rounded, 'Ngày đặt', DateFormat('dd/MM/yyyy').format(widget.selectedDate), AppTheme.accentGold),
                   const Divider(height: 30, color: Color(0xFFF5F5F5)),
                   _buildSummaryRow(Icons.access_time_filled_rounded, 'Khung giờ', widget.selectedSlot, AppTheme.accent),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text('Hình thức thanh toán', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),

            _buildPaymentOption(1, 'Thanh toán tiền mặt', Icons.payments_rounded, Colors.green),
            const SizedBox(height: 12),
            _buildPaymentOption(2, 'Chuyển khoản QR (VietQR)', Icons.qr_code_scanner_rounded, AppTheme.primary),

            const SizedBox(height: 35),
            
            // Total Price Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng', style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600)),
                  Text(
                    currencyFormat.format(widget.selectedCourt.pricePerHour),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 35),
            
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: () => _handleCheckout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: AppTheme.primary.withOpacity(0.4),
                ),
                child: const Text('XÁC NHẬN ĐẶT SÂN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(int value, String title, IconData icon, Color color) {
    bool isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(color: AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, fontSize: 15)),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 24)
            else
              Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2))),
          ],
        ),
      ),
    );
  }

  void _handleCheckout(BuildContext context) async {
    if (_selectedPaymentMethod == 2) {
      // THANH TOÁN QR
      _showPaymentQR(context);
    } else {
      // THANH TOÁN TIỀN MẶT
      _processBooking(context, 'Tiền mặt');
    }
  }

  void _showPaymentQR(BuildContext context) {
    // THÔNG TIN CHỦ SÂN DUY
    const bankBin = "970422"; // MB Bank
    const bankAccount = "0986049032";
    const bankName = "NGUYEN VAN DUY";
    final amount = widget.selectedCourt.pricePerHour.toInt();
    final description = "Dat San ${widget.selectedCourt.name} ${DateFormat('ddMM').format(widget.selectedDate)} ${widget.selectedSlot.split(' ')[0]}";
    
    final qrUrl = "https://img.vietqr.io/image/$bankBin-$bankAccount-compact2.png?amount=$amount&addInfo=${Uri.encodeComponent(description)}&accountName=${Uri.encodeComponent(bankName)}";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text('QUÉT MÃ THANH TOÁN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 240, height: 240,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200, width: 2), borderRadius: BorderRadius.circular(12)),
                child: Image.network(qrUrl, loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                }),
              ),
              const SizedBox(height: 16),
              Text(currencyFormat.format(amount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary)),
              const Text('Người thụ hưởng: NGUYEN VAN DUY', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('ℹ️ Sau khi chuyển khoản thành công, hãy nhấn nút "XÁC NHẬN ĐÃ CHUYỂN" bên dưới.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _processBooking(context, 'Chuyển khoản QR');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('XÁC NHẬN ĐÃ CHUYỂN', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _processBooking(BuildContext context, String paymentMethod) async {
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

    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.user == null) return;
    int currentUserId = int.parse(auth.user!.id);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );

    try {
      await ApiBookingService.createBooking(currentUserId, booking);
      if (mounted) {
        Navigator.pop(context); // Tắt loading
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Column(
              children: [
                Icon(Icons.hourglass_top_rounded, color: Colors.blue, size: 70),
                SizedBox(height: 16),
                Text('YÊU CẦU ĐÃ ĐƯỢC GỬI!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
            content: Text('Yêu cầu đặt sân cho khung giờ ${widget.selectedSlot} đã được gửi tới chủ sân. Vui lòng chờ thông báo xác nhận từ chúng tôi nhé!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('VỀ TRANG CHỦ', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error));
      }
    }
  }
}