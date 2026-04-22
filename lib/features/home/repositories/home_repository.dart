import 'dart:convert';
import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/api_exception.dart';
import 'package:app/core/api/api_response_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeRepository {
  final ApiClient _apiClient = ApiClient();

  // Check active session from DB via /session-status
  // Check active session from DB via /session-status
  Future<ActiveSessionResponse> getActiveSession() async {
    try {
      final response = await _apiClient.get(Endpoints.activeSession);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        final bool isActive = data['is_running'] == true;

        return ActiveSessionResponse(isActive: isActive, startTime: null);
      }

      return ActiveSessionResponse(isActive: false);
    } catch (_) {
      return ActiveSessionResponse(isActive: false);
    }
  }

  // Fetch production yield (Mocked)
  Future<ProductionYieldResponse> getProductionYield({
    String period = 'today',
  }) async {
    const good = 2160;
    const defective = 540;
    const total = good + defective;

    return ProductionYieldResponse(
      goodProducts: good,
      defectiveProducts: defective,
      totalProducts: total,
      yieldPercentage: (good / total) * 100,
      period: period,
      timestamp: DateTime.now(),
    );
  }

  // Fetch defection data (Mocked)
  Future<DefectionResponse> getDefectionData({String period = 'today'}) async {
    const categories = [
      {'name': 'Cracks', 'count': 261, 'color': '#1abc9c'},
      {'name': 'Scratch', 'count': 199, 'color': '#3498db'},
      {'name': 'Labels', 'count': 80, 'color': '#e67e22'},
    ];

    final total = categories.fold<int>(
      0,
      (sum, item) => sum + (item['count'] as int),
    );

    return DefectionResponse(
      totalDefects: total,
      categories: categories
          .map(
            (c) => DefectCategoryResponse(
              name: c['name'] as String,
              count: c['count'] as int,
              percentage: ((c['count'] as int) / total) * 100,
              color: c['color'] as String,
            ),
          )
          .toList(),
      period: period,
      timestamp: DateTime.now(),
    );
  }

  // Fetch alerts (Mocked)
  Future<List<AlertResponse>> getAlerts({bool? acknowledged}) async {
    return [
      AlertResponse(
        id: '1',
        title: 'High Temperature Detected',
        description:
            'The motor temperature has exceeded 85°C. Please inspect the cooling system immediately.',
        severity: 'critical',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isAcknowledged: false,
      ),
      AlertResponse(
        id: '2',
        title: 'Camera 2 Connection Lost',
        description:
            'Quality inspection on Line B is paused due to Cam2 being inactive.',
        severity: 'warning',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isAcknowledged: false,
      ),
    ];
  }

  // Acknowledge alert (Mocked)
  Future<bool> acknowledgeAlert(String alertId) async {
    return true;
  }

  // Start Session
  Future<bool> startSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('saved_user');
      Map<String, dynamic> data = {};

      if (savedUser != null) {
        final user = jsonDecode(savedUser);
        if (user['user_id'] != null) {
          data['user_id'] = user['user_id'];
        }
      }

      final response = await _apiClient.post(
        Endpoints.startSession,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final message = response.data is Map
            ? (response.data['message'] ??
                  response.data['detail'] ??
                  'Failed to start session')
            : 'Failed to start session: ${response.statusCode}';
        throw ApiException(
          message: message.toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error starting session: $e');
    }
  }

  // Stop Session
  Future<bool> stopSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('saved_user');
      Map<String, dynamic> data = {};

      if (savedUser != null) {
        final user = jsonDecode(savedUser);
        if (user['user_id'] != null) {
          data['user_id'] = user['user_id'];
        }
      }

      final response = await _apiClient.post(Endpoints.stopSession, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final message = response.data is Map
            ? (response.data['message'] ??
                  response.data['detail'] ??
                  'Failed to stop session')
            : 'Failed to stop session: ${response.statusCode}';
        throw ApiException(
          message: message.toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error stopping session: $e');
    }
  }
}
