import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quynh/auth/auth_service.dart';
import 'package:quynh/models/review.dart';
import 'package:quynh/services/review_service.dart';
import 'package:quynh/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:quynh/features/booking/screens/booking_history_screen.dart';

class UserReviewHistoryScreen extends StatefulWidget {
  const UserReviewHistoryScreen({super.key});

  @override
  State<UserReviewHistoryScreen> createState() => _UserReviewHistoryScreenState();
}

class _UserReviewHistoryScreenState extends State<UserReviewHistoryScreen> {
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
    
    final reviews = await ReviewService.getUserReviews(int.parse(auth.user!.id));
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
        title: const Text('Đánh giá của tôi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primary)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.primary), onPressed: () => Navigator.pop(context)),
        elevation: 0,
        backgroundColor: AppTheme.scaffoldLight,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        color: AppTheme.primary,
        child: Column(
          children: [
            _buildPromptCard(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _reviews.isEmpty
                  ? _buildEmptyState()
                  : _buildReviewList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bạn vừa chơi xong?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Hãy chia sẻ cảm nhận của bạn về sân nhé!', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingHistoryScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('VIẾT ĐÁNH GIÁ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ],
            ),
          ),
          const Icon(Icons.rate_review_rounded, color: Colors.white24, size: 80),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline_rounded, size: 64, color: AppTheme.textMuted.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('Bạn chưa có đánh giá nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        return _buildReviewCard(_reviews[index]);
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.courtName ?? 'Sân cầu lông', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.primary)),
                  Text(DateFormat('dd/MM/yyyy').format(review.createdAt), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
              Row(
                children: List.generate(5, (index) => Icon(
                  index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppTheme.accentGold, size: 14
                )),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(review.comment!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.5)),
          ],
          if (review.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.photos.length,
                itemBuilder: (context, idx) {
                  return Container(
                    width: 50,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(image: NetworkImage(review.photos[idx]), fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ],
          if (review.ownerReply != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chủ sân đã phản hồi:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.primary)),
                  const SizedBox(height: 4),
                  Text(review.ownerReply!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textPrimary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
