part of 'login_cubit.dart';

sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no action taken yet
final class LoginInitial extends LoginState {
  const LoginInitial();
}

/// Loading state — waiting for login API response
final class LoginLoading extends LoginState {
  const LoginLoading();
}

/// Success state — login was successful
final class LoginSuccess extends LoginState {
  final LoginResponse loginResponse;

  const LoginSuccess({required this.loginResponse});

  @override
  List<Object?> get props => [loginResponse];
}

/// Error state — login failed with a message
final class LoginError extends LoginState {
  final String message;

  const LoginError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Logout success state — user has logged out
final class LogoutSuccess extends LoginState {
  const LogoutSuccess();
}
