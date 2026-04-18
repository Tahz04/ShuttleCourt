import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';

import 'package:quynh/auth/auth_service.dart';
import 'package:quynh/config/api_config.dart';
import 'package:quynh/theme/app_theme.dart';
import 'package:quynh/services/review_service.dart';
import 'package:quynh/services/court_service.dart';
import 'package:quynh/models/badminton_court.dart';

class WriteReviewScreen extends StatefulWidget {
  final int? courtId;
  final String courtName;
  final int? bookingId;

  const WriteReviewScreen({
    super.key,
    this.courtId,
    required this.courtName,
    this.bookingId,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  
  // List of quick tags
  final List<String> _quickTags = [
    'Sân đẹp', 'Ánh sáng tốt', 'Sạch sẽ', 
    'Chủ sân nhiệt tình', 'Giá hợp lý', 'Mặt sân bám tốt'
  ];
  final Set<String> _selectedTags = {};

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chỉ được chọn tối đa 3 ảnh')));
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<String?> _uploadImage(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadUrl));
      request.files.add(
        await http.MultipartFile.fromPath('image', file.path, filename: path.basename(file.path))
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = json.decode(responseData);
        return data['imageUrl'];
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
    return null;
  }

  Future<void> _submitReview() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) return;

    if (_rating < 1 || _rating > 5) return;

    setState(() => _isSubmitting = true);

    try {
      int finalCourtId = widget.courtId ?? 1; // Default fallback
      if (widget.courtId == null) {
        // Try to find court ID by name
        final courts = await CourtService.getAllCourts();
        try {
          final court = courts.firstWhere((c) => c.name == widget.courtName);
          finalCourtId = int.parse(court.id);
        } catch (e) {
          finalCourtId = 1;
        }
      }

      List<String> uploadedPhotos = [];
      for (var file in _selectedImages) {
        String? url = await _uploadImage(file);
        if (url != null) uploadedPhotos.add(url);
      }

      String finalComment = _commentController.text.trim();
      if (_selectedTags.isNotEmpty) {
        String tagsString = _selectedTags.map((t) => '[$t]').join(' ');
        finalComment = '$tagsString\n$finalComment'.trim();
      }

      bool success = await ReviewService.createReview(
        courtId: finalCourtId,
        userId: int.parse(auth.user!.id),
        bookingId: widget.bookingId,
        rating: _rating,
        comment: finalComment.isEmpty ? null : finalComment,
        photos: uploadedPhotos.isEmpty ? null : uploadedPhotos,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: const Text('Đánh giá của bạn đã được gửi. Cảm ơn bạn!'),
             backgroundColor: AppTheme.primary,
             behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
           )
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại'), backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Đánh giá sân', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Court Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.sports_tennis_rounded, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sân bạn đã chơi', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text(widget.courtName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Rating Stars
            const Center(child: Text('Trải nghiệm của bạn thế nào?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(_rating > index ? 1.2 : 1.0),
                      child: Icon(
                        _rating > index ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: _rating > index ? AppTheme.accentGold : AppTheme.borderLight,
                        size: 40,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Quick Tags
            const Text('Điều gì làm bạn hài lòng?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _quickTags.map((tag) {
                bool isSelected = _selectedTags.contains(tag);
                return InkWell(
                  onTap: () => _toggleTag(tag),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderLight),
                      boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Comment Box
            const Text('Chia sẻ thêm chi tiết (Không bắt buộc)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Bạn nghĩ gì về chất lượng sân, nhân viên, cơ sở vật chất?...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Image Upload
            const Text('Thêm ảnh minh họa (Tối đa 3)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  if (_selectedImages.length < 3)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.2), style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, color: AppTheme.primary.withOpacity(0.6)),
                            const SizedBox(height: 4),
                            Text('Thêm ảnh', style: TextStyle(fontSize: 11, color: AppTheme.primary.withOpacity(0.6), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ..._selectedImages.asMap().entries.map((entry) {
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(image: FileImage(entry.value), fit: BoxFit.cover),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(entry.key),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('GỬI ĐÁNH GIÁ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
