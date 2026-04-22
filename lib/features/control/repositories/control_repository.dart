import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/api_exception.dart';
import 'package:app/core/api/api_response_models.dart';

class ControlRepository {
  final ApiClient _apiClient = ApiClient();

  // Get current machine status
  Future<MachineStatusResponse> getMachineStatus() async {
    try {
      final response = await _apiClient.get(Endpoints.machineStatus);

      if (response.statusCode == 200 && response.data != null) {
        return MachineStatusResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to fetch machine status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error fetching machine status: $e');
    }
  }

  // Start machine with target speed
  Future<MachineStatusResponse> startMachine(int targetSpeed) async {
    try {
      final request = StartMachineRequest(targetSpeed: targetSpeed);

      final response = await _apiClient.post(
        Endpoints.startMachine,
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return MachineStatusResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to start machine',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error starting machine: $e');
    }
  }

  // Stop machine
  Future<MachineStatusResponse> stopMachine() async {
    try {
      final response = await _apiClient.post(Endpoints.stopMachine);

      if (response.statusCode == 200 && response.data != null) {
        return MachineStatusResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to stop machine',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error stopping machine: $e');
    }
  }

  // Set machine speed
  Future<MachineStatusResponse> setSpeed(int targetSpeed) async {
    try {
      final request = SetSpeedRequest(targetSpeed: targetSpeed);

      final response = await _apiClient.put(
        Endpoints.setSpeed,
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return MachineStatusResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to set speed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error setting speed: $e');
    }
  }
}
