part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class HomeFetchData extends HomeEvent {}

class StartSessionRequested extends HomeEvent {}

class StopSessionRequested extends HomeEvent {}

class CheckActiveSessionRequested extends HomeEvent {
  const CheckActiveSessionRequested();
}
