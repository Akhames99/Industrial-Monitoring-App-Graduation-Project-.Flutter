import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:app/features/home/views/models/active_alerts_model.dart';
import 'package:app/features/sensors/cubit/telemetry_cubit.dart';
import 'package:app/features/sensors/cubit/telemetry_state.dart';
import 'package:app/features/sensors/repositories/sensors_repository.dart';

part 'alert_state.dart';

class AlertCubit extends Cubit<AlertState> {
  final TelemetryCubit telemetryCubit;
  final SensorsRepository sensorsRepository;
  final AlertsService _alertsService = AlertsService();

  StreamSubscription<TelemetryState>? _telemetrySub;
  List<SensorModel> _sensors = [];
  final Map<String, String> _openAlertBySensor = {};

  // Trimming thresholds — tune to taste.
  static const int _maxAlertsBeforeTrim = 200;
  static const Duration _acknowledgedRetention = Duration(hours: 24);

  AlertCubit({required this.telemetryCubit, required this.sensorsRepository})
    : super(AlertInitial()) {
    _init();
  }

  Future<void> _init() async {
    await _loadSensors();
    emit(const AlertLoaded([])); // no backend endpoint yet — start empty
    _telemetrySub = telemetryCubit.stream.listen(_onTelemetryUpdate);
  }

  Future<void> _loadSensors() async {
    try {
      _sensors = await sensorsRepository.getSensors();
    } catch (_) {}
  }

  void syncSensor(SensorModel sensor) {
    final idx = _sensors.indexWhere((s) => s.sensorId == sensor.sensorId);
    if (idx != -1) {
      _sensors[idx] = sensor;
    } else {
      _sensors.add(sensor);
    }
  }

  Future<void> refreshSensors() => _loadSensors();

  List<Alert> get _currentAlerts =>
      state is AlertLoaded ? (state as AlertLoaded).alerts : <Alert>[];

  void _onTelemetryUpdate(TelemetryState telemetryState) {
    for (final sensor in _sensors) {
      if (!sensor.isActive) continue;

      final value = telemetryState.values[sensor.sensorId];
      if (value == null) continue;

      final isOver = value > sensor.maxThreshold;
      final isUnder = value < sensor.minThreshold;
      final isBreaching = isOver || isUnder;
      final hasOpenAlert = _openAlertBySensor.containsKey(sensor.sensorId);

      if (isBreaching && !hasOpenAlert) {
        _raiseAlert(sensor, value, isOver);
      } else if (!isBreaching && hasOpenAlert) {
        _openAlertBySensor.remove(sensor.sensorId);
      }
    }
  }

  void _raiseAlert(SensorModel sensor, double value, bool isOver) {
    final id = '${sensor.sensorId}_${DateTime.now().millisecondsSinceEpoch}';
    final alert = Alert(
      id: id,
      title: '${sensor.sensorId} ${isOver ? "Above" : "Below"} Threshold',
      description:
          '${sensor.sensorId} reading of ${value.toStringAsFixed(1)} '
          '${sensor.unit} is ${isOver ? "above the maximum" : "below the minimum"} '
          'threshold (${isOver ? sensor.maxThreshold : sensor.minThreshold} ${sensor.unit}).',
      severity: _severityFor(sensor, value, isOver),
      status: AlertStatus.active,
      createdAt: DateTime.now(),
    );
    _openAlertBySensor[sensor.sensorId] = id;
    emit(AlertLoaded([..._currentAlerts, alert]));
  }

  AlertSeverity _severityFor(SensorModel sensor, double value, bool isOver) {
    final range = sensor.maxThreshold - sensor.minThreshold;
    if (range <= 0) return AlertSeverity.warning;
    final overshoot = isOver
        ? value - sensor.maxThreshold
        : sensor.minThreshold - value;
    return (overshoot / range) > 0.2
        ? AlertSeverity.critical
        : AlertSeverity.warning;
  }

  Future<void> acknowledgeAlert(String alertId) async {
    final updated = [
      for (final a in _currentAlerts)
        if (a.id == alertId)
          a.copyWith(
            status: AlertStatus.acknowledged,
            acknowledgedAt: DateTime.now(),
          )
        else
          a,
    ];

    emit(AlertLoaded(_trim(updated)));

    try {
      await _alertsService.acknowledgeAlert(alertId);
    } catch (_) {}
  }

  Future<void> dismissAlert(String alertId) async {
    emit(AlertLoaded(_currentAlerts.where((a) => a.id != alertId).toList()));
    _openAlertBySensor.removeWhere((_, id) => id == alertId);
    try {
      await _alertsService.dismissAlert(alertId);
    } catch (_) {}
  }

  /// Drops old acknowledged alerts once the list grows past a reasonable
  /// cap, so a long-running session doesn't accumulate unbounded history.
  /// Active (unacknowledged) alerts are never trimmed.
  List<Alert> _trim(List<Alert> alerts) {
    if (alerts.length <= _maxAlertsBeforeTrim) return alerts;

    return alerts.where((a) {
      if (!a.isAcknowledged) return true;
      final since = DateTime.now().difference(a.acknowledgedAt ?? a.createdAt);
      return since < _acknowledgedRetention;
    }).toList();
  }

  @override
  Future<void> close() {
    _telemetrySub?.cancel();
    return super.close();
  }
}
