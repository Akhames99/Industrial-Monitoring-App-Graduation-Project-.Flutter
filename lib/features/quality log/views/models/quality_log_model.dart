import 'package:flutter/material.dart';
import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/api_response_models.dart';
import 'package:app/features/quality%20log/repositories/quality_log_repository.dart';

// Enums
enum QualityItemStatus { pending, reviewed }

enum QualityItemType { broken, skratch, label, good }

class QualityItem {
  final String id;
  final String title;
  final QualityItemType type;
  final QualityItemStatus status;
  final double confidenceScore; // 0-100
  final String? imageUrl;
  final DateTime createdAt;
  final String? actionTaken; // e.g., "Defection Confirmed", "Label updated"
  final String? actionType; // e.g., "confirmed", "updated", "relabeled"
  final bool isConfirmed;

  QualityItem({
    required this.id,
    required this.title,
    required this.type,
    this.status = QualityItemStatus.pending,
    required this.confidenceScore,
    this.imageUrl,
    required this.createdAt,
    this.actionTaken,
    this.actionType,
    this.isConfirmed = false,
  });

  // Copy constructor
  QualityItem copyWith({
    String? id,
    String? title,
    QualityItemType? type,
    QualityItemStatus? status,
    double? confidenceScore,
    String? imageUrl,
    DateTime? createdAt,
    String? actionTaken,
    String? actionType,
    bool? isConfirmed,
  }) {
    return QualityItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      actionTaken: actionTaken ?? this.actionTaken,
      actionType: actionType ?? this.actionType,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  // Convert from JSON
  factory QualityItem.fromJson(Map<String, dynamic> json) {
    return QualityItem(
      id: json['id'] ?? json['user_id']?.toString() ?? '',
      title: json['title'] ?? '',
      type: _parseType(json['type']),
      status: _parseStatus(
        json['status'],
        json['isConfirmed'] ?? json['is_confirmed'] ?? false,
      ),
      confidenceScore:
          (json['confidenceScore'] ?? json['confidence_score'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? json['image_url'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? json['created_at'] ?? DateTime.now().toString(),
      ),
      actionTaken: json['actionTaken'] ?? json['action_taken'],
      actionType: json['actionType'],
      isConfirmed: json['isConfirmed'] ?? json['is_confirmed'] ?? false,
    );
  }

  // Convert from Response Model
  factory QualityItem.fromResponse(QualityItemResponse response) {
    return QualityItem(
      id: response.id,
      title: response.title,
      type: _parseType(response.type),
      status: _parseStatus(response.status, response.isConfirmed),
      confidenceScore: response.confidenceScore,
      imageUrl: response.imageUrl,
      createdAt: response.createdAt,
      actionTaken: response.actionTaken,
      isConfirmed: response.isConfirmed,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString(),
      'status': status.toString(),
      'confidenceScore': confidenceScore,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'actionTaken': actionTaken,
      'actionType': actionType,
      'is_confirmed': isConfirmed,
    };
  }

  static QualityItemType _parseType(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'broken':
          return QualityItemType.broken;
        case 'skratch':
          return QualityItemType.skratch;
        case 'label':
          return QualityItemType.label;
        case 'good':
          return QualityItemType.good;
        default:
          return QualityItemType.broken;
      }
    }
    return QualityItemType.broken;
  }

  static QualityItemStatus _parseStatus(
    dynamic value, [
    bool isConfirmed = false,
  ]) {
    if (isConfirmed) return QualityItemStatus.reviewed;
    if (value is String) {
      final val = value.toLowerCase();
      if (val == 'reviewed' || val == 'defected' || val == 'good') {
        return QualityItemStatus.reviewed;
      }
    }
    return QualityItemStatus.pending;
  }
}

class QualityLogContainer {
  final List<QualityItem> items;
  final DateTime lastUpdated;
  final int currentPage;
  final int itemsPerPage;

  QualityLogContainer({
    required this.items,
    required this.lastUpdated,
    this.currentPage = 1,
    this.itemsPerPage = 4,
  });

