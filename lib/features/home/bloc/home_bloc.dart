import 'dart:convert';
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
      super(const HomeState()) {
    on<HomeFetchData>(_onHomeFetchData);
    on<StartSessionRequested>(_onStartSessionRequested);
    on<StopSessionRequested>(_onStopSessionRequested);
    on<_UpdateLocalStatus>(_onUpdateLocalStatus);
    on<CheckActiveSessionRequested>(_onCheckActiveSession);
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
              startHour: s['start'],
              endHour: s['end'],
            ),
          )
          .toList();
    } else {
      segments = [
        StateSegment(state: SystemState.idle, startHour: 0, endHour: 24),
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

      // Fetching other dashboard data (mocked in repo for now)
      emit(state.copyWith(status: HomeStatus.success));
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
          startHour: lastSegment.startHour.toInt(),
          endHour: timeHour.toInt(),
        );

        // Add new active segment from timeHour to 24
        newSegments.add(
          StateSegment(
            state: newState,
            startHour: timeHour.toInt(),
            endHour: 24,
          ),
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
