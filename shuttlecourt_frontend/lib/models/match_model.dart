class MatchModel {
  final int id;
  final int hostId;
  final String hostName;
  final String courtName;
  final String level;
  final DateTime matchDate;
  final String startTime;
  final int capacity;
  final int joinedCount;
  final double price;
  final String description;

  MatchModel({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.courtName,
    required this.level,
    required this.matchDate,
    required this.startTime,
    required this.capacity,
    this.joinedCount = 1,
    required this.price,
    this.description = '',
  });

  bool get isExpired {
    try {
      final timeParts = startTime.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final matchDateTime = DateTime(
          matchDate.year,
          matchDate.month,
          matchDate.day,
          hour,
          minute,
        );
        return DateTime.now().isAfter(matchDateTime);
      }
    } catch (_) {}
    return false;
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'],
      hostId: json['host_id'],
      hostName: json['host_name'] ?? 'Ẩn danh',
      courtName: json['court_name'],
      level: json['level'],
      matchDate: _parseDateOnly(json['match_date']),
      startTime: json['start_time'],
      capacity: json['capacity'],
      joinedCount: json['joined_count'] ?? 1,
      price: double.parse(json['price'].toString()),
      description: json['description'] ?? '',
    );
  }

  static DateTime _parseDateOnly(dynamic raw) {
    if (raw == null) {
      return DateTime.now();
    }
    final parsed = DateTime.parse(raw.toString()).toLocal();
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
