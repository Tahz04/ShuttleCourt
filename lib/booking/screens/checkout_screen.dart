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
  int _selectedPaymentMethod = 1; // 1: Momo/ZaloPay, 2: Bank QR, 3: Direct Payment

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Xác Nhận Đặt Sân', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                   _buildSummaryRow(Icons.sports_tennis_rounded, 'Sân', widget.selectedCourt.name, AppTheme.primary),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),
                  _buildSummaryRow(Icons.location_on_rounded, 'Địa chỉ', widget.selectedCourt.address, AppTheme.error),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),
                  _buildSummaryRow(Icons.calendar_month_rounded, 'Ngày', DateFormat('dd/MM/yyyy').format(widget.selectedDate), AppTheme.accentGold),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),
                  _buildSummaryRow(Icons.access_time_filled_rounded, 'Khung giờ', widget.selectedSlot, AppTheme.accent),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const Text('Phương thức thanh toán', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),

            _buildPaymentOption(1, 'Ví Momo / ZaloPay', Icons.account_balance_wallet_rounded, AppTheme.primary),
            const SizedBox(height: 10),
            _buildPaymentOption(2, 'Chuyển khoản Ngân hàng (QR)', Icons.qr_code_scanner_rounded, AppTheme.accent),
            const SizedBox(height: 10),
            _buildPaymentOption(3, 'Thanh toán tại quầy', Icons.payments_rounded, AppTheme.accentGold),

            const SizedBox(height: 32),
            
            // Total Price Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng:', style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  Text(
                    currencyFormat.format(widget.selectedCourt.pricePerHour),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _handlePayment(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppTheme.primary.withOpacity(0.2),
                ),
                child: const Text('XÁC NHẬN & THANH TOÁN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(title, style: TextStyle(color: AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 22)
            else
              Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2))),
          ],
        ),
      ),
    );
  }

  void _handlePayment(BuildContext context) async {
    final paymentMethod = _selectedPaymentMethod == 1 ? 'Ví Momo / ZaloPay' :
                         _selectedPaymentMethod == 2 ? 'Chuyển khoản Ngân hàng (QR)' :
                         'Thanh toán trực tiếp';

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
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Column(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 70),
                SizedBox(height: 16),
                Text('Thành Công!', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
              ],
            ),
            content: const Text('Bạn đã đặt sân thành công. Hãy đến đúng giờ nhé!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('VỀ TRANG CHỦ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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