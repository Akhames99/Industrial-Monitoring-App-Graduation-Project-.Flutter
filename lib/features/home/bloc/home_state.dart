part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final String systemStatus;
  final List<StateSegment> systemSegments;
  final String? errorMessage;
  final bool isSessionLoading;
  final DateTime? sessionStartTime;
  final DateTime? sessionEndTime;
  final ProductionYieldResponse? productionYield;
  final DefectionResponse? defectionData;
  final String? selectedSessionId;

  // History fields
  final List<SessionResponse> allSessions;
  final List<StateSegment> historySegments;
  final DateTime selectedHistoryDate;

  HomeState({
    this.status = HomeStatus.initial,
    this.systemStatus = 'Idle',
    this.systemSegments = const [],
    this.errorMessage,
    this.isSessionLoading = false,
    this.sessionStartTime,
    this.sessionEndTime,
    this.productionYield,
    this.defectionData,
    this.selectedSessionId,
    this.allSessions = const [],
    this.historySegments = const [],
    DateTime? selectedHistoryDate,
  }) : selectedHistoryDate = selectedHistoryDate ?? DateTime.now();

  HomeState copyWith({
    HomeStatus? status,
    String? systemStatus,
    List<StateSegment>? systemSegments,
    String? errorMessage,
    bool? isSessionLoading,
    DateTime? sessionStartTime,
    DateTime? sessionEndTime,
    List<SessionResponse>? allSessions,
    List<StateSegment>? historySegments,
    DateTime? selectedHistoryDate,
    ProductionYieldResponse? productionYield,
    DefectionResponse? defectionData,
    String? selectedSessionId,
  }) {
    return HomeState(
      status: status ?? this.status,
      systemStatus: systemStatus ?? this.systemStatus,
      systemSegments: systemSegments ?? this.systemSegments,
      errorMessage: errorMessage ?? this.errorMessage,
      isSessionLoading: isSessionLoading ?? this.isSessionLoading,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      sessionEndTime: sessionEndTime ?? this.sessionEndTime,
      allSessions: allSessions ?? this.allSessions,
      historySegments: historySegments ?? this.historySegments,
      selectedHistoryDate: selectedHistoryDate ?? this.selectedHistoryDate,
      productionYield: productionYield ?? this.productionYield,
      defectionData: defectionData ?? this.defectionData,
      selectedSessionId: selectedSessionId ?? this.selectedSessionId,
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
    allSessions,
    historySegments,
    selectedHistoryDate,
    productionYield,
    defectionData,
    selectedSessionId,
  ];
}

class HomeInitial extends HomeState {}
