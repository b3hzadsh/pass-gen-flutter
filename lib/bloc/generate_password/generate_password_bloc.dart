import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'generate_password_event.dart';
part 'generate_password_state.dart';

class PassGenBloc extends Bloc<PassGenEvent, PassGenState> {
  PassGenBloc() : super(PassGenInitial()) {
    on<PassGenEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
