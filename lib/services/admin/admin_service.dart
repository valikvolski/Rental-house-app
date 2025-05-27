import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/house_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _collection = 'listings';

  // Получение списка пользователей
  Stream<List<UserModel>> getUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  // Получение списка объявлений на модерацию
  Stream<List<HouseModel>> getPendingHouses() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return HouseModel.fromMap(data);
            }).toList());
  }

  // Получение всех объявлений
  Stream<List<HouseModel>> getAllHouses() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return HouseModel.fromMap(data);
            }).toList());
  }

  // Одобрение объявления
  Future<void> approveHouse(String houseId) async {
    await _firestore
        .collection(_collection)
        .doc(houseId)
        .update({
          'status': 'active',
          'moderatedAt': FieldValue.serverTimestamp(),
        });
  }

  // Отклонение объявления
  Future<void> rejectHouse(String houseId, String reason) async {
    await _firestore.collection(_collection).doc(houseId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Редактирование объявления
  Future<void> updateHouse(HouseModel house) async {
    await _firestore
        .collection(_collection)
        .doc(house.id)
        .update({
          ...house.toJson(),
          'moderatedAt': FieldValue.serverTimestamp(),
        });
  }

  // Изменение роли пользователя
  Future<void> updateUserRole(String userId, String newRole) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'role': newRole});
  }

  // Получение статистики
  Future<Map<String, dynamic>> getStatistics() async {
    final usersCount = await _firestore.collection('users').count().get();
    final listingsCount = await _firestore.collection(_collection).count().get();
    final pendingCount = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    final activeCount = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .count()
        .get();

    return {
      'usersCount': usersCount.count,
      'listingsCount': listingsCount.count,
      'pendingCount': pendingCount.count,
      'activeCount': activeCount.count,
    };
  }
} 