import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Создание нового бронирования
  Future<BookingModel> createBooking({
    required String houseId,
    required String ownerId,
    required DateTime checkIn,
    required DateTime checkOut,
    required double totalPrice,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final bookingRef = _firestore.collection('bookings').doc();
    final booking = BookingModel(
      id: bookingRef.id,
      houseId: houseId,
      userId: user.uid,
      ownerId: ownerId,
      checkIn: checkIn,
      checkOut: checkOut,
      totalPrice: totalPrice,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await bookingRef.set(booking.toJson());
    return booking;
  }

  // Получение всех бронирований пользователя
  Stream<List<BookingModel>> getUserBookings() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data()))
            .toList());
  }

  // Получение всех бронирований для владельца
  Stream<List<BookingModel>> getOwnerBookings() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    return _firestore
        .collection('bookings')
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data()))
            .toList());
  }

  // Обновление статуса бронирования
  Future<void> updateBookingStatus(String bookingId, String status, {String? rejectionReason}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final bookingDoc = await bookingRef.get();
    
    if (!bookingDoc.exists) {
      throw Exception('Бронирование не найдено');
    }

    final booking = BookingModel.fromMap(bookingDoc.data()!);
    if (booking.ownerId != user.uid) {
      throw Exception('Нет прав для изменения статуса бронирования');
    }

    await bookingRef.update({
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    });
  }

  // Отмена бронирования
  Future<void> cancelBooking(String bookingId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final bookingDoc = await bookingRef.get();
    
    if (!bookingDoc.exists) {
      throw Exception('Бронирование не найдено');
    }

    final booking = BookingModel.fromMap(bookingDoc.data()!);
    if (booking.userId != user.uid && booking.ownerId != user.uid) {
      throw Exception('Нет прав для отмены бронирования');
    }

    await bookingRef.update({
      'status': 'cancelled',
    });
  }

  // Проверка доступности дат для бронирования
  Future<bool> isDateRangeAvailable(String houseId, DateTime checkIn, DateTime checkOut) async {
    final bookings = await _firestore
        .collection('bookings')
        .where('houseId', isEqualTo: houseId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();

    for (var doc in bookings.docs) {
      final booking = BookingModel.fromMap(doc.data());
      if ((checkIn.isBefore(booking.checkOut) && checkOut.isAfter(booking.checkIn))) {
        return false;
      }
    }
    return true;
  }

  // НОВЫЙ МЕТОД: Получение всех бронирований (для админа)
  Stream<List<BookingModel>> getAllBookingsStream() {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data()))
            .toList());
  }

  // НОВЫЙ МЕТОД: Получение бронирований по ID владельца (для аналитики арендодателя)
  Stream<List<BookingModel>> getBookingsByOwnerIdStream(String ownerId) {
    return _firestore
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data()))
            .toList());
  }
} 