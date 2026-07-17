part of 'alert_cubit.dart';

sealed class AlertState extends Equatable {
  const AlertState();

  @override
  List<Object> get props => [];
}

final class AlertInitial extends AlertState {}

final class AlertLoaded extends AlertState {
  final List<Alert> alerts;

  const AlertLoaded(this.alerts);

  @override
  List<Object> get props => [alerts];
}

final class AlertError extends AlertState {
  final String message;

  const AlertError(this.message);

  @override
  List<Object> get props => [message];
}
