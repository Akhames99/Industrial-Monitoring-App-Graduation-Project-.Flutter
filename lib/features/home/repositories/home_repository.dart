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

  // Fetch all sessions
  Future<List<SessionResponse>> getSessions() async {
    try {
      final response = await _apiClient.get(Endpoints.sessions);

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map(
              (item) => SessionResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw ApiException(
          message: 'Failed to fetch sessions',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error fetching sessions: $e');
    }
  }

  // Fetch production yield
  Future<ProductionYieldResponse> getProductionYield({
    String period = 'today',
    String? sessionId,
  }) async {
    try {
      final endpoint = sessionId != null
          ? Endpoints.getQualityDataBySession.replaceAll(
              '{session_id}',
              sessionId,
            )
          : Endpoints.getQualityData;

      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> items = response.data is List
            ? response.data
            : (response.data['items'] ?? []);

        final inspections = items
            .map((i) => QualityItemResponse.fromJson(i as Map<String, dynamic>))
            .toList();

        int goodCount = 0;
        int defectiveCount = 0;

        for (var item in inspections) {
          final status = item.status.toLowerCase();
          if (status == 'good') {
            goodCount++;
          } else {
            defectiveCount++;
          }
        }

        final total = goodCount + defectiveCount;

        return ProductionYieldResponse(
          goodProducts: goodCount,
          defectiveProducts: defectiveCount,
          totalProducts: total,
          yieldPercentage: total > 0 ? (goodCount / total) * 100 : 0,
          period: period,
          timestamp: DateTime.now(),
        );
      } else {
        throw ApiException(
          message: 'Failed to fetch production yield',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error fetching production yield: $e');
    }
  }

  // Fetch defection data
  Future<DefectionResponse> getDefectionData({
    String period = 'today',
    String? sessionId,
  }) async {
    try {
      final endpoint = sessionId != null
          ? Endpoints.getQualityDataBySession.replaceAll(
              '{session_id}',
              sessionId,
            )
          : Endpoints.getQualityData;

      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> items = response.data is List
            ? response.data
            : (response.data['items'] ?? []);

        final inspections = items
            .map((i) => QualityItemResponse.fromJson(i as Map<String, dynamic>))
            .toList();

        Map<String, int> categoryCounts = {
          'Broken': 0,
          'Skratch': 0,
          'Label': 0,
        };

        int totalDefects = 0;

        for (var item in inspections) {
          if (item.status.toLowerCase() != 'good') {
            totalDefects++;

            // Priority: defectCategory -> title -> 'Broken' (default)
            final category = item.defectCategory ?? item.title;

            if (category.contains('Broken'))
              categoryCounts['Broken'] = (categoryCounts['Broken'] ?? 0) + 1;
            else if (category.contains('Skratch'))
              categoryCounts['Skratch'] = (categoryCounts['Skratch'] ?? 0) + 1;
            else if (category.contains('Label'))
              categoryCounts['Label'] = (categoryCounts['Label'] ?? 0) + 1;
            else {
              // Default to Broken if it's a defect but doesn't match other categories
              categoryCounts['Broken'] = (categoryCounts['Broken'] ?? 0) + 1;
            }
          }
        }

        final List<DefectCategoryResponse> categories = [];
        final List<String> colors = ['#1A1A2E', '#9B59B6', '#E67E22'];
        int colorIdx = 0;

        categoryCounts.forEach((name, count) {
          categories.add(
            DefectCategoryResponse(
              name: name,
              count: count,
              percentage: totalDefects > 0 ? (count / totalDefects) * 100 : 0,
              color: colors[colorIdx % colors.length],
            ),
          );
          colorIdx++;
        });

        return DefectionResponse(
          totalDefects: totalDefects,
          categories: categories,
          period: period,
          timestamp: DateTime.now(),
        );
      } else {
        throw ApiException(
          message: 'Failed to fetch defection data',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error fetching defection data: $e');
    }
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
