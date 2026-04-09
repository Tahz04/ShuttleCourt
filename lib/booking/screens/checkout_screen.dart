import 'package:flutter/material.dart';
import 'package:quynh/models/badminton_court.dart';
import 'package:quynh/models/booking.dart';
import 'package:uuid/uuid.dart';
import 'package:quynh/services/api_booking_service.dart';
import 'package:provider/provider.dart';
import 'package:quynh/auth/auth_service.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tóm tắt đơn đặt sân', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Card(
              child: ListTile(
                leading: Icon(Icons.sports_tennis, color: Colors.green),
                title: Text(widget.selectedCourt.name),
                subtitle: Text('Ngày: ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}\n${widget.selectedCourt.address}'),
              ),
            ),
            ListTile(
              title: const Text('Khung giờ'),
              trailing: Text(widget.selectedSlot, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text('Giá thuê'),
              trailing: Text(
                '${widget.selectedCourt.pricePerHour.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
            ),
            const Divider(),
            const Text('Chọn phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            RadioListTile(
              value: 1,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
              title: const Text('Ví Momo / ZaloPay'),
              secondary: const Icon(Icons.wallet)
            ),
            RadioListTile(
              value: 2,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
              title: const Text('Chuyển khoản Ngân hàng (QR)'),
              secondary: const Icon(Icons.qr_code)
            ),
            RadioListTile(
              value: 3,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
              title: const Text('Thanh toán trực tiếp'),
              secondary: const Icon(Icons.money)
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                // Giả lập thanh toán thành công
                final paymentMethod = _selectedPaymentMethod == 1 ? 'Ví Momo / ZaloPay' :
                                     _selectedPaymentMethod == 2 ? 'Chuyển khoản Ngân hàng (QR)' :
                                     'Thanh toán trực tiếp';

                // Tạo booking mới
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

                // Lưu booking
                final auth = Provider.of<AuthService>(context, listen: false);
                int currentUserId = int.parse(auth.user!.id);

                try {
                  await ApiBookingService.createBooking(currentUserId, booking);

                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                        content: const Text('Đặt sân thành công!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                              child: const Text('VỀ TRANG CHỦ')
                          )
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'))
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
              child: const Text('THANH TOÁN NGAY', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}