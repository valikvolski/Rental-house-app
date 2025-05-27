import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Получить данные пользователя
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Получить информацию о пользователе в виде Map
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      rethrow;
    }
  }

  // Создать или обновить данные пользователя
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // Обновить отдельные поля пользователя
  Future<void> updateUserFields(String userId, Map<String, dynamic> fields) async {
    try {
      await _firestore.collection(_collection).doc(userId).update(fields);
    } catch (e) {
      rethrow;
    }
  }
} 