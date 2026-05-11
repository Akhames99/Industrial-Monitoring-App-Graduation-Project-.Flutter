part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeFetchData extends HomeEvent {}

class StartSessionRequested extends HomeEvent {}

class StopSessionRequested extends HomeEvent {}

class CheckActiveSessionRequested extends HomeEvent {
  const CheckActiveSessionRequested();
}

class FetchSessionHistory extends HomeEvent {}

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
