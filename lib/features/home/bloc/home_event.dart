part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeFetchData extends HomeEvent {}

class StartSessionRequested extends HomeEvent {}

class StopSessionRequested extends HomeEvent {}

class ChangeHistoryDate extends HomeEvent {
  final DateTime date;
  const ChangeHistoryDate(this.date);

  @override
  List<Object?> get props => [date];
}

class ChangeProductionYieldSession extends HomeEvent {
  final String? sessionId;
  const ChangeProductionYieldSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Fetches /motor/timeline for the given date (defaults to today).
/// Only affects segments (systemSegments / historySegments / timelineEntries).
class FetchMotorTimeline extends HomeEvent {
  final DateTime? date;
  const FetchMotorTimeline({this.date});

  @override
  List<Object?> get props => [date];
}

/// Fetches /motor/status — the single source of truth for the live
/// systemStatus badge (Running / Stopped / Error / Offline / Unknown).
class FetchMotorStatus extends HomeEvent {
  const FetchMotorStatus();
}
