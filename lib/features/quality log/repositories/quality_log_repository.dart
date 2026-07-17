import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/api_exception.dart';
import 'package:app/core/api/api_response_models.dart';
import 'package:flutter/material.dart';

class QualityLogRepository {
  final ApiClient _apiClient = ApiClient();

  Future<int> _getTotalCount(String endpoint) async {
    final response = await _apiClient.get(endpoint);
    if (response.statusCode != 200 || response.data == null) {
      throw ApiException(
        message: 'Failed to fetch inspection count',
        statusCode: response.statusCode,
      );
    }
    // Backend now returns a raw list, not {data, meta} — length IS the count.
    final list = response.data as List;
    return list.length;
  }

  Future<({int pendingCount, int reviewedCount})> getQualityCounts() async {
    final counts = await Future.wait([
      _getTotalCount(Endpoints.pendingReviewInspections),
      _getTotalCount(Endpoints.reviewedInspections),
    ]);
    return (pendingCount: counts[0], reviewedCount: counts[1]);
  }

  /// Fetches ALL items matching `status` — the backend no longer paginates,
  /// so this always returns the full set. Pagination now happens entirely
  /// client-side in QualityLogContainer.
  Future<QualityItemsListResponse> getQualityItems({
    String? status,
    String? reviewStatus, // Good/Defected/Invalid — only used for 'reviewed'
  }) async {
    try {
      List<QualityItemResponse> allItems;
      Set<String> pendingSourceIds = {};

      if (status != null && status.toLowerCase() == 'pending') {
        final response = await _apiClient.get(
          Endpoints.pendingReviewInspections,
        );
        if (response.statusCode != 200 || response.data == null) {
          throw ApiException(
            message: 'Failed to fetch pending inspections',
            statusCode: response.statusCode,
          );
        }
        final list = response.data as List; // ← raw list now, not a Map
        allItems = list
            .map(
              (item) =>
                  QualityItemResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (status != null && status.toLowerCase() == 'reviewed') {
        final response = await _apiClient.get(
          Endpoints.reviewedInspections,
          queryParameters: {
            if (reviewStatus != null) 'status_filter': reviewStatus,
          },
        );
        if (response.statusCode != 200 || response.data == null) {
          throw ApiException(
            message: 'Failed to fetch reviewed inspections',
            statusCode: response.statusCode,
          );
        }
        final list = response.data as List;
        allItems = list
            .map(
              (item) =>
                  QualityItemResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        // All: union of both full lists.
        final responses = await Future.wait([
          _apiClient.get(Endpoints.pendingReviewInspections),
          _apiClient.get(Endpoints.reviewedInspections),
        ]);

        final pendingResponse = responses[0];
        final reviewedResponse = responses[1];

        if (pendingResponse.statusCode != 200 || pendingResponse.data == null) {
          throw ApiException(
            message: 'Failed to fetch pending inspections',
            statusCode: pendingResponse.statusCode,
          );
        }
        if (reviewedResponse.statusCode != 200 ||
            reviewedResponse.data == null) {
          throw ApiException(
            message: 'Failed to fetch reviewed inspections',
            statusCode: reviewedResponse.statusCode,
          );
        }

        final pendingList = pendingResponse.data as List;
        final reviewedList = reviewedResponse.data as List;

        final pendingItems = pendingList
            .map(
              (item) =>
                  QualityItemResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        final reviewedItems = reviewedList
            .map(
              (item) =>
                  QualityItemResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        // Do NOT stamp status here — keep it non-destructive (fixed earlier
        // for the "unknown_defect" bug). Track ids instead so the service
        // layer can bucket these as Pending without touching the real
        // Good/Defected/Invalid classification.
        pendingSourceIds = pendingItems.map((e) => e.id).toSet();
        allItems = [...pendingItems, ...reviewedItems];
      }

      // Normalize ordering: backend sorts pending oldest-first and
      // reviewed newest-first — always show newest-first regardless of tab.
      allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final total = allItems.length;
      final isPendingRequest =
          status != null && status.toLowerCase() == 'pending';
      final isReviewedRequest =
          status != null && status.toLowerCase() == 'reviewed';

      final pendingCount = isPendingRequest
          ? total
          : (isReviewedRequest ? 0 : pendingSourceIds.length);
      final reviewedCount = isReviewedRequest
          ? total
          : (isPendingRequest ? 0 : total - pendingSourceIds.length);

      return QualityItemsListResponse(
        items: allItems,
        total: total,
        pendingCount: pendingCount,
        reviewedCount: reviewedCount,
        pendingItemIds: pendingSourceIds,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error fetching quality items: $e');
    }
  }

  /// Confirm inspection: moves the image to its permanent Cloudinary
  /// category folder and stamps user_id server-side, which is what moves
  /// the item from Pending to Reviewed.
  /// Maps to PUT /inspections/{id}/confirm
  Future<bool> confirmInspection(String inspectionId) async {
    try {
      final endpoint = Endpoints.confirmInspection.replaceAll(
        '{inspection_id}',
        inspectionId,
      );
      final response = await _apiClient.put(endpoint);
      debugPrint(
        '[confirmInspection] PUT $endpoint → '
        'status=${response.statusCode}, body=${response.data}',
      );
      return response.statusCode == 200;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error confirming inspection: $e');
    }
  }

  /// Edit inspection status and/or defect type.
  /// Maps to PUT /inspections/{id}/edit  →  { status, defect_type }
  Future<bool> editInspection(
    String inspectionId, {
    required String status,
    required String defectCategory,
  }) async {
    try {
      final endpoint = Endpoints.editInspection.replaceAll(
        '{inspection_id}',
        inspectionId,
      );
      final response = await _apiClient.put(
        endpoint,
        data: {
          'status': status,
          'defect_type': defectCategory.isEmpty ? null : defectCategory,
          'is_confirmed': status.toLowerCase() != 'pending',
        },
      );
      debugPrint(
        '[editInspection] PUT $endpoint → '
        'status=${response.statusCode}, body=${response.data}',
      );
      return response.statusCode == 200;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error editing inspection: $e');
    }
  }

  /// Relabel item — uses PUT /inspections/{id}/edit (same as editInspection).
  /// The old code incorrectly called the non-existent /quality/items/{id} endpoint.
  Future<bool> relabelItem(String inspectionId, String newLabel) async {
    final isGood = newLabel.toLowerCase() == 'perfect_bottle';
    return editInspection(
      inspectionId,
      status: isGood ? 'Good' : 'Defected',
      defectCategory: isGood ? '' : newLabel,
    );
  }
}
