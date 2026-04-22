import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/api_exception.dart';
import 'package:app/core/api/api_response_models.dart';
import 'package:app/features/auth/repositories/auth_repository.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository authRepository;
  final ApiClient apiClient;

  LoginCubit({required this.authRepository, required this.apiClient})
    : super(const LoginInitial());

  /// Login with email and password
  Future<void> login(String username, String password) async {
    emit(const LoginLoading());

    try {
      final loginResponse = await authRepository.login(
        username: username,
        password: password,
      );

      // Save token for future authenticated requests
      await apiClient.setAuthToken(loginResponse.token);
      debugPrint('=== TOKEN: ${loginResponse.token}');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'saved_user',
        jsonEncode(loginResponse.user.toJson()),
      );

      emit(LoginSuccess(loginResponse: loginResponse));
    } on ApiException catch (e) {
      emit(LoginError(message: e.message));
    } catch (e) {
      emit(LoginError(message: 'An unexpected error occurred: $e'));
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await authRepository.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_user');
      emit(const LogoutSuccess());
      emit(const LoginInitial());
    } on ApiException catch (e) {
      emit(LoginError(message: e.message));
    } catch (e) {
      emit(LoginError(message: 'An unexpected error occurred: $e'));
    }
  }

  /// Update current user information in state and persist to SharedPreferences
  Future<void> updateUserInfo({
    String? username,
    String? fullName,
    String? role,
  }) async {
    final currentState = state;
    if (currentState is LoginSuccess) {
      final updatedUser = currentState.loginResponse.user.copyWith(
        username: username,
        fullName: fullName,
        role: role,
      );

      emit(
        LoginSuccess(
          loginResponse: currentState.loginResponse.copyWith(user: updatedUser),
        ),
      );

      // Persist updated user so tryAutoLogin restores the correct data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_user', jsonEncode(updatedUser.toJson()));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(const LoginInitial());
  }

  /// Call this on app startup to restore session
  Future<void> tryAutoLogin() async {
    emit(const LoginLoading());
    try {
      final token = await apiClient.getStoredToken();
      if (token == null || token.isEmpty) {
        emit(const LoginInitial());
        return;
      }

      // Token exists — restore user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('saved_user');
      if (savedUser == null) {
        emit(const LoginInitial());
        return;
      }

      final user = UserProfileResponse.fromJson(
        jsonDecode(savedUser) as Map<String, dynamic>,
      );
      emit(
        LoginSuccess(
          loginResponse: LoginResponse(token: token, user: user),
        ),
      );
    } catch (e) {
      emit(const LoginInitial());
    }
  }
}
