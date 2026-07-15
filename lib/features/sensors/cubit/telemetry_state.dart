import 'package:equatable/equatable.dart';

class TelemetryReading extends Equatable {
  final double value;
  final DateTime timestamp;

  const TelemetryReading({required this.value, required this.timestamp});

  @override
  List<Object?> get props => [value, timestamp];
}

class VibrationReading extends Equatable {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  const VibrationReading({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [x, y, z, timestamp];
}

class TelemetryState extends Equatable {
  /// One numeric reading per sensor_id (e.g. 'Temp_01' -> 23.5).
  /// Vibration sensors are collapsed to a single magnitude value.
  final Map<String, double> values;

  /// History of standard single-value sensor readings: sensor_id -> list of readings
  final Map<String, List<TelemetryReading>> history;

  /// History of vibration readings (x, y, z): sensor_id -> list of vibration readings
  final Map<String, List<VibrationReading>> vibrationHistory;

  /// Latest vibration reading per sensor_id
  final Map<String, VibrationReading> latestVibration;

  /// PLC logical status (e.g. 'START' / 'STOP'), kept separately since
  /// it's a string, not a numeric sensor reading.
  final String? plcStatus;

  final bool isConnected;
  final bool sessionExpired;
  final String? error;

  const TelemetryState({
    this.values = const {},
    this.history = const {},
    this.vibrationHistory = const {},
    this.latestVibration = const {},
    this.plcStatus,
    this.isConnected = false,
    this.sessionExpired = false,
    this.error,
  });

  TelemetryState copyWith({
    Map<String, double>? values,
    Map<String, List<TelemetryReading>>? history,
    Map<String, List<VibrationReading>>? vibrationHistory,
    Map<String, VibrationReading>? latestVibration,
    String? plcStatus,
    bool? isConnected,
    bool? sessionExpired,
    String? error,
  }) {
    return TelemetryState(
      values: values ?? this.values,
      history: history ?? this.history,
      vibrationHistory: vibrationHistory ?? this.vibrationHistory,
      latestVibration: latestVibration ?? this.latestVibration,
      plcStatus: plcStatus ?? this.plcStatus,
      isConnected: isConnected ?? this.isConnected,
      sessionExpired: sessionExpired ?? this.sessionExpired,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    values,
    history,
    vibrationHistory,
    latestVibration,
    plcStatus,
    isConnected,
    sessionExpired,
    error,
  ];
}
