import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/api_exception.dart';
import 'package:app/core/api/api_response_models.dart';
import 'package:flutter/material.dart';

class QualityLogRepository {
  final ApiClient _apiClient = ApiClient();

  // "All" isn't backed by its own endpoint — it's the union of pending +
  // reviewed. This is how many items we pull from each side when building
  // that union. Client-side pagination (4/page) happens further up in
  // QualityLogPage, so this just needs to be big enough to cover realistic
  // totals without a dedicated combined endpoint.
  static const int _allTabFetchSize = 100;

  Future<int> _getTotalCount(String endpoint) async {
    final response = await _apiClient.get(
      endpoint,
      queryParameters: {'page': 1, 'size': 1},
    );

    if (response.statusCode != 200 || response.data == null) {
      throw ApiException(
        message: 'Failed to fetch inspection count',
        statusCode: response.statusCode,
      );
    }

    final dataMap = response.data as Map<String, dynamic>;
    final meta = dataMap['meta'] as Map<String, dynamic>?;
    if (meta != null && meta['total_count'] is num) {
      return (meta['total_count'] as num).toInt();
    }

    final data = dataMap['data'];
    return data is List ? data.length : 0;
  }

  Future<({int pendingCount, int reviewedCount})> getQualityCounts() async {
    final counts = await Future.wait([
      _getTotalCount(Endpoints.pendingReviewInspections),
      _getTotalCount(Endpoints.reviewedInspections),
    ]);

    return (pendingCount: counts[0], reviewedCount: counts[1]);
  }

  /// Fetch quality items.
  ///
  /// Strategy:
  /// - status == "pending"  → GET /inspections/pending-review (paginated, has images)
  /// - status == "reviewed" → GET /inspections/reviewed (paginated)
  /// - status == null       → GET both endpoints concurrently and merge
  ///                           ("All" = union of pending + reviewed, since
  ///                           there's no single backend endpoint for it)
  Future<QualityItemsListResponse> getQualityItems({
    int page = 1,
    int pageSize = 10,
    String? status,
  }) async {
    try {
      final List<QualityItemResponse> items;
      int total = 0;
      int? pendingCountOverride;
      int? reviewedCountOverride;

      if (status != null && status.toLowerCase() == 'pending') {
        // ── Pending: use the dedicated paginated endpoint ──────────────────
        final response = await _apiClient.get(
          Endpoints.pendingReviewInspections,
          queryParameters: {'page': page, 'size': pageSize},
        );

        if (response.statusCode != 200 || response.data == null) {
          throw ApiException(
            message: 'Failed to fetch pending inspections',
            statusCode: response.statusCode,
          );
        }

        final dataMap = response.data as Map<String, dynamic>;
        final list = dataMap['data'] as List;
        items = list.map((item) {
          final json = Map<String, dynamic>.from(item as Map);
          return QualityItemResponse.fromJson(json);
        }).toList();

        final meta = dataMap['meta'] as Map<String, dynamic>?;
        total = meta != null
            ? (meta['total_count'] as num).toInt()
            : items.length;
      } else if (status != null && status.toLowerCase() == 'reviewed') {
        // ── Reviewed: use the dedicated paginated endpoint ─────────────────
        final response = await _apiClient.get(
          Endpoints.reviewedInspections,
          queryParameters: {'page': page, 'size': pageSize},
        );

        if (response.statusCode != 200 || response.data == null) {
          throw ApiException(
            message: 'Failed to fetch reviewed inspections',
            statusCode: response.statusCode,
          );
        }

        final dataMap = response.data as Map<String, dynamic>;
        final list = dataMap['data'] as List;
        items = list
            .map(
              (item) =>
                  QualityItemResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        final meta = dataMap['meta'] as Map<String, dynamic>?;
        total = meta != null
            ? (meta['total_count'] as num).toInt()
            : items.length;
      } else {
        // ── All: union of pending-review + reviewed, fetched concurrently ──
        final responses = await Future.wait([
          _apiClient.get(
            Endpoints.pendingReviewInspections,
            queryParameters: {'page': 1, 'size': _allTabFetchSize},
          ),
          _apiClient.get(
            Endpoints.reviewedInspections,
            queryParameters: {'page': 1, 'size': _allTabFetchSize},
          ),
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

        final pendingMap = pendingResponse.data as Map<String, dynamic>;
        final reviewedMap = reviewedResponse.data as Map<String, dynamic>;

        final pendingList = pendingMap['data'] as List;
        final reviewedList = reviewedMap['data'] as List;

        // Same tagging the dedicated pending branch does — the
        // pending-review endpoint doesn't include a status field itself,
        // so it has to be stamped on client-side.
        final pendingItems = pendingList.map((item) {
          final json = Map<String, dynamic>.from(item as Map);
          json['status'] = 'pending';
          return QualityItemResponse.fromJson(json);
        }).toList();

        final reviewedItems = reviewedList
            .map(
              (item) =>
                  QualityItemResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        items = [...pendingItems, ...reviewedItems];

        final pendingMeta = pendingMap['meta'] as Map<String, dynamic>?;
        final reviewedMeta = reviewedMap['meta'] as Map<String, dynamic>?;

        // Use the real backend totals (not just this batch's length) so the
        // header counts stay accurate even if either list exceeds
        // _allTabFetchSize.
        pendingCountOverride = pendingMeta != null
            ? (pendingMeta['total_count'] as num).toInt()
            : pendingItems.length;
        reviewedCountOverride = reviewedMeta != null
            ? (reviewedMeta['total_count'] as num).toInt()
            : reviewedItems.length;

        total = pendingCountOverride + reviewedCountOverride;
      }

      final isPendingRequest =
          status != null && status.toLowerCase() == 'pending';
      final isReviewedRequest =
          status != null && status.toLowerCase() == 'reviewed';

      final pendingCount =
          pendingCountOverride ??
          (isPendingRequest
              ? total
              : items.where((i) => i.status.toLowerCase() == 'pending').length);
      final reviewedCount =
          reviewedCountOverride ??
          (isReviewedRequest
              ? total
              : items
                    .where(
                      (i) =>
                          i.status.toLowerCase() != 'pending' &&
                          i.status.toLowerCase() != 'uploading_in_background',
                    )
                    .length);

      return QualityItemsListResponse(
        items: items,
        total: total,
        pendingCount: pendingCount,
        reviewedCount: reviewedCount,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error fetching quality items: $e');
    }
  }

  /// Confirm inspection as-is (moves image to its current category folder).
  Future<bool> confirmInspection(String inspectionId) async {
    try {
      final endpoint = Endpoints.confirmInspection.replaceAll(
        '{inspection_id}',
        inspectionId,
      );
      final response = await _apiClient.put(endpoint);
      debugPrint(
        '[confirmInspection] PUT $endpoint (session=${_apiClient.sessionId}) '
        '→ status=${response.statusCode}, body=${response.data}',
      ); // temp debug
      return response.statusCode == 200 || response.statusCode == 201;
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
