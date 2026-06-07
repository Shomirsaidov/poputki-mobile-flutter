class Ride {
  final int id;
  final String fromCity;
  final String toCity;
  final String date;
  final String time;
  final double price;
  final int seats;
  final int? bookedSeats;
  final String? driverName;
  final double? driverRating;
  final int? driverId;
  final String? driverPhone;
  final String? fromAddress;
  final String? toAddress;
  final bool allowsDelivery;
  final bool isPassengerEntry;
  final String? status;
  final Map<String, dynamic>? vehicle;
  final List<dynamic>? driverPreferences;
  final List<dynamic>? bookings;
  final List<int>? reservedSeats;
  final Map<String, dynamic>? rowPrices;
  final int totalSeats;

  Ride({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.date,
    required this.time,
    required this.price,
    required this.seats,
    this.bookedSeats,
    this.driverName,
    this.driverRating,
    this.driverId,
    this.driverPhone,
    this.fromAddress,
    this.toAddress,
    required this.allowsDelivery,
    required this.isPassengerEntry,
    this.status,
    this.vehicle,
    this.driverPreferences,
    this.bookings,
    this.reservedSeats,
    this.rowPrices,
    required this.totalSeats,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      fromCity: json['from_city'],
      toCity: json['to_city'],
      date: json['date'],
      time: json['time'] ?? '00:00',
      price: (json['price'] as num).toDouble(),
      seats: json['seats'],
      bookedSeats: json['booked_seats'] ?? (json['bookings'] as List?)?.length,
      driverName: json['driver_name'],
      driverRating: (json['driver_rating'] as num?)?.toDouble() ?? 5.0,
      driverId: json['driver_id'],
      driverPhone: json['driver_phone'],
      fromAddress: json['from_address'],
      toAddress: json['to_address'],
      allowsDelivery: json['allows_delivery'] == 1 || json['allows_delivery'] == true,
      isPassengerEntry: json['is_passenger_entry'] == 1 || json['is_passenger_entry'] == true,
      status: json['status'],
      vehicle: json['vehicle'],
      driverPreferences: json['driver_preferences'] as List?,
      bookings: json['bookings'] as List?,
      reservedSeats: (json['reserved_seats'] as List?)?.map((e) => e as int).toList(),
      rowPrices: json['row_prices'] as Map<String, dynamic>?,
      totalSeats: json['total_seats'] ?? 5,
    );
  }
}
