import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final _storage = FirebaseStorage.instance;

  // Upload a single image and return its download URL
  Future<String> uploadImage(File imageFile, String listingId) async {
    try {
      if (!await imageFile.exists()) {
        throw 'Файл не существует: ${imageFile.path}';
      }

      print('DEBUG: Начало загрузки изображения: ${imageFile.path}');
      
      // Создаем уникальное имя файла
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final ref = _storage.ref().child('listings/$listingId/$fileName');

      // Загружаем файл с метаданными
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'picked-file-path': imageFile.path},
        ),
      );
      
      // Отслеживаем прогресс
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('DEBUG: Прогресс загрузки: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      });

      // Ждем завершения загрузки
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('DEBUG: Изображение успешно загружено: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('ERROR: Ошибка при загрузке изображения: $e');
      rethrow;
    }
  }

  // Upload multiple images and return their download URLs
  Future<List<String>> uploadImages(List<File> images, String listingId) async {
    try {
      print('DEBUG: Начало загрузки ${images.length} изображений');
      final urls = <String>[];
      
      for (var image in images) {
        try {
          final url = await uploadImage(image, listingId);
          urls.add(url);
        } catch (e) {
          print('ERROR: Ошибка при загрузке изображения ${image.path}: $e');
          // Продолжаем с следующим изображением
        }
      }
      
      print('DEBUG: Успешно загружено ${urls.length} изображений');
      return urls;
    } catch (e) {
      print('ERROR: Ошибка при загрузке изображений: $e');
      rethrow;
    }
  }

  // Delete an image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (!imageUrl.startsWith('http') && !imageUrl.startsWith('gs://')) {
        print('WARNING: Пропуск удаления локального файла: $imageUrl');
        return;
      }

      print('DEBUG: Удаление изображения: $imageUrl');
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('DEBUG: Изображение успешно удалено');
    } catch (e) {
      print('ERROR: Ошибка при удалении изображения: $e');
      rethrow;
    }
  }

  // Delete multiple images from storage
  Future<void> deleteImages(List<String> imageUrls) async {
    try {
      print('DEBUG: Удаление ${imageUrls.length} изображений');
      for (var url in imageUrls) {
        try {
          await deleteImage(url);
        } catch (e) {
          print('ERROR: Ошибка при удалении изображения $url: $e');
          // Продолжаем с следующим изображением
        }
      }
      print('DEBUG: Удаление изображений завершено');
    } catch (e) {
      print('ERROR: Ошибка при удалении изображений: $e');
      rethrow;
    }
  }
} 