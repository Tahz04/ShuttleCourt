class Review {
  final int id;
  final int courtId;
  final int userId;
  final int? bookingId;
  final int rating;
  final String? comment;
  final List<String> photos;
  final DateTime createdAt;
  final String? userName;
  final String? courtName;

  final String? ownerReply;
  final DateTime? ownerReplyAt;

  Review({
    required this.id,
    required this.courtId,
    required this.userId,
    this.bookingId,
    required this.rating,
    this.comment,
    required this.photos,
    required this.createdAt,
    this.userName,
    this.courtName,
    this.ownerReply,
    this.ownerReplyAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    List<String> parsedPhotos = [];
    if (json['photos'] != null) {
      if (json['photos'] is String) {
        try {
            final parsedString = json['photos'] as String;
            if (parsedString.startsWith('[') && parsedString.endsWith(']')) {
              parsedPhotos = parsedString.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            } else {
              parsedPhotos = [parsedString];
            }
        } catch (e) {
            parsedPhotos = [];
        }
      } else if (json['photos'] is List) {
        parsedPhotos = List<String>.from(json['photos']);
      }
    }

    return Review(
      id: json['id'],
      courtId: json['court_id'],
      userId: json['user_id'],
      bookingId: json['booking_id'],
      rating: json['rating'],
      comment: json['comment'],
      photos: parsedPhotos,
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'],
      courtName: json['court_name'],
      ownerReply: json['owner_reply'],
      ownerReplyAt: json['owner_reply_at'] != null ? DateTime.parse(json['owner_reply_at']) : null,
    );
  }
}
