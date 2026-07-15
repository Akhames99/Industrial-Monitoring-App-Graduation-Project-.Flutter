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
  final List<Alert> alerts;

  // History / timeline fields
  final List<StateSegment> historySegments;
  final List<MotorTimelineEntryResponse> timelineEntries;
  final DateTime selectedHistoryDate;
  final bool isHistoryLoading;
  final String? historyErrorMessage;

  // /motor/status extra context (e.g. "No telemetry data found.")
  final String? motorStatusMessage;

  HomeState({
    this.status = HomeStatus.initial,
    this.systemStatus = 'Stopped',
    this.systemSegments = const [],
    this.errorMessage,
    this.isSessionLoading = false,
    this.sessionStartTime,
    this.sessionEndTime,
    this.productionYield,
    this.defectionData,
    this.selectedSessionId,
    this.alerts = const [],
    this.historySegments = const [],
    this.timelineEntries = const [],
    DateTime? selectedHistoryDate,
    this.isHistoryLoading = false,
    this.historyErrorMessage,
    this.motorStatusMessage,
  }) : selectedHistoryDate = selectedHistoryDate ?? DateTime.now();

  HomeState copyWith({
    HomeStatus? status,
    String? systemStatus,
    List<StateSegment>? systemSegments,
    String? errorMessage,
    bool? isSessionLoading,
    DateTime? sessionStartTime,
    DateTime? sessionEndTime,
    List<StateSegment>? historySegments,
    List<MotorTimelineEntryResponse>? timelineEntries,
    DateTime? selectedHistoryDate,
    bool? isHistoryLoading,
    String? historyErrorMessage,
    bool clearHistoryError = false,
    ProductionYieldResponse? productionYield,
    DefectionResponse? defectionData,
    String? selectedSessionId,
    List<Alert>? alerts,
    String? motorStatusMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      systemStatus: systemStatus ?? this.systemStatus,
      systemSegments: systemSegments ?? this.systemSegments,
      errorMessage: errorMessage ?? this.errorMessage,
      isSessionLoading: isSessionLoading ?? this.isSessionLoading,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      sessionEndTime: sessionEndTime ?? this.sessionEndTime,
      historySegments: historySegments ?? this.historySegments,
      timelineEntries: timelineEntries ?? this.timelineEntries,
      selectedHistoryDate: selectedHistoryDate ?? this.selectedHistoryDate,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
      historyErrorMessage: clearHistoryError
          ? null
          : (historyErrorMessage ?? this.historyErrorMessage),
      productionYield: productionYield ?? this.productionYield,
      defectionData: defectionData ?? this.defectionData,
      selectedSessionId: selectedSessionId ?? this.selectedSessionId,
      alerts: alerts ?? this.alerts,
      motorStatusMessage: motorStatusMessage ?? this.motorStatusMessage,
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
    historySegments,
    timelineEntries,
    selectedHistoryDate,
    isHistoryLoading,
    historyErrorMessage,
    productionYield,
    defectionData,
    selectedSessionId,
    alerts,
    motorStatusMessage,
  ];
}

class HomeInitial extends HomeState {}
