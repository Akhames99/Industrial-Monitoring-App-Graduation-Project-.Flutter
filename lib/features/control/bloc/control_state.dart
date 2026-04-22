part of 'control_bloc.dart';

sealed class ControlState extends Equatable {
  const ControlState();
  
  @override
  List<Object> get props => [];
}

final class ControlInitial extends ControlState {}
