import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'quality_log_event.dart';
part 'quality_log_state.dart';

class QualityLogBloc extends Bloc<QualityLogEvent, QualityLogState> {
  QualityLogBloc() : super(QualityLogInitial()) {
    on<QualityLogEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
