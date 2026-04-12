import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOTPSent extends AuthState {
  final String phone;
  const AuthOTPSent(this.phone);

  @override
  List<Object?> get props => [phone];
}

class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> user;
  final String token;
  const AuthAuthenticated(this.user, this.token);

  @override
  List<Object?> get props => [user, token];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
