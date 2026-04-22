part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final String systemStatus; // 'Running' or 'Idle'
  final List<StateSegment> systemSegments;
  final String? errorMessage;
  final bool isSessionLoading;
  final DateTime? sessionStartTime;
  final DateTime? sessionEndTime;

  const HomeState({
    this.status = HomeStatus.initial,
    this.systemStatus = 'Idle',
    this.systemSegments = const [],
    this.errorMessage,
    this.isSessionLoading = false,
    this.sessionStartTime,
    this.sessionEndTime,
  });

  HomeState copyWith({
    HomeStatus? status,
    String? systemStatus,
    List<StateSegment>? systemSegments,
    String? errorMessage,
    bool? isSessionLoading,
    DateTime? sessionStartTime,
    DateTime? sessionEndTime,
  }) {
    return HomeState(
      status: status ?? this.status,
      systemStatus: systemStatus ?? this.systemStatus,
      systemSegments: systemSegments ?? this.systemSegments,
      errorMessage: errorMessage ?? this.errorMessage,
      isSessionLoading: isSessionLoading ?? this.isSessionLoading,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      sessionEndTime: sessionEndTime ?? this.sessionEndTime,
    );
  }

  @override
  List<Object?> get props => [
    status,
    systemStatus,
    systemSegments,
    errorMessage,
    isSessionLoading,
    sessionStartTime,
    sessionEndTime,
  ];
}

class HomeInitial extends HomeState {}