  int get totalItems => items.length;
  int get totalPages => (items.length / itemsPerPage).ceil();

  List<QualityItem> get pendingItems =>
      items.where((i) => i.status == QualityItemStatus.pending).toList();
  List<QualityItem> get reviewedItems =>
      items.where((i) => i.status == QualityItemStatus.reviewed).toList();

  List<QualityItem> getItemsForPage(int page) {
    final start = (page - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    return items.sublist(start, end > items.length ? items.length : end);
  }

  QualityLogContainer copyWith({
    List<QualityItem>? items,
    DateTime? lastUpdated,
    int? currentPage,
    int? itemsPerPage,
  }) {
    return QualityLogContainer(
      items: items ?? this.items,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }
}

// Service class
class QualityLogService {
  final QualityLogRepository _repository = QualityLogRepository();

  // Fetch quality log items
  Future<QualityLogContainer> fetchQualityLog({
    QualityItemStatus? filterByStatus,
    int page = 1,
  }) async {
    try {
      final response = await _repository.getQualityItems(
        page: page,
        status: filterByStatus?.name,
      );

      final items = response.items.map((item) {
        var qualityItem = QualityItem.fromResponse(item);
        if (qualityItem.imageUrl != null &&
            !qualityItem.imageUrl!.startsWith('http')) {
          qualityItem = qualityItem.copyWith(
            imageUrl: '${ApiConfig.baseUrl}/${qualityItem.imageUrl}'.replaceAll(
              '\\',
              '/',
            ),
          );
        }
        return qualityItem;
      }).toList();

      return QualityLogContainer(items: items, lastUpdated: DateTime.now());
    } catch (e) {
      debugPrint('Error fetching quality log: $e');
      throw Exception('Failed to fetch quality log: $e');
    }
  }

  // Update quality item status
  Future<bool> updateItemStatus(String itemId, QualityItemStatus status) async {
    try {
      // Depending on the API, this might be a generic update or specific ones
      if (status == QualityItemStatus.reviewed) {
        await _repository.confirmDefection(itemId);
      }
      return true;
    } catch (e) {
      debugPrint('Error updating item status: $e');
      return false;
    }
  }

  // Dismiss/delete item
  Future<bool> dismissItem(String itemId) async {
    try {
      return await _repository.dismissItem(itemId);
    } catch (e) {
      debugPrint('Error dismissing item: $e');
      return false;
    }
  }

  // Confirm defection
  Future<bool> confirmDefection(String itemId) async {
    try {
      await _repository.confirmDefection(itemId);
      return true;
    } catch (e) {
      debugPrint('Error confirming defection: $e');
      return false;
    }
  }

  // Send to dataset
  Future<bool> sendToDataset(String itemId) async {
    try {
      return await _repository.sendToDataset(itemId);
    } catch (e) {
      debugPrint('Error sending to dataset: $e');
      return false;
    }
  }

  // Relabel item
  Future<bool> relabelItem(String itemId, String newLabel) async {
    try {
      await _repository.relabelItem(itemId, newLabel);
      return true;
    } catch (e) {
      debugPrint('Error relabeling item: $e');
      return false;
    }
  }

  // Confirm inspection (sets is_confirmed to true)
  Future<bool> confirmInspection(String inspectionId) async {
    try {
      return await _repository.confirmInspection(inspectionId);
    } catch (e) {
      debugPrint('Error confirming inspection: $e');
      return false;
    }
  }

  // Edit inspection (status and defect category)
  Future<bool> editInspection(
    String inspectionId, {
    required String status,
    required String defectCategory,
  }) async {
    try {
      return await _repository.editInspection(
        inspectionId,
        status: status,
        defectCategory: defectCategory,
      );
    } catch (e) {
      debugPrint('Error editing inspection: $e');
      return false;
    }
  }

  static List<QualityItem> generateMockData() {
    return [
      QualityItem(
        id: '1',
        title: 'Broken',
        type: QualityItemType.broken,
        status: QualityItemStatus.reviewed,
        confidenceScore: 30,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        actionTaken: 'Defection Confirmed',
        actionType: 'confirmed',
      ),
      QualityItem(
        id: '2',
        title: 'Skratch',
        type: QualityItemType.skratch,
        status: QualityItemStatus.pending,
        confidenceScore: 85,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      QualityItem(
        id: '3',
        title: 'Label',
        type: QualityItemType.label,
        status: QualityItemStatus.reviewed,
        confidenceScore: 70,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        actionTaken: 'Label updated',
        actionType: 'updated',
      ),
      QualityItem(
        id: '4',
        title: 'Broken',
        type: QualityItemType.broken,
        status: QualityItemStatus.pending,
        confidenceScore: 95,
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      QualityItem(
        id: '5',
        title: 'Broken',
        type: QualityItemType.broken,
        status: QualityItemStatus.pending,
        confidenceScore: 60,
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      QualityItem(
        id: '6',
        title: 'Skratch',
        type: QualityItemType.skratch,
        status: QualityItemStatus.reviewed,
        confidenceScore: 45,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        actionTaken: 'Relabeled',
        actionType: 'relabeled',
      ),
      QualityItem(
        id: '7',
        title: 'Skratch',
        type: QualityItemType.skratch,
        status: QualityItemStatus.pending,
        confidenceScore: 75,
        createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
      ),
      QualityItem(
        id: '8',
        title: 'Broken',
        type: QualityItemType.broken,
        status: QualityItemStatus.pending,
        confidenceScore: 88,
        createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
      ),
      QualityItem(
        id: '9',
        title: 'Label',
        type: QualityItemType.label,
        status: QualityItemStatus.reviewed,
        confidenceScore: 92,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      QualityItem(
        id: '10',
        title: 'Skratch',
        type: QualityItemType.skratch,
        status: QualityItemStatus.pending,
        confidenceScore: 65,
        createdAt: DateTime.now().subtract(const Duration(minutes: 50)),
      ),
      QualityItem(
        id: '11',
        title: 'Broken',
        type: QualityItemType.broken,
        status: QualityItemStatus.reviewed,
        confidenceScore: 78,
        createdAt: DateTime.now().subtract(const Duration(minutes: 55)),
      ),
      QualityItem(
        id: '12',
        title: 'Broken',
        type: QualityItemType.broken,
        status: QualityItemStatus.pending,
        confidenceScore: 82,
        createdAt: DateTime.now().subtract(const Duration(minutes: 60)),
      ),
    ];
  }
}

// Helper extensions
extension QualityItemTypeExtension on QualityItemType {
  String get displayName {
    switch (this) {
      case QualityItemType.broken:
        return 'Broken';
      case QualityItemType.skratch:
        return 'Skratch';
      case QualityItemType.label:
        return 'Label';
      case QualityItemType.good:
        return 'Good';
    }
  }

  Color get color {
    switch (this) {
      case QualityItemType.broken:
        return const Color(0xFF1A1A2E); // Dark
      case QualityItemType.skratch:
        return const Color(0xFF9B59B6); // Purple
      case QualityItemType.label:
        return const Color(0xFFE67E22); // Orange
      case QualityItemType.good:
        return Colors.green; // Green for Good
    }
  }
}

extension QualityItemStatusExtension on QualityItemStatus {
  String get displayName {
    switch (this) {
      case QualityItemStatus.pending:
        return 'Pending';
      case QualityItemStatus.reviewed:
        return 'Reviewed';
    }
  }

  Color get badgeColor {
    switch (this) {
      case QualityItemStatus.pending:
        return const Color(0xFFFEF5E7); // Yellow/Orange
      case QualityItemStatus.reviewed:
        return const Color(0xFFE8E8E8); // Gray
    }
  }

  Color get badgeTextColor {
    switch (this) {
      case QualityItemStatus.pending:
        return Color(0xffF59E0B);
      case QualityItemStatus.reviewed:
        return const Color(0xFF666666);
    }
  }
}
