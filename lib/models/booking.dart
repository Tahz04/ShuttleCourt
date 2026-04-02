class Booking {
  final String id;
  final String courtName;
  final String courtAddress;
  final String slot;
  final DateTime date;
  final double price;
  final String paymentMethod;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.courtName,
    required this.courtAddress,
    required this.slot,
    required this.date,
    required this.price,
    required this.paymentMethod,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courtName': courtName,
      'courtAddress': courtAddress,
      'slot': slot,
      'date': date.toIso8601String(),
      'price': price,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      courtName: json['courtName'],
      courtAddress: json['courtAddress'],
      slot: json['slot'],
      date: DateTime.parse(json['date']),
      price: json['price'],
      paymentMethod: json['paymentMethod'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
