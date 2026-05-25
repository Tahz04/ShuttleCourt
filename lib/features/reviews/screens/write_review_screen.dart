import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';

import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/config/api_config.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/services/review_service.dart';
import 'package:shuttlecourt/services/court_service.dart';
import 'package:shuttlecourt/models/badminton_court.dart';

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
        title: const Text('Đánh giá trải nghiệm', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppTheme.scaffoldLight,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: Column(
                children: [
                   const SizedBox(height: 20),
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(24),
                       boxShadow: AppTheme.softShadow,
                     ),
                     child: Row(
                       children: [
                         Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                           child: const Icon(Icons.sports_tennis_rounded, color: AppTheme.primary, size: 28),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Text('Bạn nghĩ sao về', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                               Text(widget.courtName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                             ],
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 32),
                   const Text('Chất lượng sân thế nào?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: List.generate(5, (index) {
                       bool isActive = _rating > index;
                       return GestureDetector(
                         onTap: () {
                           Feedback.forTap(context);
                           setState(() => _rating = index + 1);
                         },
                         child: AnimatedContainer(
                           duration: const Duration(milliseconds: 300),
                           curve: Curves.elasticOut,
                           margin: const EdgeInsets.symmetric(horizontal: 6),
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(
                             color: isActive ? AppTheme.accentGold.withOpacity(0.15) : Colors.transparent,
                             shape: BoxShape.circle,
                           ),
                           child: Icon(
                             isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                             color: isActive ? AppTheme.accentGold : AppTheme.textMuted.withOpacity(0.3),
                             size: 44,
                           ),
                         ),
                       );
                     }),
                   ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chọn thẻ nhận xét nhanh', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.primary)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: _quickTags.map((tag) {
                      bool isSelected = _selectedTags.contains(tag);
                      return InkWell(
                        onTap: () {
                           Feedback.forTap(context);
                           _toggleTag(tag);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderLight),
                            boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  const Text('Chi tiết đánh giá (Nếu có)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.primary)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Cảm nhận của bạn về buổi chơi hôm nay...',
                        hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('Hình ảnh thực tế', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.primary)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (_selectedImages.length < 3)
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 110,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 2, style: BorderStyle.solid),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, color: AppTheme.primary, size: 32),
                                  const SizedBox(height: 8),
                                  const Text('Thêm ảnh', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ),
                        ..._selectedImages.asMap().entries.map((entry) {
                          return Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(image: FileImage(entry.value), fit: BoxFit.cover),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 8, right: 8,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(entry.key),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
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
                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 8,
                        shadowColor: AppTheme.primary.withOpacity(0.4),
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('GỬI ĐÁNH GIÁ NGAY', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
