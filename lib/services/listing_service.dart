import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/house_model.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart';

class ListingService {
  final _firestore = FirebaseFirestore.instance;
  final _collection = 'listings';
  final _storageService = StorageService();
  final _auth = FirebaseAuth.instance;

  // Получить все объявления с фильтрацией, поиском и сортировкой
  Stream<List<HouseModel>> getAllListings({
    String? city,
    String? searchQuery,
    String? sortBy,
  }) {
    print('DEBUG: Запрос объявлений с фильтрами: city=$city, search=$searchQuery, sort=$sortBy');
    var query = _firestore.collection(_collection)
      .where('status', isEqualTo: 'active');
    
    if (city != null) {
      query = query.where('location', isEqualTo: city);
    }

    // Применяем сортировку
    if (sortBy != null) {
      switch (sortBy) {
        case 'price_asc':
          query = query.orderBy('price', descending: false);
          break;
        case 'price_desc':
          query = query.orderBy('price', descending: true);
          break;
        case 'newest':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'popular':
          query = query.orderBy('favoritesCount', descending: true);
          break;
      }
    }

    return query.snapshots()
      .map((snap) {
        print('DEBUG: Получено ${snap.docs.length} объявлений');
        var listings = snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return HouseModel.fromMap(data);
        }).toList();

        // Применяем поиск на клиенте (можно перенести на сервер с помощью Firestore Full Text Search)
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          listings = listings.where((house) {
            return house.title.toLowerCase().contains(query) ||
                   house.description.toLowerCase().contains(query) ||
                   house.location.toLowerCase().contains(query);
          }).toList();
        }

        return listings;
      });
  }

  // Получить только свои объявления (все статусы)
  Stream<List<HouseModel>> getMyListings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print('ERROR: Пользователь не авторизован');
      return const Stream.empty();
    }

    print('DEBUG: Получение объявлений пользователя: $uid');
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          print('DEBUG: Получено ${snap.docs.length} объявлений');
          return snap.docs.map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              print('DEBUG: Объявление: ${data['title']} (${data['status']})');
              return HouseModel.fromMap(data);
            } catch (e) {
              print('ERROR: Ошибка при преобразовании документа: $e');
              rethrow;
            }
          }).toList();
        });
  }

  // Создать объявление
  Future<HouseModel> createListing(HouseModel house, List<File> images) async {
    try {
      print('DEBUG: Начало создания объявления');
      print('DEBUG: Создание модели дома: ${house.toJson()}');
      print('DEBUG: Количество изображений для загрузки: ${images.length}');

      // Загружаем изображения
      print('DEBUG: Начало загрузки изображений');
      final imageUrls = await _storageService.uploadImages(images, house.id);
      print('DEBUG: Изображения загружены: ${imageUrls.length}');

      // Обновляем модель с URL изображений и устанавливаем статус
      final updatedHouse = house.copyWith(
        images: imageUrls,
        status: house.status, // Оставляем исходный статус
      );

      // Сохраняем в Firestore
      print('DEBUG: Сохранение объявления в Firestore');
      await _firestore
          .collection(_collection)
          .doc(house.id)
          .set(updatedHouse.toJson());
      print('DEBUG: Объявление успешно сохранено в Firestore');

      return updatedHouse;
    } catch (e) {
      print('ERROR: Ошибка при создании объявления: $e');
      // Если произошла ошибка, пытаемся удалить загруженные изображения
      try {
        if (house.images.isNotEmpty) {
          print('DEBUG: Попытка удаления загруженных изображений');
          await _storageService.deleteImages(house.images);
        }
      } catch (deleteError) {
        print('ERROR: Ошибка при удалении изображений: $deleteError');
      }
      rethrow;
    }
  }

  // Обновить объявление (только если владелец)
  Future<void> updateListing(HouseModel updatedHouse, List<File> newImages) async {
    print('DEBUG: Начало обновления объявления');
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    // Проверяем существование объявления
    final doc = await _firestore.collection('listings').doc(updatedHouse.id).get();
    if (!doc.exists) {
      throw Exception('Объявление не найдено');
    }

    // Проверяем, является ли пользователь владельцем
    final data = doc.data();
    if (data == null || data['ownerId'] != user.uid) {
      throw Exception('Нет прав на редактирование этого объявления');
    }

    print('DEBUG: Обновление модели дома: ${updatedHouse.toJson()}');
    print('DEBUG: Количество новых изображений: ${newImages.length}');

    List<String> imageUrls = List<String>.from(updatedHouse.images);

    // Загружаем новые изображения
    if (newImages.isNotEmpty) {
      print('DEBUG: Начало загрузки ${newImages.length} изображений');
      for (final image in newImages) {
        final url = await _storageService.uploadImage(image, updatedHouse.id);
        imageUrls.add(url);
      }
      print('DEBUG: Успешно загружено ${newImages.length} изображений');
    }

    // Обновляем документ с новыми данными
    await _firestore.collection('listings').doc(updatedHouse.id).update({
      ...updatedHouse.toJson(),
      'images': imageUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('DEBUG: Объявление успешно обновлено');
  }

  // Удалить объявление
  Future<void> deleteListing(String listingId) async {
    try {
      print('DEBUG: Начало удаления объявления: $listingId');
      
      // Проверяем права доступа
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Пользователь не авторизован';
      }

      // Получаем объявление перед удалением
      final doc = await _firestore.collection(_collection).doc(listingId).get();
      if (!doc.exists) {
        throw 'Объявление не найдено';
      }

      final house = HouseModel.fromMap(doc.data()!);
      
      // Проверяем владельца
      if (house.ownerId != user.uid) {
        throw 'Нет прав на удаление';
      }

      // Удаляем изображения
      if (house.images.isNotEmpty) {
        print('DEBUG: Удаление ${house.images.length} изображений');
        try {
          await _storageService.deleteImages(house.images);
        } catch (e) {
          print('ERROR: Ошибка при удалении изображений: $e');
          // Продолжаем удаление объявления даже если не удалось удалить изображения
        }
      }

      // Удаляем документ
      await _firestore.collection(_collection).doc(listingId).delete();
      print('DEBUG: Объявление успешно удалено');
    } catch (e) {
      print('ERROR: Ошибка при удалении объявления: $e');
      rethrow;
    }
  }

  // Получить популярные объявления с фильтрацией по городу
  Stream<List<HouseModel>> getPopularListings({String? city}) {
    return getAllListings(
      city: city,
      sortBy: 'popular',
    ).map((listings) => listings.take(10).toList());
  }

  Future<HouseModel?> getListing(String id) async {
    try {
      final doc = await _firestore.collection('listings').doc(id).get();
      if (doc.exists) {
        return HouseModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка при получении объявления: $e');
      return null;
    }
  }
} 