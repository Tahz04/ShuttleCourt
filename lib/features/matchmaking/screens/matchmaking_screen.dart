import 'package:flutter/material.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  String selectedLevel = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tìm Kèo Ghép', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. THANH LỌC TRÌNH ĐỘ (CHIPS)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Tất cả', 'Mới chơi', 'Trung bình', 'Khá', 'Pro'].map((level) {
                  bool isSelected = selectedLevel == level;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(level),
                      selected: isSelected,
                      onSelected: (val) => setState(() => selectedLevel = level),
                      selectedColor: Colors.blueAccent.withOpacity(0.2),
                      checkmarkColor: Colors.blueAccent,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blueAccent : Colors.black54,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 2. DANH SÁCH KÈO CHI TIẾT
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => _buildAdvancedMatchCard(context, index),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Tạo Kèo Mới'),
        icon: const Icon(Icons.add_location_alt_rounded),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildAdvancedMatchCard(BuildContext context, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blueGrey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Phần Header của Card (Ảnh sân + Trạng thái)
          Stack(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(colors: [Colors.blueAccent, Colors.blue.shade200]),
                ),
                child: const Center(child: Icon(Icons.sports_tennis, size: 50, color: Colors.white)),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Text('🔥 Thiếu 2 người', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ),
              ),
            ],
          ),

          // Phần nội dung
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sân Cầu Lông Kỳ Hòa - Quận 10', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const CircleAvatar(radius: 12, backgroundColor: Colors.blueAccent, child: Icon(Icons.person, size: 15, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Text('Host: Nam Nguyễn', style: TextStyle(color: Colors.grey)),
                    const Spacer(),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const Text(' 4.9', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconDetail(Icons.calendar_today, 'Sáng mai', '08:00 - 10:00'),
                    _buildIconDetail(Icons.flash_on, 'Trình độ', 'Khá - Pro'),
                    _buildIconDetail(Icons.monetization_on, 'Phí dự kiến', '35k/người'),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showMatchDetails(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('XEM CHI TIẾT & THAM GIA', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconDetail(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.blueAccent),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showMatchDetails(BuildContext context) {
    // Logic hiện popup hoặc trang chi tiết
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang tải thông tin trận đấu...')));
  }
}