import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/api_exception.dart';
import 'package:app/core/api/api_response_models.dart';

class QualityLogRepository {
  final ApiClient _apiClient = ApiClient();

  // Fetch quality items with pagination and filtering
  Future<QualityItemsListResponse> getQualityItems({
    int page = 1,
    int pageSize = 10,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(
        Endpoints.getQualityData,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          final items = (response.data as List)
              .map(
                (item) =>
                    QualityItemResponse.fromJson(item as Map<String, dynamic>),
              )
              .toList();
          return QualityItemsListResponse(
            items: items,
            total: items.length,
            pendingCount: items.where((i) => i.status == 'pending').length,
            reviewedCount: items.where((i) => i.status == 'reviewed').length,
          );
        }
        return QualityItemsListResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to fetch quality items',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error fetching quality items: $e');
    }
  }

  // Get single quality item detail
  Future<QualityItemResponse> getQualityItemDetail(String itemId) async {
    try {
      final endpoint = Endpoints.qualityDetail.replaceAll('{id}', itemId);

      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200 && response.data != null) {
        return QualityItemResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to fetch quality item',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error fetching quality item: $e');
    }
  }

  // Confirm defection
  Future<QualityItemResponse> confirmDefection(String itemId) async {
    try {
      final response = await _apiClient.post(
        Endpoints.confirmDefection,
        data: {'item_id': itemId},
      );

      if (response.statusCode == 200 && response.data != null) {
        return QualityItemResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to confirm defection',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error confirming defection: $e');
    }
  }

  // Relabel item
  Future<QualityItemResponse> relabelItem(
    String itemId,
    String newLabel,
  ) async {
    try {
      final request = RelabelItemRequest(newLabel: newLabel);

      final response = await _apiClient.put(
        Endpoints.qualityDetail.replaceAll('{id}', itemId),
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return QualityItemResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to relabel item',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error relabeling item: $e');
    }
  }

  // Dismiss item
  Future<bool> dismissItem(String itemId) async {
    try {
      final response = await _apiClient.post(
        Endpoints.dismissItem,
        data: {'item_id': itemId},
      );

      return response.statusCode == 200;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error dismissing item: $e');
    }
  }

  // Send item to dataset
  Future<bool> sendToDataset(String itemId) async {
    try {
      final response = await _apiClient.post(
        Endpoints.sendToDataset,
        data: {'item_id': itemId},
      );

      return response.statusCode == 200;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error sending to dataset: $e');
    }
  }
}
