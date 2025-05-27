import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/favorite_model.dart';
import '../models/house_model.dart';

class FavoriteService {
  final _firestore = FirebaseFirestore.instance;
  final _favoritesCollection = 'favorites';
  final _listingsCollection = 'listings';

  // Получить избранные объявления текущего пользователя
  Stream<List<HouseModel>> getUserFavorites() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection(_favoritesCollection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .asyncMap((favSnap) async {
          final houseIds = favSnap.docs.map((doc) => doc['houseId'] as String).toList();
          if (houseIds.isEmpty) return <HouseModel>[];
          final housesSnap = await _firestore
              .collection(_listingsCollection)
              .where(FieldPath.documentId, whereIn: houseIds)
              .get();
          return housesSnap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return HouseModel.fromMap(data);
          }).toList();
        });
  }

  // Проверить, добавлено ли объявление в избранное
  Future<bool> isFavorite(String houseId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final snap = await _firestore
        .collection(_favoritesCollection)
        .where('userId', isEqualTo: uid)
        .where('houseId', isEqualTo: houseId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // Добавить в избранное
  Future<void> addFavorite(String houseId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Пользователь не авторизован');
    final docRef = _firestore.collection(_favoritesCollection).doc();
    await docRef.set({
      'id': docRef.id,
      'userId': uid,
      'houseId': houseId,
      'createdAt': DateTime.now().toIso8601String(),
    });
    // Обновить счетчик
    await _updateFavoritesCount(houseId, 1);
  }

  // Удалить из избранного
  Future<void> removeFavorite(String houseId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Пользователь не авторизован');
    final snap = await _firestore
        .collection(_favoritesCollection)
        .where('userId', isEqualTo: uid)
        .where('houseId', isEqualTo: houseId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      await _firestore.collection(_favoritesCollection).doc(snap.docs.first.id).delete();
      // Обновить счетчик
      await _updateFavoritesCount(houseId, -1);
    }
  }

  // Обновить счетчик избранного в объявлении
  Future<void> _updateFavoritesCount(String houseId, int delta) async {
    final docRef = _firestore.collection(_listingsCollection).doc(houseId);
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(docRef);
      final current = (doc.data()?['favoritesCount'] ?? 0) as int;
      tx.update(docRef, {'favoritesCount': current + delta});
    });
  }
} 