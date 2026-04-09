import 'package:flutter/material.dart';

class CheckoutScreen extends StatelessWidget {
  final String selectedSlot;
  const CheckoutScreen({super.key, required this.selectedSlot});

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
            const Card(
              child: ListTile(
                leading: Icon(Icons.sports_tennis, color: Colors.green),
                title: Text('Sân Cầu Lông ABC'),
                subtitle: Text('Ngày: 28/03/2026'),
              ),
            ),
            ListTile(
              title: const Text('Khung giờ'),
              trailing: Text(selectedSlot, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const ListTile(
              title: Text('Giá thuê'),
              trailing: Text('50.000đ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            const Text('Chọn phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            RadioListTile(value: 1, groupValue: 1, onChanged: (v){}, title: const Text('Ví Momo / ZaloPay'), secondary: const Icon(Icons.wallet)),
            RadioListTile(value: 2, groupValue: 1, onChanged: (v){}, title: const Text('Chuyển khoản Ngân hàng (QR)'), secondary: const Icon(Icons.qr_code)),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Hiển thị thông báo thành công
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                    content: const Text('Đặt sân thành công! Chúc bạn có những giờ phút chơi cầu vui vẻ.', textAlign: TextAlign.center),
                    actions: [TextButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('VỀ TRANG CHỦ'))],
                  ),
                );
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