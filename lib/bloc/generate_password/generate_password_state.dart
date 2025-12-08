part of 'generate_password_bloc.dart';

sealed class PassGenState extends Equatable {
  const PassGenState();
  
  @override
  List<Object> get props => [];
}

final class PassGenInitial extends PassGenState {}
