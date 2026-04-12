import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<CheckAuthEvent>(_onCheckAuth);
    on<SendOtpEvent>(_onSendOtp);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckAuth(CheckAuthEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await _authRepository.getToken();
      if (token != null) {
        emit(AuthAuthenticated(token));
      } else {
        emit(AuthInitial());
      }
    } catch (_) {
      emit(AuthInitial());
    }
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendOtp(event.phone);
      emit(const AuthSuccess('OTP_SENT'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await _authRepository.verifyOtp(event.phone, event.otp);
      emit(AuthAuthenticated(token));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    AuthInitial();
    await _authRepository.logout();
    emit(AuthInitial());
  }
}
