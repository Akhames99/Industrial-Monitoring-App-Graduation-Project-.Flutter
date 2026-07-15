import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'telemetry_state.dart';

class TelemetryCubit extends Cubit<TelemetryState> {
  TelemetryCubit() : super(const TelemetryState());

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  static const String _wsBaseUrl = 'wss://backend-api-db-ds3m.onrender.com';

  void connect(String sessionId) {
    final wsUrl = '$_wsBaseUrl/ws/telemetry?session_id=$sessionId';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      emit(state.copyWith(isConnected: true, error: null));

      _subscription = _channel!.stream.listen(
        _onMessage,
        onDone: _onDone,
        onError: _onError,
        cancelOnError: true,
      );
    } catch (e) {
      emit(state.copyWith(isConnected: false, error: e.toString()));
    }
  }

  void _onMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message as String);
      if (decoded['status'] != 'success' || decoded['data'] == null) return;

      // Confirmed shape (matches backend's get_latest_telemetry()): a list
      // of reading dicts, each with a sensor_id plus its own field(s).
      final List<dynamic> readings = decoded['data'] as List<dynamic>;
      final Map<String, double> updatedValues = Map.of(state.values);
      final Map<String, List<TelemetryReading>> updatedHistory = Map.of(
        state.history,
      );
      final Map<String, List<VibrationReading>> updatedVibrationHistory =
          Map.of(state.vibrationHistory);
      final Map<String, VibrationReading> updatedLatestVibration = Map.of(
        state.latestVibration,
      );
      String? plcStatus = state.plcStatus;
      final now = DateTime.now();

      for (final reading in readings) {
        if (reading is! Map) continue;
        final sensorId = reading['sensor_id']?.toString();
        if (sensorId == null) continue;

        double? asDouble(dynamic v) => v is num ? v.toDouble() : null;
        final x = asDouble(reading['vibration_x']);
        final y = asDouble(reading['vibration_y']);
        final z = asDouble(reading['vibration_z']);

        final value = _extractValue(reading);
        if (value != null) {
          updatedValues[sensorId] = value;

          final list = List<TelemetryReading>.from(
            updatedHistory[sensorId] ?? [],
          );
          list.add(TelemetryReading(value: value, timestamp: now));
          if (list.length > 20) {
            list.removeAt(0);
          }
          updatedHistory[sensorId] = list;
        }

        if (x != null || y != null || z != null) {
          final vibX = x ?? 0.0;
          final vibY = y ?? 0.0;
          final vibZ = z ?? 0.0;
          final vibReading = VibrationReading(
            x: vibX,
            y: vibY,
            z: vibZ,
            timestamp: now,
          );

          updatedLatestVibration[sensorId] = vibReading;

          final list = List<VibrationReading>.from(
            updatedVibrationHistory[sensorId] ?? [],
          );
          list.add(vibReading);
          if (list.length > 20) {
            list.removeAt(0);
          }
          updatedVibrationHistory[sensorId] = list;
        }

        if (reading['plc_status'] != null) {
          plcStatus = reading['plc_status'].toString();
        }
      }

      emit(
        state.copyWith(
          values: updatedValues,
          history: updatedHistory,
          vibrationHistory: updatedVibrationHistory,
          latestVibration: updatedLatestVibration,
          plcStatus: plcStatus,
          isConnected: true,
        ),
      );
    } catch (_) {
      // Malformed message — ignore rather than crash the stream.
    }
  }

  /// Maps a single reading dict to the one number the sensors page displays,
  /// based on the known field names per sensor type.
  double? _extractValue(Map reading) {
    double? asDouble(dynamic v) => v is num ? v.toDouble() : null;

    final temp = asDouble(reading['temperature']);
    if (temp != null) return temp;

    final current = asDouble(reading['current']);
    if (current != null) return current;

    final speed = asDouble(reading['speed_ms']);
    if (speed != null) return speed;

    final x = asDouble(reading['vibration_x']);
    final y = asDouble(reading['vibration_y']);
    final z = asDouble(reading['vibration_z']);

    if (x != null || y != null || z != null) {
      return sqrt(
        (x ?? 0) * (x ?? 0) + (y ?? 0) * (y ?? 0) + (z ?? 0) * (z ?? 0),
      );
    }

    return null;
  }

  void _onDone() {
    // Close code 1008 = policy violation, used by this backend for an
    // expired/invalid session.
    if (_channel?.closeCode == 1008) {
      emit(state.copyWith(isConnected: false, sessionExpired: true));
    } else {
      emit(state.copyWith(isConnected: false));
    }
  }

  void _onError(Object error) {
    emit(state.copyWith(isConnected: false, error: error.toString()));
  }

  void reconnect(String sessionId) {
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    connect(sessionId);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    return super.close();
  }
}
