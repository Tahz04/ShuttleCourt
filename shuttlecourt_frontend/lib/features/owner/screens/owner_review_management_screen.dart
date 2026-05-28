import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/models/review.dart';
import 'package:shuttlecourt/models/review_report.dart';
import 'package:shuttlecourt/services/review_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:intl/intl.dart';

class OwnerReviewManagementScreen extends StatefulWidget {
  final bool isAdmin;
  const OwnerReviewManagementScreen({super.key, this.isAdmin = false});

  @override
  State<OwnerReviewManagementScreen> createState() =>
      _OwnerReviewManagementScreenState();
}

class _OwnerReviewManagementScreenState
    extends State<OwnerReviewManagementScreen> {
  bool _isLoading = true;
  List<Review> _reviews = [];
  List<ReviewReport> _reports = [];
  bool _showReports = false;

  @override
  void initState() {
    super.initState();
    if (widget.isAdmin) {
      _showReports = true;
      _loadReports();
    } else {
      _loadReviews();
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final reviews = widget.isAdmin
        ? await ReviewService.getAllReviews()
        : await ReviewService.getOwnerReviews(int.parse(auth.user!.id));
    setState(() {
      _reviews = reviews;
      _isLoading = false;
    });
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final reports = await ReviewService.getReviewReports();
    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text(
          'Quản lý Đánh giá',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppTheme.primary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: AppTheme.scaffoldLight,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: widget.isAdmin
            ? (_showReports ? _loadReports : _loadReviews)
            : _loadReviews,
        color: AppTheme.primary,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : widget.isAdmin
            ? (_showReports ? _buildReportList() : _buildReviewList())
            : (_reviews.isEmpty ? _buildEmptyState() : _buildReviewList()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: _buildEmptyStateContent());
  }

  Widget _buildEmptyStateContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.rate_review_outlined,
          size: 80,
          color: AppTheme.textMuted.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        const Text(
          'Chưa có đánh giá nào',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Các đánh giá từ khách hàng sẽ xuất hiện ở đây.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEmptyReportsState() {
    return Center(child: _buildEmptyReportsStateContent());
  }

  Widget _buildEmptyReportsStateContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.report_gmailerrorred_rounded,
          size: 80,
          color: AppTheme.textMuted.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        const Text(
          'Chưa có báo cáo nào',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Các báo cáo đánh giá sẽ xuất hiện ở đây.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAdminToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Báo cáo',
              isActive: _showReports,
              onTap: () {
                if (_showReports) return;
                setState(() => _showReports = true);
                _loadReports();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildToggleButton(
              label: 'Tất cả',
              isActive: !_showReports,
              onTap: () {
                if (!_showReports) return;
                setState(() => _showReports = false);
                _loadReviews();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewList() {
    final hasHeader = widget.isAdmin;
    if (hasHeader && _reviews.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildAdminToggle(),
          const SizedBox(height: 80),
          _buildEmptyStateContent(),
        ],
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _reviews.length + (hasHeader ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasHeader && index == 0) {
          return _buildAdminToggle();
        }
        final reviewIndex = hasHeader ? index - 1 : index;
        return _buildReviewCard(_reviews[reviewIndex]);
      },
    );
  }

  Widget _buildReportList() {
    if (_reports.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildAdminToggle(),
          const SizedBox(height: 80),
          _buildEmptyReportsStateContent(),
        ],
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _reports.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildAdminToggle();
        }
        return _buildReportCard(_reports[index - 1]);
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    final ownerName = review.ownerName?.trim();
    final ownerLabel = widget.isAdmin
        ? (ownerName == null || ownerName.isEmpty
              ? 'Phản hồi của Owner'
              : 'Phản hồi của Owner $ownerName')
        : 'Phản hồi của bạn';
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
                      child: Text(
                        (review.userName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.userName ?? 'Khách hàng',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Đã đánh giá ${review.courtName}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
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
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < review.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppTheme.accentGold,
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(review.createdAt),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              review.comment!,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
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
                      image: DecorationImage(
                        image: NetworkImage(review.photos[idx]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppTheme.borderLight),
          ),

          if (review.ownerReply != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: AppTheme.primary, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$ownerLabel:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppTheme.primary,
                        ),
                      ),
                      if (review.ownerReplyAt != null)
                        Text(
                          DateFormat('dd/MM/yyyy').format(review.ownerReplyAt!),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.ownerReply!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _showReplyDialog(review),
                icon: const Icon(Icons.reply_rounded, size: 18),
                label: const Text(
                  'TRẢ LỜI ĐÁNH GIÁ',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.primary.withOpacity(0.1)),
                  ),
                ),
              ),
            ),
          ],
          if (!widget.isAdmin) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _showReportDialog(review),
                icon: const Icon(Icons.report_gmailerrorred_rounded, size: 18),
                label: const Text(
                  'BÁO CÁO ĐÁNH GIÁ',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.error.withOpacity(0.2)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportCard(ReviewReport report) {
    final review = report.review;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.courtName ?? 'Sân',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Báo cáo lúc ${DateFormat('dd/MM/yyyy').format(report.reportedAt)}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppTheme.accentGold,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Người đánh giá: ${review.userName ?? 'Ẩn danh'}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          if (report.reason != null && report.reason!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error.withOpacity(0.2)),
              ),
              child: Text(
                'Lý do: ${report.reason}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _resolveReport(report, 'keep'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: AppTheme.borderLight),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'GIỮ',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _resolveReport(report, 'delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'XÓA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(Review review) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Phản hồi đánh giá',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.primary,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung phản hồi...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'HỦY',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final success = await ReviewService.replyToReview(
                reviewId: review.id,
                reply: controller.text.trim(),
              );
              if (success && mounted) {
                Navigator.pop(context);
                _loadReviews();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã gửi phản hồi thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'GỬI',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(Review review) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Báo cáo đánh giá',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.primary,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Nhập lý do báo cáo...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'HỦY',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthService>(context, listen: false);
              if (auth.user == null) return;
              final success = await ReviewService.reportReview(
                reviewId: review.id,
                ownerId: int.parse(auth.user!.id),
                reason: controller.text.trim().isEmpty
                    ? null
                    : controller.text.trim(),
              );
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã gửi báo cáo thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'GỬI',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveReport(ReviewReport report, String action) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await ReviewService.resolveReviewReport(
      reportId: report.reportId,
      action: action,
      adminId: auth.user != null ? int.parse(auth.user!.id) : null,
    );
    if (success && mounted) {
      _loadReports();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'delete' ? 'Đã xóa đánh giá' : 'Đã giữ đánh giá',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
