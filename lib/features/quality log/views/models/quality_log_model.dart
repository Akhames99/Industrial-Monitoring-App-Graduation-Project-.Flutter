import 'package:flutter/material.dart';
import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/api_response_models.dart';
import 'package:app/features/quality%20log/repositories/quality_log_repository.dart';

// ─────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────

enum QualityItemStatus { pending, reviewed }

/// Sub-buckets within the "reviewed" status, mirroring the three review
/// outcomes stored in the database.
enum QualityReviewCategory { good, defected, invalid }

enum QualityItemType {
  perfectBottle,
  noCap,
  crookedCap,
  emptyBottle,
  noLabel,
  invalid,
}

// ─────────────────────────────────────────────
// QualityItem model
// ─────────────────────────────────────────────

class QualityItem {
  final String id;
  final String title;
  final QualityItemType type;
  final QualityItemStatus status;
  final double confidenceScore;
  final String? imageUrl;
  final DateTime createdAt;
  final String? actionTaken;
  final String? actionType;
  final bool isConfirmed;
  final String? defectCategory;
  final String? rawStatus;
  final bool isUploading; // ← add

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
    this.defectCategory,
    this.rawStatus,
    this.isUploading = false, // ← add
  });

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
    String? defectCategory,
    String? rawStatus,
    bool? isUploading, // ← add
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
      defectCategory: defectCategory ?? this.defectCategory,
      rawStatus: rawStatus ?? this.rawStatus,
      isUploading: isUploading ?? this.isUploading, // ← add
    );
  }

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
      defectCategory: response.defectCategory,
      rawStatus: response.status,
      isUploading: response.isUploading, // ← add
    );
  }

  factory QualityItem.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'pending';
    final isConfirmed = json['is_confirmed'] as bool? ?? false;
    final statusLower = status.toLowerCase();

    // Only guess a defect type when the item is actually in the "defected"
    // bucket. "good" has no defect, and "invalid" means the inspection was
    // thrown out — neither should be labeled with an invented defect type.
    final String type;
    if (statusLower == 'good') {
      type = 'good';
    } else if (statusLower == 'invalid') {
      type = 'invalid';
    } else {
      type = json['defect_type'] ?? json['type'] ?? 'broken';
    }

    final rawImageUrl =
        json['cv_image_url'] ??
        json['image_url'] ??
        json['image_path'] ??
        json['imageUrl'] ??
        json['cvImageUrl'] ??
        json['cloudinary_url'] ??
        json['cloudinaryUrl'] ??
        json['url'];
    final bool isUploading = rawImageUrl == 'uploading_in_background'; // ← add

    String? imageUrl = rawImageUrl;
    if (imageUrl == null || imageUrl.isEmpty || isUploading) {
      imageUrl = null;
    }

    return QualityItem(
      id: (json['inspection_id'] ?? json['id'])?.toString() ?? '',
      title: statusLower == 'good' ? 'Good' : (json['title'] ?? type),
      type: _parseType(type),
      status: _parseStatus(status, isConfirmed),
      confidenceScore: (json['confidence_score'] ?? json['confidence'] ?? 0)
          .toDouble(),
      imageUrl: imageUrl,
      createdAt:
          DateTime.tryParse(json['inspected_at'] ?? json['created_at'] ?? '') ??
          DateTime.now(),
      actionTaken: json['action_taken'],
      isConfirmed: isConfirmed,
      defectCategory: json['defect_type'] ?? json['defect_category'],
      rawStatus: status,
      isUploading: isUploading, // ← add
    );
  }

  Map<String, dynamic> toJson() => {
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

  static QualityItemType _parseType(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'perfect_bottle':
        case 'good':
          return QualityItemType.perfectBottle;
        case 'no_cap':
          return QualityItemType.noCap;
        case 'crooked_cap':
          return QualityItemType.crookedCap;
        case 'empty_bottle':
          return QualityItemType.emptyBottle;
        case 'no_label':
        case 'label':
          return QualityItemType.noLabel;
        case 'broken':
          return QualityItemType.crookedCap;
        case 'skratch':
        case 'scratch':
          return QualityItemType.crookedCap;
        case 'invalid':
          return QualityItemType.invalid; // ← new
      }
    }
    return QualityItemType.crookedCap;
  }

  /// An item is "reviewed" if it is confirmed OR its status is anything
  /// other than "pending" / "uploading_in_background".
  static QualityItemStatus _parseStatus(
    dynamic value, [
    bool isConfirmed = false,
  ]) {
    if (value is String) {
      final valLower = value.toLowerCase();
      if (valLower == 'pending' || valLower == 'uploading_in_background') {
        return QualityItemStatus.pending;
      }
      return QualityItemStatus.reviewed;
    }
    if (isConfirmed) return QualityItemStatus.reviewed;
    return QualityItemStatus.pending;
  }
}

