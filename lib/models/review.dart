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
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    List<String> parsedPhotos = [];
    if (json['photos'] != null) {
      if (json['photos'] is String) {
        // Depending on how JSON is returned from MySQL
        try {
            // some db drivers return JSON strings
            final parsedString = json['photos'] as String;
            parsedPhotos = parsedString.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
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
    );
  }
}
