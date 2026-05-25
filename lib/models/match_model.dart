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

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'],
      hostId: json['host_id'],
      hostName: json['host_name'] ?? 'Ẩn danh',
      courtName: json['court_name'],
      level: json['level'],
      matchDate: DateTime.parse(json['match_date']),
      startTime: json['start_time'],
      capacity: json['capacity'],
      joinedCount: json['joined_count'] ?? 1,
      price: double.parse(json['price'].toString()),
      description: json['description'] ?? '',
    );
  }
}
