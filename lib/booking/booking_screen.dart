import 'package:flutter/material.dart';
import 'screens/checkout_screen.dart';
import 'package:quynh/models/badminton_court.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Giả lập danh sách khung giờ
  final List<String> _timeSlots = [
    '05:00 - 06:00', '06:00 - 07:00', '07:00 - 08:00',
    '17:00 - 18:00', '18:00 - 19:00', '19:00 - 20:00',
    '20:00 - 21:00', '21:00 - 22:00'
  ];

  String _selectedSlot = '';
  BadmintonCourt? _selectedCourt;
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedCourt == null ? 'Chọn sân để đặt' : 'Đặt sân ngay',
          style: const TextStyle(color: Colors.white)
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _selectedCourt != null ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _selectedCourt = null;
              _selectedSlot = '';
              _selectedDate = DateTime.now();
            });
          },
        ) : null,
      ),
      body: _selectedCourt == null ? _buildCourtSelection() : _buildBookingDetails(),
    );
  }

  // Widget chọn sân
  Widget _buildCourtSelection() {
    final filteredCourts = sampleBadmintonCourts.where((court) => court.name.toLowerCase().contains(_searchQuery.toLowerCase()) || court.address.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Chọn sân cầu lông bạn muốn đặt',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // Thanh tìm kiếm
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sân theo tên hoặc địa chỉ',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.green),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredCourts.length,
            itemBuilder: (context, index) {
              final court = filteredCourts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCourt = court;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.sports_tennis,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                court.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                court.address,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${court.rating} (${court.reviews})',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${court.pricePerHour.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ/giờ',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget chi tiết đặt sân (sau khi chọn sân)
  Widget _buildBookingDetails() {
    if (_selectedCourt == null) return const SizedBox.shrink();

    return Column(
      children: [
        // 1. Thông tin tóm tắt sân
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.withOpacity(0.1),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sports_tennis,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCourt!.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    Text(
                      _selectedCourt!.address,
                      style: const TextStyle(color: Colors.grey)
                    ),
                    Text(
                      '${_selectedCourt!.pricePerHour.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ / Giờ',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              )
            ],
          ),
        ),

        // 2. Chọn ngày
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Chọn ngày: ${DateFormat('EEEE, dd/MM/yyyy').format(_selectedDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),

        // 3. Danh sách khung giờ
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _timeSlots.length,
            itemBuilder: (context, index) {
              bool isSelected = _selectedSlot == _timeSlots[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSlot = _timeSlots[index];
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.white,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _timeSlots[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 4. Nút tiến hành thanh toán
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _selectedSlot.isEmpty
                ? null
                : () {
              // Chuyển sang màn hình Thanh toán và truyền thông tin sân và khung giờ
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutScreen(
                    selectedSlot: _selectedSlot,
                    selectedCourt: _selectedCourt!,
                    selectedDate: _selectedDate,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: const Text(
                'TIẾN HÀNH THANH TOÁN',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ),
        ),
      ],
    );
  }
}