// ─────────────────────────────────────────────
// QualityLogContainer
// ─────────────────────────────────────────────

class QualityLogContainer {
  final List<QualityItem> items;
  final DateTime lastUpdated;
  final int currentPage;
  final int itemsPerPage;
  final int pendingCount;
  final int reviewedCount;

  QualityLogContainer({
    required this.items,
    required this.lastUpdated,
    this.currentPage = 1,
    this.itemsPerPage = 4,
    this.pendingCount = 0,
    this.reviewedCount = 0,
  });

  int get totalItems => items.length;
  int get totalPages => (items.length / itemsPerPage).ceil();

  List<QualityItem> get pendingItems =>
      items.where((i) => i.status == QualityItemStatus.pending).toList();
  List<QualityItem> get reviewedItems =>
      items.where((i) => i.status == QualityItemStatus.reviewed).toList();

  /// Reviewed items bucketed into Good / Defected / Invalid.
  List<QualityItem> reviewedItemsByCategory(QualityReviewCategory category) =>
      reviewedItems.where((i) => i.reviewCategory == category).toList();

  List<QualityItem> getItemsForPage(int page) {
    final start = (page - 1) * itemsPerPage;
    final end = (start + itemsPerPage).clamp(0, items.length);
    return items.sublist(start, end);
  }

  QualityLogContainer copyWith({
    List<QualityItem>? items,
    DateTime? lastUpdated,
    int? currentPage,
    int? itemsPerPage,
    int? pendingCount,
    int? reviewedCount,
  }) {
    return QualityLogContainer(
      items: items ?? this.items,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      pendingCount: pendingCount ?? this.pendingCount,
      reviewedCount: reviewedCount ?? this.reviewedCount,
    );
  }
}

// ─────────────────────────────────────────────
// QualityLogService
// ─────────────────────────────────────────────

class QualityLogService {
  final QualityLogRepository _repository = QualityLogRepository();

  Future<QualityLogContainer> fetchQualityLog({
    QualityItemStatus? filterByStatus,
    int page = 1,
  }) async {
    final results = await Future.wait<Object>([
      _repository.getQualityItems(
        page: page,
        pageSize: 100,
        status: filterByStatus?.name, // "pending" | "reviewed" | null
      ),
      _repository.getQualityCounts(),
    ]);
    final response = results[0] as QualityItemsListResponse;
    final counts = results[1] as ({int pendingCount, int reviewedCount});

    final items = response.items.map((item) {
      var q = QualityItem.fromResponse(item);
      if (filterByStatus == QualityItemStatus.pending) {
        q = q.copyWith(status: QualityItemStatus.pending);
      }
      if (q.imageUrl != null && !q.imageUrl!.startsWith('http')) {
        q = q.copyWith(
          imageUrl: '${ApiConfig.baseUrl}/${q.imageUrl!.replaceAll('\\', '/')}',
        );
      }
      return q;
    }).toList();

    return QualityLogContainer(
      items: items,
      lastUpdated: DateTime.now(),
      pendingCount: counts.pendingCount,
      reviewedCount: counts.reviewedCount,
    );
  }

  /// Send to dataset: confirms the inspection so the image is moved to its
  /// permanent Cloudinary category folder.
  /// Maps to PUT /inspections/{id}/confirm
  Future<bool> sendToDataset(String itemId) async {
    try {
      return await _repository.confirmInspection(itemId);
    } catch (e) {
      debugPrint('Error sending to dataset: $e');
      return false;
    }
  }

