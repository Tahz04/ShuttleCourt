class Booking {
  final String id;
  final String courtName;
  final String courtAddress;
  final String slot;
  final DateTime date;
  final double price;
  final String paymentMethod;
  final DateTime createdAt;
  final String status;
  final String? userName; // Dành cho Owner quản lý

  Booking({
    required this.id,
    required this.courtName,
    required this.courtAddress,
    required this.slot,
    required this.date,
    required this.price,
    required this.paymentMethod,
    required this.createdAt,
    this.status = 'Chờ duyệt',
    this.userName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'].toString(),
      courtName: json['court_name'] ?? json['courtName'] ?? '',
      courtAddress: json['court_address'] ?? json['courtAddress'] ?? '',
      slot: json['slot'] ?? '',
      date: DateTime.parse(json['booking_date'] ?? json['date']),
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      paymentMethod: json['payment_method'] ?? json['paymentMethod'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      status: json['status'] ?? 'Chờ duyệt',
      userName: json['user_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'court_name': courtName,
      'court_address': courtAddress,
      'slot': slot,
      'booking_date': date.toIso8601String(),
      'price': price,
      'payment_method': paymentMethod,
      'status': status,
    };
  }
}
