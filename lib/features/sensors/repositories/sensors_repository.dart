import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/api_exception.dart';
import 'package:flutter/material.dart';

class SensorModel {
  final String sensorId;
  final String sensorType;
  final double minThreshold;
  final double maxThreshold;
  final String unit;
  final bool isActive;
  final double? currentValue; // from telemetry

  SensorModel({
    required this.sensorId,
    required this.sensorType,
    required this.minThreshold,
    required this.maxThreshold,
    required this.unit,
    required this.isActive,
    this.currentValue,
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      sensorId: json['sensor_id']?.toString() ?? '',
      sensorType: json['sensor_type']?.toString() ?? '',
      minThreshold: (json['min_threshold'] ?? 0).toDouble(),
      maxThreshold: (json['max_threshold'] ?? 100).toDouble(),
      unit: json['unit']?.toString() ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  SensorModel copyWith({
    String? sensorId,
    String? sensorType,
    double? minThreshold,
    double? maxThreshold,
    String? unit,
    bool? isActive,
    double? currentValue,
  }) {
    return SensorModel(
      sensorId: sensorId ?? this.sensorId,
      sensorType: sensorType ?? this.sensorType,
      minThreshold: minThreshold ?? this.minThreshold,
      maxThreshold: maxThreshold ?? this.maxThreshold,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      currentValue: currentValue ?? this.currentValue,
    );
  }
}

class SensorsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<SensorModel>> getSensors() async {
    try {
      final response = await _apiClient.get('/sensors');
      debugPrint('GET /sensors status: ${response.statusCode}');
      debugPrint('GET /sensors body: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data as List<dynamic>;
        return list
            .map((e) => SensorModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          message: 'Failed to fetch sensors',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error fetching sensors: $e');
    }
  }

  Future<SensorModel> addSensor({
    required String sensorId,
    required String sensorType,
    required double minThreshold,
    required double maxThreshold,
    required String unit,
    required bool isActive,
  }) async {
    try {
      final response = await _apiClient.post(
        '/sensors',
        data: {
          'sensor_id': sensorId,
          'sensor_type': sensorType,
          'min_threshold': minThreshold,
          'max_threshold': maxThreshold,
          'unit': unit,
          'is_active': isActive,
        },
      );

      debugPrint('POST /sensors status: ${response.statusCode}');
      debugPrint('POST /sensors body: ${response.data}');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return SensorModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        final message = response.data is Map
            ? (response.data['detail'] ??
                  response.data['message'] ??
                  'Failed to add sensor')
            : 'Failed to add sensor';
        throw ApiException(
          message: message.toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error adding sensor: $e');
    }
  }

  Future<void> updateSensorStatus({
    required String sensorId,
    required bool isActive,
  }) async {
    try {
      final response = await _apiClient.put(
        '/sensors/$sensorId/status',
        queryParameters: {'is_active': isActive},
      );

      debugPrint('PUT /sensors/$sensorId/status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final message = response.data is Map
            ? (response.data['detail'] ??
                  response.data['message'] ??
                  'Failed to update sensor')
            : 'Failed to update sensor';
        throw ApiException(
          message: message.toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error updating sensor: $e');
    }
  }

  Future<Map<String, dynamic>> getTelemetry() async {
    try {
      final response = await _apiClient.get('/telemetry');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