  /// Edit inspection: update status + defect type on the server.
  /// This is the call that moves an item from pending → reviewed.
  /// Maps to PUT /inspections/{id}/edit
  Future<bool> editInspection(
    String itemId,
    String status,
    String defectCategory,
  ) async {
    try {
      return await _repository.editInspection(
        itemId,
        status: status,
        defectCategory: defectCategory,
      );
    } catch (e) {
      debugPrint('Error editing inspection: $e');
      return false;
    }
  }

  /// Relabel: change the defect type (and status) via PUT /inspections/{id}/edit.
  Future<bool> relabelItem(String itemId, String newLabel) async {
    try {
      return await _repository.relabelItem(itemId, newLabel);
    } catch (e) {
      debugPrint('Error relabeling item: $e');
      return false;
    }
  }

  Future<bool> confirmInspection(String inspectionId) async {
    try {
      return await _repository.confirmInspection(inspectionId);
    } catch (e) {
      debugPrint('Error confirming inspection: $e');
      return false;
    }
  }
}

// ─────────────────────────────────────────────
// Extensions
// ─────────────────────────────────────────────

extension QualityItemTypeExtension on QualityItemType {
  String get displayName {
    switch (this) {
      case QualityItemType.perfectBottle:
        return 'perfect_bottle';
      case QualityItemType.noCap:
        return 'No_cap';
      case QualityItemType.crookedCap:
        return 'Crooked_cap';
      case QualityItemType.emptyBottle:
        return 'Empty_bottle';
      case QualityItemType.noLabel:
        return 'No_label';
      case QualityItemType.invalid:
        return 'Invalid';
    }
  }

  Color get color {
    switch (this) {
      case QualityItemType.perfectBottle:
        return Colors.green;
      case QualityItemType.noCap:
        return const Color(0xFF1A1A2E);
      case QualityItemType.crookedCap:
        return const Color(0xFF9B59B6);
      case QualityItemType.emptyBottle:
        return const Color(0xFFE67E22);
      case QualityItemType.noLabel:
        return const Color(0xFFE74C3C);
      case QualityItemType.invalid:
        return const Color(0xFF7F8C8D);
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
        return const Color(0xFFFEF5E7);
      case QualityItemStatus.reviewed:
        return const Color(0xFFE8E8E8);
    }
  }

  Color get badgeTextColor {
    switch (this) {
      case QualityItemStatus.pending:
        return const Color(0xFFF59E0B);
      case QualityItemStatus.reviewed:
        return const Color(0xFF666666);
    }
  }
}

extension QualityReviewCategoryExtension on QualityReviewCategory {
  String get displayName {
    switch (this) {
      case QualityReviewCategory.good:
        return 'Good';
      case QualityReviewCategory.defected:
        return 'Defected';
      case QualityReviewCategory.invalid:
        return 'Invalid';
    }
  }

  Color get badgeColor {
    switch (this) {
      case QualityReviewCategory.good:
        return const Color(0xFFE8F8F0);
      case QualityReviewCategory.defected:
        return const Color(0xFFFEE8E8);
      case QualityReviewCategory.invalid:
        return const Color(0xFFF0F0F0);
    }
  }

  Color get badgeTextColor {
    switch (this) {
      case QualityReviewCategory.good:
        return const Color(0xFF27AE60);
      case QualityReviewCategory.defected:
        return const Color(0xFFE74C3C);
      case QualityReviewCategory.invalid:
        return const Color(0xFF7F8C8D);
    }
  }
}

/// Buckets a reviewed QualityItem into Good / Defected / Invalid based on
/// the raw backend status string. Returns null for pending items, since the
/// bucketing only applies within the Reviewed tab.
extension QualityItemReviewCategoryExtension on QualityItem {
  QualityReviewCategory? get reviewCategory {
    if (status != QualityItemStatus.reviewed) return null;
    final raw = (rawStatus ?? '').toLowerCase();
    if (raw == 'good') return QualityReviewCategory.good;
    if (raw == 'invalid') return QualityReviewCategory.invalid;
    // "Defected", specific defect type names (Broken/Skratch/Label), or any
    // other non-good/non-invalid reviewed status all bucket as Defected.
    return QualityReviewCategory.defected;
  }
}
