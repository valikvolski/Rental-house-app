class UserModel {
  final String uid;
  final String email;
  final String role; // 'user', 'admin', 'landlord'
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'role': role,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'phoneNumber': phoneNumber,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'],
    email: map['email'],
    role: map['role'] ?? 'user',
    displayName: map['displayName'],
    photoUrl: map['photoUrl'],
    phoneNumber: map['phoneNumber'],
    createdAt: DateTime.parse(map['createdAt']),
  );

  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, role: $role, displayName: $displayName, photoUrl: $photoUrl, phoneNumber: $phoneNumber, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.role == role &&
        other.displayName == displayName &&
        other.phoneNumber == phoneNumber &&
        other.photoUrl == photoUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        role.hashCode ^
        displayName.hashCode ^
        phoneNumber.hashCode ^
        photoUrl.hashCode ^
        createdAt.hashCode;
  }
} 