import 'package:flutter/material.dart';
import 'package:quynh/models/review.dart';
import 'package:quynh/services/review_service.dart';
import 'package:quynh/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CourtReviewsScreen extends StatefulWidget {
  final int courtId;
  final String courtName;

  const CourtReviewsScreen({super.key, required this.courtId, required this.courtName});

  @override
  State<CourtReviewsScreen> createState() => _CourtReviewsScreenState();
}

class _CourtReviewsScreenState extends State<CourtReviewsScreen> {
  bool _isLoading = true;
  List<Review> _reviews = [];
  dynamic _averageRating = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final data = await ReviewService.getCourtReviews(widget.courtId);
    setState(() {
      _reviews = data['reviews'];
      _averageRating = data['averageRating'];
      _total = data['total'];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: Text('Đánh giá: ${widget.courtName}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : _reviews.isEmpty
          ? _buildEmptyState()
          : _buildReviewList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline_rounded, size: 80, color: AppTheme.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Chưa có đánh giá nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Hãy là người đầu tiên trải nghiệm và đánh giá sân này.', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Text(
                  _averageRating.toString(),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.primary, height: 1),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) => Icon(
                        index < (_averageRating is String ? double.parse(_averageRating) : _averageRating).round() ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppTheme.accentGold, size: 20
                      )),
                    ),
                    const SizedBox(height: 4),
                    Text('Dựa trên $_total đánh giá', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final review = _reviews[index];
              return _buildReviewItem(review);
            },
            childCount: _reviews.length,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text((review.userName ?? 'U')[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.userName ?? 'Người dùng Ẩn danh', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(DateFormat('dd/MM/yyyy').format(review.createdAt), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
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
            const SizedBox(height: 16),
            Text(review.comment!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5)),
          ],
          if (review.photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.photos.length,
                itemBuilder: (context, idx) {
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(image: NetworkImage(review.photos[idx]), fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ]
        ],
      ),
    );
  }
}
