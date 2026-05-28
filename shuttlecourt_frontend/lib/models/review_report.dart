import 'package:shuttlecourt/models/review.dart';

class ReviewReport {
  final int reportId;
  final int reviewId;
  final int ownerId;
  final String? reason;
  final String status;
  final DateTime reportedAt;
  final Review review;

  ReviewReport({
    required this.reportId,
    required this.reviewId,
    required this.ownerId,
    required this.reason,
    required this.status,
    required this.reportedAt,
    required this.review,
  });

  factory ReviewReport.fromJson(Map<String, dynamic> json) {
    return ReviewReport(
      reportId: json['report_id'],
      reviewId: json['review_id'] ?? json['id'],
      ownerId: json['owner_id'],
      reason: json['reason'],
      status: json['status'] ?? 'pending',
      reportedAt: DateTime.parse(json['reported_at']),
      review: Review.fromJson(json),
    );
  }
}
