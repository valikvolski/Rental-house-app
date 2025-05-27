class HouseModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String location;
  final double price;
  final int bedrooms;
  final int bathrooms;
  final int area;
  final List<String> images;
  final String status;
  final DateTime createdAt;
  final String? rejectionReason;

  HouseModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.images,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'location': location,
      'price': price,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'images': images,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  factory HouseModel.fromMap(Map<String, dynamic> map) {
    return HouseModel(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      bedrooms: map['bedrooms'] ?? 0,
      bathrooms: map['bathrooms'] ?? 0,
      area: map['area'] ?? 0,
      images: List<String>.from(map['images'] ?? []),
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      rejectionReason: map['rejectionReason'],
    );
  }

  HouseModel copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    String? location,
    double? price,
    int? bedrooms,
    int? bathrooms,
    int? area,
    List<String>? images,
    String? status,
    DateTime? createdAt,
    String? rejectionReason,
  }) {
    return HouseModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      price: price ?? this.price,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      images: images ?? this.images,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
} 