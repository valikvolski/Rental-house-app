import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reports';

  // Создать новую жалобу
  Future<void> createReport(ReportModel report) async {
    final docRef = _firestore.collection(_collection).doc();
    final reportWithId = report.copyWith(id: docRef.id);
    await docRef.set(reportWithId.toMap());
  }

  // Получить все жалобы (для админа)
  Stream<List<ReportModel>> getAllReports() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromMap(doc.data()))
            .toList());
  }

  // Получить активные жалобы (для админа)
  Stream<List<ReportModel>> getActiveReports() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromMap(doc.data()))
            .toList());
  }

  // Получить жалобы на конкретного пользователя
  Stream<List<ReportModel>> getReportsForUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('reportedUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromMap(doc.data()))
            .toList());
  }

  // Обновить статус жалобы
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    required String adminId,
    String? resolutionNote,
  }) async {
    final updates = {
      'status': status,
      'resolvedAt': DateTime.now().toIso8601String(),
      'resolvedBy': adminId,
      if (resolutionNote != null) 'resolutionNote': resolutionNote,
    };

    await _firestore.collection(_collection).doc(reportId).update(updates);
  }

  // Получить жалобу по ID
  Future<ReportModel?> getReportById(String reportId) async {
    final doc = await _firestore.collection(_collection).doc(reportId).get();
    if (!doc.exists) return null;
    return ReportModel.fromMap(doc.data()!);
  }

  // Проверить, есть ли уже активная жалоба от пользователя на это объявление
  Future<bool> hasActiveReport({
    required String reporterId,
    required String listingId,
  }) async {
    final query = await _firestore
        .collection(_collection)
        .where('reporterId', isEqualTo: reporterId)
        .where('listingId', isEqualTo: listingId)
        .where('status', isEqualTo: 'active')
        .get();
    
    return query.docs.isNotEmpty;
  }
} 