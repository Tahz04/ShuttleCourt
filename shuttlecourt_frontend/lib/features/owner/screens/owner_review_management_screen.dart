import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/models/review.dart';
import 'package:shuttlecourt/services/review_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:intl/intl.dart';

class OwnerReviewManagementScreen extends StatefulWidget {
  const OwnerReviewManagementScreen({super.key});

  @override
  State<OwnerReviewManagementScreen> createState() => _OwnerReviewManagementScreenState();
}

class _OwnerReviewManagementScreenState extends State<OwnerReviewManagementScreen> {
  bool _isLoading = true;
  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.user == null) return;
    
    final reviews = await ReviewService.getOwnerReviews(int.parse(auth.user!.id));
    setState(() {
      _reviews = reviews;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Quản lý Đánh giá', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primary)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        elevation: 0,
        backgroundColor: AppTheme.scaffoldLight,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        color: AppTheme.primary,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _reviews.isEmpty
            ? _buildEmptyState()
            : _buildReviewList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: AppTheme.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Chưa có đánh giá nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Các đánh giá từ khách hàng sẽ xuất hiện ở đây.', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        return _buildReviewCard(_reviews[index]);
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text((review.userName ?? 'U')[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review.userName ?? 'Khách hàng', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('Đã đánh giá ${review.courtName}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: List.generate(5, (index) => Icon(
                      index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppTheme.accentGold, size: 14
                    )),
                  ),
                  const SizedBox(height: 4),
                  Text(DateFormat('dd/MM/yyyy').format(review.createdAt), style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(review.comment!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5)),
          ],
          if (review.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.photos.length,
                itemBuilder: (context, idx) {
                  return Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: NetworkImage(review.photos[idx]), fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ],
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppTheme.borderLight)),
          
          if (review.ownerReply != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: AppTheme.primary, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phản hồi của bạn:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.primary)),
                      if (review.ownerReplyAt != null)
                        Text(DateFormat('dd/MM/yyyy').format(review.ownerReplyAt!), style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review.ownerReply!, style: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textPrimary)),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _showReplyDialog(review),
                icon: const Icon(Icons.reply_rounded, size: 18),
                label: const Text('TRẢ LỜI ĐÁNH GIÁ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.primary.withOpacity(0.1))),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReplyDialog(Review review) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phản hồi đánh giá', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung phản hồi...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final success = await ReviewService.replyToReview(reviewId: review.id, reply: controller.text.trim());
              if (success && mounted) {
                Navigator.pop(context);
                _loadReviews();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi phản hồi thành công!'), backgroundColor: Colors.green));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('GỬI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
