class FavoriteModel {
  final String id;
  final String userId;
  final String houseId;
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.houseId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'houseId': houseId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FavoriteModel.fromMap(Map<String, dynamic> map) => FavoriteModel(
    id: map['id'],
    userId: map['userId'],
    houseId: map['houseId'],
    createdAt: DateTime.parse(map['createdAt']),
  );
} 