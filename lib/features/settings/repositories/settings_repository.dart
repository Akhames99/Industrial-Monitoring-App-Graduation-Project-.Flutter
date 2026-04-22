import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/api_exception.dart';
import 'package:app/core/api/api_response_models.dart';
import 'package:flutter/foundation.dart';

class SettingsRepository {
  final ApiClient _apiClient = ApiClient();

  // Get user profile
  Future<UserProfileResponse> getUserProfile() async {
    try {
      final response = await _apiClient.get(Endpoints.userProfile);

      if (response.statusCode == 200 && response.data != null) {
        return UserProfileResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to fetch user profile',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error fetching user profile: $e');
    }
  }

  // Update user profile
  Future<UserProfileResponse> updateUserProfile({
    required String fullName,
    required String role,
    required String username,
  }) async {
    try {
      final request = UpdateProfileRequest(
        fullName: fullName,
        role: role,
        username: username,
      );

      final response = await _apiClient.put(
        Endpoints.updateProfile,
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return UserProfileResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to update user profile',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error updating user profile: $e');
    }
  }

  // Get team members
  Future<TeamMembersListResponse> getTeamMembers() async {
    try {
      final response = await _apiClient.get(Endpoints.teamMembers);

      if (response.statusCode == 200 && response.data != null) {
        return TeamMembersListResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to fetch team members',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error fetching team members: $e');
    }
  }

  // Add team member
  Future<TeamMemberResponse> addTeamMember({
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final request = AddTeamMemberRequest(
        username: username,
        password: password,
        role: role,
      );

      debugPrint('Adding team member: ${request.toJson()}');
      final response = await _apiClient.post(
        Endpoints.addTeamMember,
        data: request.toJson(),
      );

      debugPrint('Add member response status: ${response.statusCode}');
      debugPrint('Add member response data: ${response.data}');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return TeamMemberResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to add team member',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error adding team member: $e');
    }
  }

  // Remove team member
  Future<bool> removeTeamMember(String memberId) async {
    try {
      final endpoint = Endpoints.removeTeamMember.replaceAll('{id}', memberId);

      final response = await _apiClient.delete(endpoint);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error removing team member: $e');
    }
  }

  // Change password
  Future<bool> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      final endpoint = _apiClient.withUserId(Endpoints.changePassword, userId);

      debugPrint('Changing password for user $userId');
      final response = await _apiClient.put(
        endpoint,
        data: {'new_password': newPassword},
      );

      debugPrint('Change password response status: ${response.statusCode}');
      debugPrint('Change password response data: ${response.data}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final message = response.data is Map
            ? (response.data['detail'] ??
                response.data['message'] ??
                'Failed to change password')
            : 'Failed to change password';
        throw ApiException(
          message: message.toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error changing password: $e');
    }
  }

  // Change username
  Future<bool> changeUsername({
    required String userId,
    required String newUsername,
  }) async {
    try {
      final endpoint = _apiClient.withUserId(Endpoints.changeUsername, userId);

      debugPrint('Changing username for user $userId to $newUsername');
      final response = await _apiClient.put(
        endpoint,
        data: {'new_username': newUsername},
      );

      debugPrint('Change username response status: ${response.statusCode}');
      debugPrint('Change username response data: ${response.data}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final message = response.data is Map
            ? (response.data['detail'] ??
                response.data['message'] ??
                'Failed to change username')
            : 'Failed to change username';
        throw ApiException(
          message: message.toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error changing username: $e');
    }
  }

  // Change role
  Future<bool> changeRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      final endpoint = _apiClient.withUserId(Endpoints.editRole, userId);

      debugPrint('Changing role for user $userId to $newRole');
      final response = await _apiClient.put(
        endpoint,
        data: {'new_role': newRole},
      );

      debugPrint('Change role response status: ${response.statusCode}');
      debugPrint('Change role response data: ${response.data}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final message = response.data is Map
            ? (response.data['detail'] ??
                response.data['message'] ??
                'Failed to change role')
            : 'Failed to change role';
        throw ApiException(
          message: message.toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error changing role: $e');
    }
  }

  // Get security settings
  Future<Map<String, dynamic>> getSecuritySettings() async {
    try {
      final response = await _apiClient.get(Endpoints.securitySettings);

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: 'Failed to fetch security settings',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error fetching security settings: $e');
    }
  }
}
