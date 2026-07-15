import 'dart:convert';
import 'package:app/core/api/api_response_models.dart';
import 'package:app/features/home/repositories/home_repository.dart';
import 'package:app/features/home/views/models/active_alerts_model.dart';
import 'package:app/features/home/widgets/system_state_widget.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
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
    on<ChangeHistoryDate>(_onChangeHistoryDate);
    on<ChangeProductionYieldSession>(_onChangeProductionYieldSession);
    on<FetchMotorTimeline>(_onFetchMotorTimeline);
    on<FetchMotorStatus>(_onFetchMotorStatus);
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

    final savedStatus = prefs.getString(_sessionKey) ?? 'Stopped';
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
              // Round-trips the real state (running/stopped/error/offline/unknown)
              // instead of collapsing everything down to running/idle.
              state: SystemState.values.firstWhere(
                (v) => v.name == s['state'],
                orElse: () => SystemState.stopped,
              ),
              startHour: (s['start'] as num).toDouble(),
              endHour: (s['end'] as num).toDouble(),
            ),
          )
          .toList();
    } else {
      segments = [
        StateSegment(state: SystemState.stopped, startHour: 0.0, endHour: 24.0),
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
  }

  void _onUpdateLocalStatus(_UpdateLocalStatus event, Emitter<HomeState> emit) {
    // Deliberately does NOT set systemStatus. The cached value in
    // SharedPreferences can be stale (e.g. from before /motor/status existed,
    // or from the last time the app was closed) and racing it against
    // FetchMotorStatus is exactly the bug that kept showing "Running".
    // /motor/status (via FetchMotorStatus) is the only writer of systemStatus.
    emit(
      state.copyWith(
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
      // /motor/status is the single source of truth for the live status badge.
      // /motor/timeline is only responsible for the segments bar / history list.
      add(const FetchMotorStatus());
      add(const FetchMotorTimeline());

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
      if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        emit(state.copyWith(status: HomeStatus.success));
        return;
      }
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

        // Refresh from the real backend shortly after so the badge reflects
        // actual telemetry rather than the optimistic local update.
        add(const FetchMotorStatus());
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
    if (state.systemStatus.toLowerCase() != 'running') return;

    emit(state.copyWith(isSessionLoading: true));
    try {
      final success = await _homeRepository.stopSession();
      if (success) {
        final now = DateTime.now();
        final currentHour = now.hour + (now.minute / 60.0);

        final List<StateSegment> updatedSegments = _updateSegmentsForAction(
          state.systemSegments,
          SystemState.stopped,
          currentHour,
        );

        await _saveState('Stopped', updatedSegments, endTime: now);

        emit(
          state.copyWith(
            isSessionLoading: false,
            systemStatus: 'Stopped',
            systemSegments: updatedSegments,
            sessionEndTime: now,
          ),
        );

        add(const FetchMotorStatus());
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
              // Store the real enum name so it round-trips correctly on reload
              // instead of collapsing everything to running/idle.
              'state': s.state.name,
              'start': s.startHour,
              'end': s.endHour,
            },
          )
          .toList(),
    );

    await prefs.setString(_segmentsKey, segmentsJson);
  }

  /// Single source of truth for the live status badge (systemStatus).
  /// Hits /motor/status. Nothing else in this bloc should set systemStatus
  /// except the optimistic Start/Stop handlers above, which immediately
  /// re-sync via this same method afterwards.
  Future<void> _onFetchMotorStatus(
    FetchMotorStatus event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final motorStatus = await _homeRepository.getMotorStatus();
      final label = _statusLabel(
        mapMotorStateString(motorStatus.motorStatus) ?? SystemState.unknown,
      );

      await _saveState(label, state.systemSegments);

      emit(
        state.copyWith(
          systemStatus: label,
          motorStatusMessage: motorStatus.message,
        ),
      );
    } catch (e) {
      debugPrint('Failed to fetch motor status: $e');
      // Non-fatal — badge keeps showing last known status
    }
  }

  String _statusLabel(SystemState state) {
    switch (state) {
      case SystemState.running:
        return 'Running';
      case SystemState.stopped:
        return 'Stopped';
      case SystemState.error:
        return 'Error';
      case SystemState.offline:
        return 'Offline';
      case SystemState.unknown:
        return 'Unknown';
    }
  }

  /// Responsible ONLY for segments (systemSegments / historySegments /
  /// timelineEntries) — never touches systemStatus. /motor/status owns that.
  Future<void> _onFetchMotorTimeline(
    FetchMotorTimeline event,
    Emitter<HomeState> emit,
  ) async {
    final targetDate = event.date ?? DateTime.now();
    emit(state.copyWith(isHistoryLoading: true, clearHistoryError: true));

    try {
      final data = await _homeRepository.getMotorTimeline(date: targetDate);

      final now = DateTime.now();
      final isToday =
          targetDate.year == now.year &&
          targetDate.month == now.month &&
          targetDate.day == now.day;

      emit(
        state.copyWith(
          isHistoryLoading: false,
          historySegments: data.segments,
          timelineEntries: data.entries,
          systemSegments: isToday ? data.segments : state.systemSegments,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isHistoryLoading: false,
          historyErrorMessage: 'Failed to load timeline: $e',
        ),
      );
    }
  }

  void _onChangeHistoryDate(ChangeHistoryDate event, Emitter<HomeState> emit) {
    emit(state.copyWith(selectedHistoryDate: event.date));
    add(FetchMotorTimeline(date: event.date));
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
