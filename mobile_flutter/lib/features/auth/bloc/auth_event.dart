import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthRequestOTP extends AuthEvent {
  final String phone;
  const AuthRequestOTP(this.phone);

  @override
  List<Object?> get props => [phone];
}

class AuthVerifyOTP extends AuthEvent {
  final String phone;
  final String otp;
  const AuthVerifyOTP(this.phone, this.otp);

  @override
  List<Object?> get props => [phone, otp];
}

class AuthCheckSession extends AuthEvent {}

class AuthLogout extends AuthEvent {}
