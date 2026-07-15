import 'dart:convert';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/api_exception.dart';
import 'package:app/core/api/api_response_models.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  /// Returns [LoginResponse] containing the auth token and user profile.
  /// Throws [ApiException] on failure.
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    final response = await apiClient.post(
      Endpoints.login,
      data: {'username': username, 'password': password},
    );
    debugPrint('=== RAW LOGIN RESPONSE: ${jsonEncode(response.data)}');

    if (response.data is! Map) {
      throw ApiException(
        message: 'Unexpected response format: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final data = response.data as Map<String, dynamic>;

    // Check if it's an ApiResponse wrapper or a flat success object
    final bool success =
        data['success'] as bool? ??
        (data.containsKey('user_id') || data.containsKey('token'));

    if (!success) {
      final errorMessage = _extractErrorFromData(data);
      throw ApiException(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }

    // If it's the expected wrapped format: {success: true, data: {token: ..., user: {...}}}
    if (data.containsKey('data') && data['data'] is Map) {
      final apiResponse = ApiResponse<LoginResponse>.fromJson(
        data,
        (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    }

    // If it's a flat success object: {user_id: ..., username: ..., role: ..., token: ...}
    // We already checked for 'user_id' or 'token' in the success flag check above.
    return LoginResponse.fromJson(data);
  }

  /// Logout the current user.
  /// Clears the auth token from the API client.
  /// Throws [ApiException] on failure.
  Future<void> logout() async {
    try {
      final response = await apiClient.post(Endpoints.logout);

      // We try to parse the response if it's a map
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // If it's a standard ApiResponse wrapper
        if (data.containsKey('success')) {
          final apiResponse = ApiResponse<LogoutResponse>.fromJson(
            data,
            (json) => LogoutResponse.fromJson(json as Map<String, dynamic>),
          );

          if (!apiResponse.success) {
            debugPrint(
              'Logout API returned success=false: ${apiResponse.message}',
            );
          }
        }
      }
    } catch (e) {
      // We log the error but proceed to clear the local token
      debugPrint('Logout API call failed: $e. Proceeding with local logout.');
    } finally {
      // Always clear the stored auth token locally
      await apiClient.clearAuthToken();
    }
  }

  String _extractErrorFromData(dynamic data) {
    if (data is Map) {
      // 1. Check for FastAPI style details (loc: [body, username], msg: "field required")
      if (data.containsKey('detail')) {
        final detail = data['detail'];
        if (detail is String) return detail;
        if (detail is List) {
          return detail
              .map((e) {
                if (e is Map) {
                  final msg = e['msg'] ?? 'Error';
                  final loc = e['loc'] is List ? (e['loc'] as List).last : null;
                  return loc != null ? '$loc: $msg' : msg;
                }
                return e.toString();
              })
              .join(', ');
        }
      }

      // 2. Check for traditional message/error keys
      if (data.containsKey('message')) return data['message'] as String;
      if (data.containsKey('error')) return data['error'] as String;
      if (data.containsKey('errors')) {
        final errors = data['errors'];
        if (errors is List) return errors.join(', ');
        if (errors is String) return errors;
      }

      // 3. Fallback: tell the user what keys were found
      return 'Unexpected API error. Keys: ${data.keys.join(', ')}';
    }
    return 'An unexpected error occurred: ${data.toString()}';
  }
}
