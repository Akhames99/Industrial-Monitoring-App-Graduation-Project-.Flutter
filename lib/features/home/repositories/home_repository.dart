import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/api_exception.dart';
import 'package:app/core/api/api_response_models.dart';
import 'package:app/features/home/widgets/system_state_widget.dart';

class MotorTimelineData {
  final List<StateSegment> segments;
  final List<MotorTimelineEntryResponse> entries;
  MotorTimelineData({required this.segments, required this.entries});
}

class HomeRepository {
  final ApiClient _apiClient = ApiClient();

  Future<MotorTimelineData> getMotorTimeline({DateTime? date}) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateStr =
          '${targetDate.year.toString().padLeft(4, '0')}-'
          '${targetDate.month.toString().padLeft(2, '0')}-'
          '${targetDate.day.toString().padLeft(2, '0')}';

      final response = await _apiClient.get(
        Endpoints.motorTimeLine,
        queryParameters: {'date': dateStr},
      );

      if (response.statusCode == 200 && response.data != null) {
        final timelineResponse = MotorTimelineResponse.fromJson(
          response.data as Map<String, dynamic>,
        );

        final segments = timelineResponse.timeline
            .map(_entryToSegment)
            .whereType<StateSegment>()
            .toList();

        return MotorTimelineData(
          segments: _fillTimelineGaps(segments),
          entries: timelineResponse.timeline,
        );
      } else {
        throw ApiException(
          message: 'Failed to fetch motor timeline',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error fetching motor timeline: $e');
    }
  }

  Future<ActiveSessionResponse> getActiveSession() async {
    try {
      final motorStatus = await getMotorStatus();
      final isActive =
          mapMotorStateString(motorStatus.motorStatus) == SystemState.running;
      return ActiveSessionResponse(isActive: isActive, startTime: null);
    } catch (_) {
      return ActiveSessionResponse(isActive: false);
    }
  }

  /// Fills gaps between logged segments (and before/after the first/last
  /// entry) with an `unknown` segment, so the returned list always spans
  /// the full 0–24 range. Without this, a day with only one logged
  /// interval (e.g. a single ERROR block) would be the *only* child in the
  /// timeline bar's Row, and Expanded would stretch it to fill 100% of the
  /// bar regardless of its actual duration.
  List<StateSegment> _fillTimelineGaps(List<StateSegment> segments) {
    if (segments.isEmpty) {
      return [
        StateSegment(state: SystemState.unknown, startHour: 0.0, endHour: 24.0),
      ];
    }

    final sorted = List<StateSegment>.from(segments)
      ..sort((a, b) => a.startHour.compareTo(b.startHour));

    final filled = <StateSegment>[];
    double cursor = 0.0;

    for (final segment in sorted) {
      if (segment.startHour > cursor) {
        filled.add(
          StateSegment(
            state: SystemState.unknown,
            startHour: cursor,
            endHour: segment.startHour,
          ),
        );
      }
      filled.add(segment);
      cursor = segment.endHour > cursor ? segment.endHour : cursor;
    }

    if (cursor < 24.0) {
      filled.add(
        StateSegment(
          state: SystemState.unknown,
          startHour: cursor,
          endHour: 24.0,
        ),
      );
    }

    return filled;
  }

  StateSegment? _entryToSegment(MotorTimelineEntryResponse entry) {
    final state = mapMotorStateString(entry.state);
    if (state == null) return null;

    final start = entry.startTime.toLocal();
    final end = entry.endTime.toLocal();

    double toHour(DateTime dt) =>
        dt.hour + (dt.minute / 60.0) + (dt.second / 3600.0);

    final startHour = toHour(start);

    // Only treat this as a midnight-spanning block if `end` is actually on a
    // later calendar day than `start`. The old check (toHour(end) <=
    // toHour(start)) also fired for same-timestamp blocks — a state that
    // only lasted a single telemetry sample — incorrectly stretching a
    // one-off blip all the way to 24.0 and painting the rest of the day
    // with that state.
    final crossesMidnight =
        end.isBefore(start) ||
        DateTime(
          end.year,
          end.month,
          end.day,
        ).isAfter(DateTime(start.year, start.month, start.day));

    double endHour;
    if (crossesMidnight) {
      endHour = 24.0;
    } else {
      endHour = toHour(end);
      // Zero-duration block (single sample): give it a minimal sliver
      // instead of collapsing to nothing or stretching to midnight.
      if (endHour <= startHour) {
        endHour = (startHour + (1 / 3600)).clamp(0.0, 24.0);
      }
    }

    return StateSegment(state: state, startHour: startHour, endHour: endHour);
  }

  Future<MotorStatusResponse> getMotorStatus() async {
    try {
      final response = await _apiClient.get(Endpoints.motorStatus);

      if (response.statusCode == 200 && response.data != null) {
        return MotorStatusResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to fetch motor status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error fetching motor status: $e');
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
        int invalidCount = 0;

        for (var item in inspections) {
          final status = item.status.toLowerCase();
          if (status == 'good') {
            goodCount++;
          } else if (status == 'invalid') {
            invalidCount++;
          } else {
            defectiveCount++;
          }
        }

        final total = goodCount + defectiveCount + invalidCount;

        return ProductionYieldResponse(
          goodProducts: goodCount,
          defectiveProducts: defectiveCount,
          invalidProducts: invalidCount,
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
          'No_cap': 0,
          'Crooked_cap': 0,
          'Empty_bottle': 0,
          'No_label': 0,
          'No_detection': 0,
        };

        int totalDefects = 0;

        for (var item in inspections) {
          if (item.status.toLowerCase() != 'good') {
            totalDefects++;

            // Priority: defectCategory -> title -> 'No_detection' (default)
            final category = (item.defectCategory ?? item.title).toLowerCase();

            if (category.contains('no_cap') || category.contains('nocap'))
              categoryCounts['No_cap'] = (categoryCounts['No_cap'] ?? 0) + 1;
            else if (category.contains('crooked_cap') ||
                category.contains('crookedcap'))
              categoryCounts['Crooked_cap'] =
                  (categoryCounts['Crooked_cap'] ?? 0) + 1;
            else if (category.contains('empty_bottle') ||
                category.contains('emptybottle'))
              categoryCounts['Empty_bottle'] =
                  (categoryCounts['Empty_bottle'] ?? 0) + 1;
            else if (category.contains('no_label') ||
                category.contains('nolabel'))
              categoryCounts['No_label'] =
                  (categoryCounts['No_label'] ?? 0) + 1;
            else
              categoryCounts['No_detection'] =
                  (categoryCounts['No_detection'] ?? 0) + 1;
          }
        }

        final List<DefectCategoryResponse> categories = [];
        final List<String> colors = [
          '#1A1A2E',
          '#9B59B6',
          '#E67E22',
          '#FF6B6B',
          '#4ECDC4',
        ];
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

  Future<bool> startSession() async {
    try {
      final response = await _apiClient.post(
        Endpoints.motorControl,
        data: {'command': 'start'},
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

  Future<bool> stopSession() async {
    try {
      final response = await _apiClient.post(
        Endpoints.motorControl,
        data: {'command': 'stop'},
      );

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
