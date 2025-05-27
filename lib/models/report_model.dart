import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterId;      // ID пользователя, который отправил жалобу
  final String reportedUserId;  // ID пользователя, на которого пожаловались
  final String listingId;       // ID объявления, по поводу которого жалоба
  final String reason;          // Причина жалобы
  final String? details;        // Дополнительные детали (опционально)
  final String status;          // Статус жалобы: 'active', 'resolved', 'rejected'
  final DateTime createdAt;     // Дата создания жалобы
  final DateTime? resolvedAt;   // Дата решения жалобы (опционально)
  final String? resolvedBy;     // ID админа, который решил жалобу (опционально)
  final String? resolutionNote; // Комментарий админа при решении (опционально)

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.listingId,
    required this.reason,
    this.details,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'listingId': listingId,
      'reason': reason,
      'details': details,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolvedBy': resolvedBy,
      'resolutionNote': resolutionNote,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      listingId: map['listingId'] ?? '',
      reason: map['reason'] ?? '',
      details: map['details'],
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      resolvedAt: map['resolvedAt'] != null 
          ? DateTime.parse(map['resolvedAt']) 
          : null,
      resolvedBy: map['resolvedBy'],
      resolutionNote: map['resolutionNote'],
    );
  }

  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? listingId,
    String? reason,
    String? details,
    String? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? resolutionNote,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      listingId: listingId ?? this.listingId,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolutionNote: resolutionNote ?? this.resolutionNote,
    );
  }
} 