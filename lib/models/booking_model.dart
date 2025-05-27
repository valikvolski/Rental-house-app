import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String houseId;
  final String userId;
  final String ownerId;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalPrice;
  final String status; // pending, confirmed, cancelled, completed
  final DateTime createdAt;
  final String? rejectionReason;

  BookingModel({
    required this.id,
    required this.houseId,
    required this.userId,
    required this.ownerId,
    required this.checkIn,
    required this.checkOut,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'houseId': houseId,
      'userId': userId,
      'ownerId': ownerId,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }
    return BookingModel(
      id: map['id'] ?? '',
      houseId: map['houseId'] ?? '',
      userId: map['userId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      checkIn: parseDate(map['checkIn']),
      checkOut: parseDate(map['checkOut']),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: parseDate(map['createdAt']),
      rejectionReason: map['rejectionReason'],
    );
  }

  BookingModel copyWith({
    String? id,
    String? houseId,
    String? userId,
    String? ownerId,
    DateTime? checkIn,
    DateTime? checkOut,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
    String? rejectionReason,
  }) {
    return BookingModel(
      id: id ?? this.id,
      houseId: houseId ?? this.houseId,
      userId: userId ?? this.userId,
      ownerId: ownerId ?? this.ownerId,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
} 