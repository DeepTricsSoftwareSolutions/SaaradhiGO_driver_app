import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthEvent extends AuthEvent {}

class SendOtpEvent extends AuthEvent {
  final String phone;
  const SendOtpEvent(this.phone);

  @override
  List<Object?> get props => [phone];
}

class LoginEvent extends AuthEvent {
  final String phone;
  final String otp;
  const LoginEvent(this.phone, this.otp);

  @override
  List<Object?> get props => [phone, otp];
}

class LogoutEvent extends AuthEvent {}
