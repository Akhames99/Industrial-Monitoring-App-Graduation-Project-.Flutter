import 'dart:convert';
import 'package:app/core/api/api_response_models.dart';
import 'package:app/features/home/repositories/home_repository.dart';
import 'package:app/features/home/widgets/system_state_widget.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;
  static const String _sessionKey = 'session_status';
  static const String _segmentsKey = 'system_segments_24h';
  static const String _lastUpdateDateKey = 'last_update_date';

  HomeBloc({required HomeRepository homeRepository})
    : _homeRepository = homeRepository,
      super(HomeState()) {
    on<HomeFetchData>(_onHomeFetchData);
    on<StartSessionRequested>(_onStartSessionRequested);
    on<StopSessionRequested>(_onStopSessionRequested);
    on<_UpdateLocalStatus>(_onUpdateLocalStatus);
    on<CheckActiveSessionRequested>(_onCheckActiveSession);
    on<FetchSessionHistory>(_onFetchSessionHistory);
    on<ChangeHistoryDate>(_onChangeHistoryDate);
    on<ChangeProductionYieldSession>(_onChangeProductionYieldSession);
    _initializeLocalState();
  }

  Future<void> _initializeLocalState() async {
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";
    final lastDate = prefs.getString(_lastUpdateDateKey) ?? today;

    if (lastDate != today) {
      await prefs.clear();
      await prefs.setString(_lastUpdateDateKey, today);
    }

    final savedStatus = prefs.getString(_sessionKey) ?? 'Idle';
    final segmentsJson = prefs.getString(_segmentsKey);
    final startTimeStr = prefs.getString('session_start_time');
    final endTimeStr = prefs.getString('session_end_time');

    final startTime = startTimeStr != null
        ? DateTime.tryParse(startTimeStr)
        : null;
    final endTime = endTimeStr != null ? DateTime.tryParse(endTimeStr) : null;

    List<StateSegment> segments;
    if (segmentsJson != null) {
      final List<dynamic> decoded = jsonDecode(segmentsJson);
      segments = decoded
          .map(
            (s) => StateSegment(
              state: s['state'] == 'running'
                  ? SystemState.running
                  : SystemState.idle,
              startHour: (s['start'] as num).toDouble(),
              endHour: (s['end'] as num).toDouble(),
            ),
          )
          .toList();
    } else {
      segments = [
        StateSegment(state: SystemState.idle, startHour: 0.0, endHour: 24.0),
      ];
    }

    add(
      _UpdateLocalStatus(
        status: savedStatus,
        segments: segments,
        startTime: startTime,
        endTime: endTime,
      ),
    );

    add(const CheckActiveSessionRequested());
  }

  Future<void> _onCheckActiveSession(
    CheckActiveSessionRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final session = await _homeRepository.getActiveSession();

      final String apiStatus = session.isActive ? 'Running' : 'Idle';

      // Only update if API disagrees with local state — avoids unnecessary redraws
      if (apiStatus != state.systemStatus ||
          (session.startTime != null &&
              session.startTime != state.sessionStartTime)) {
        final now = DateTime.now();
        final currentHour = now.hour + (now.minute / 60.0);

        // Rebuild segments to reflect the real status
        final List<StateSegment> updatedSegments = _updateSegmentsForAction(
          state.systemSegments,
          session.isActive ? SystemState.running : SystemState.idle,
          currentHour,
        );

        // Persist the corrected state locally
        await _saveState(
          apiStatus,
          updatedSegments,
          startTime: session.startTime,
        );

        emit(
          state.copyWith(
            systemStatus: apiStatus,
            systemSegments: updatedSegments,
            sessionStartTime: session.startTime,
          ),
        );
      }
    } catch (_) {
      // Silently keep local state if API check fails
    }
  }

  void _onUpdateLocalStatus(_UpdateLocalStatus event, Emitter<HomeState> emit) {
    emit(
      state.copyWith(
        systemStatus: event.status,
        systemSegments: event.segments,
        sessionStartTime: event.startTime,
        sessionEndTime: event.endTime,
      ),
    );
  }

  Future<void> _onHomeFetchData(
    HomeFetchData event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      // Trigger session check alongside dashboard data fetch
      add(const CheckActiveSessionRequested());

      // Fetch dashboard data from repository
      final yieldData = await _homeRepository.getProductionYield(
        sessionId: state.selectedSessionId,
      );
      final defectionData = await _homeRepository.getDefectionData(
        sessionId: state.selectedSessionId,
      );

      emit(
        state.copyWith(
          status: HomeStatus.success,
          productionYield: yieldData,
          defectionData: defectionData,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onStartSessionRequested(
    StartSessionRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (state.systemStatus == 'Running') return;

    emit(state.copyWith(isSessionLoading: true));
    try {
      final success = await _homeRepository.startSession();
      if (success) {
        final now = DateTime.now();
        final currentHour = now.hour + (now.minute / 60.0);

        final List<StateSegment> updatedSegments = _updateSegmentsForAction(
          state.systemSegments,
          SystemState.running,
          currentHour,
        );

        await _saveState('Running', updatedSegments, startTime: now);

        emit(
          state.copyWith(
            isSessionLoading: false,
            systemStatus: 'Running',
            systemSegments: updatedSegments,
            sessionStartTime: now,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isSessionLoading: false,
            errorMessage: 'Failed to start session',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isSessionLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onStopSessionRequested(
    StopSessionRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (state.systemStatus == 'Idle') return;

    emit(state.copyWith(isSessionLoading: true));
    try {
      final success = await _homeRepository.stopSession();
      if (success) {
        final now = DateTime.now();
        final currentHour = now.hour + (now.minute / 60.0);

        final List<StateSegment> updatedSegments = _updateSegmentsForAction(
          state.systemSegments,
          SystemState.idle,
          currentHour,
        );

        await _saveState('Idle', updatedSegments, endTime: now);

        emit(
          state.copyWith(
            isSessionLoading: false,
            systemStatus: 'Idle',
            systemSegments: updatedSegments,
            sessionEndTime: now,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isSessionLoading: false,
            errorMessage: 'Failed to stop session',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isSessionLoading: false, errorMessage: e.toString()));
    }
  }

  List<StateSegment> _updateSegmentsForAction(
    List<StateSegment> currentSegments,
    SystemState newState,
    double timeHour,
  ) {
    List<StateSegment> newSegments = List.from(currentSegments);

    // Find the segment that contains the current time
    // Usually it's the last one that ends at 24
    int targetIndex = newSegments.indexWhere((s) => s.endHour == 24);

    if (targetIndex != -1) {
      final lastSegment = newSegments[targetIndex];

      // If the current time is after the start of the last segment
      if (timeHour > lastSegment.startHour) {
        // Close the current segment at timeHour
        newSegments[targetIndex] = StateSegment(
          state: lastSegment.state,
          startHour: lastSegment.startHour,
          endHour: timeHour,
        );

        // Add new active segment from timeHour to 24
        newSegments.add(
          StateSegment(state: newState, startHour: timeHour, endHour: 24.0),
        );
      }
    }

    return newSegments;
  }

  Future<void> _saveState(
    String status,
    List<StateSegment> segments, {
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, status);

    if (startTime != null) {
      await prefs.setString('session_start_time', startTime.toIso8601String());
    }
    if (endTime != null) {
      await prefs.setString('session_end_time', endTime.toIso8601String());
    }

    final segmentsJson = jsonEncode(
      segments
          .map(
            (s) => {
              'state': s.state == SystemState.running ? 'running' : 'idle',
              'start': s.startHour,
              'end': s.endHour,
            },
          )
          .toList(),
    );

    await prefs.setString(_segmentsKey, segmentsJson);
  }

  Future<void> _onFetchSessionHistory(
    FetchSessionHistory event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final sessions = await _homeRepository.getSessions();
      final historySegments = _calculateSegmentsForDate(
        sessions,
        state.selectedHistoryDate,
      );

      final now = DateTime.now();
      final isToday =
          state.selectedHistoryDate.year == now.year &&
          state.selectedHistoryDate.month == now.month &&
          state.selectedHistoryDate.day == now.day;

      if (isToday) {
        await _saveState(state.systemStatus, historySegments);
      }

      emit(
        state.copyWith(
          status: HomeStatus.success,
          allSessions: sessions,
          historySegments: historySegments,
          systemSegments: isToday ? historySegments : null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  void _onChangeHistoryDate(ChangeHistoryDate event, Emitter<HomeState> emit) {
    final historySegments = _calculateSegmentsForDate(
      state.allSessions,
      event.date,
    );
    emit(
      state.copyWith(
        selectedHistoryDate: event.date,
        historySegments: historySegments,
      ),
    );
  }

  List<StateSegment> _calculateSegmentsForDate(
    List<SessionResponse> sessions,
    DateTime date,
  ) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    // 1. Sort all sessions by start time first to handle zombie sessions
    final sortedAll = List<SessionResponse>.from(sessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    List<({double start, double end})> runningPeriods = [];

    for (int i = 0; i < sortedAll.length; i++) {
      final s = sortedAll[i];
      final sStart = s.startTime.toLocal();

      // Heuristic: If stopTime is null but there is a NEXT session,
      // cap this one to the start of the next session.
      DateTime effectiveStop;
      if (s.stopTime != null) {
        effectiveStop = s.stopTime!;
      } else if (i < sortedAll.length - 1) {
        effectiveStop = sortedAll[i + 1].startTime;
      } else {
        effectiveStop = DateTime.now();
      }

      final sEnd = effectiveStop.toLocal();

      // Check if session overlaps with the requested day
      if (sStart.isBefore(endOfDay) && sEnd.isAfter(startOfDay)) {
        double startHour = sStart.isBefore(startOfDay)
            ? 0.0
            : sStart.hour + (sStart.minute / 60.0) + (sStart.second / 3600.0);

        double endHour = sEnd.isAfter(endOfDay)
            ? 24.0
            : sEnd.hour + (sEnd.minute / 60.0) + (sEnd.second / 3600.0);

        if (endHour > startHour) {
          runningPeriods.add((start: startHour, end: endHour));
        }
      }
    }

    if (runningPeriods.isEmpty) {
      return [
        StateSegment(state: SystemState.idle, startHour: 0.0, endHour: 24.0),
      ];
    }

    // 2. Merge overlapping periods
    runningPeriods.sort((a, b) => a.start.compareTo(b.start));

    List<({double start, double end})> mergedPeriods = [];
    if (runningPeriods.isNotEmpty) {
      var current = runningPeriods[0];
      for (int i = 1; i < runningPeriods.length; i++) {
        final next = runningPeriods[i];
        if (next.start <= current.end) {
          if (next.end > current.end) {
            current = (start: current.start, end: next.end);
          }
        } else {
          mergedPeriods.add(current);
          current = next;
        }
      }
      mergedPeriods.add(current);
    }

    // 3. Build final segments with idle gaps
    List<StateSegment> segments = [];
    double currentHour = 0.0;

    for (final period in mergedPeriods) {
      if (period.start > currentHour) {
        segments.add(
          StateSegment(
            state: SystemState.idle,
            startHour: currentHour,
            endHour: period.start,
          ),
        );
      }
      segments.add(
        StateSegment(
          state: SystemState.running,
          startHour: period.start,
          endHour: period.end,
        ),
      );
      currentHour = period.end;
    }

    if (currentHour < 24.0) {
      segments.add(
        StateSegment(
          state: SystemState.idle,
          startHour: currentHour,
          endHour: 24.0,
        ),
      );
    }

    return segments;
  }

  Future<void> _onChangeProductionYieldSession(
    ChangeProductionYieldSession event,
    Emitter<HomeState> emit,
  ) async {
    emit(
      state.copyWith(
        status: HomeStatus.loading,
        selectedSessionId: event.sessionId,
      ),
    );
    try {
      final yieldData = await _homeRepository.getProductionYield(
        sessionId: event.sessionId,
      );
      final defectionData = await _homeRepository.getDefectionData(
        sessionId: event.sessionId,
      );

      emit(
        state.copyWith(
          status: HomeStatus.success,
          productionYield: yieldData,
          defectionData: defectionData,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}

class _UpdateLocalStatus extends HomeEvent {
  final String status;
  final List<StateSegment> segments;
  final DateTime? startTime;
  final DateTime? endTime;

  const _UpdateLocalStatus({
    required this.status,
    required this.segments,
    this.startTime,
    this.endTime,
  });
}
