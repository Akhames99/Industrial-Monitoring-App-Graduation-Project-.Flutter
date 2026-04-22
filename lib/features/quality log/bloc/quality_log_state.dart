part of 'quality_log_bloc.dart';

sealed class QualityLogState extends Equatable {
  const QualityLogState();
  
  @override
  List<Object> get props => [];
}

final class QualityLogInitial extends QualityLogState {}
