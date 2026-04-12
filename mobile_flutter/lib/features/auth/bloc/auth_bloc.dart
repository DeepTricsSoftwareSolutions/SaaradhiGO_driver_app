import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthRequestOTP>(_onRequestOTP);
    on<AuthVerifyOTP>(_onVerifyOTP);
    on<AuthCheckSession>(_onCheckSession);
    on<AuthLogout>(_onLogout);
  }

  Future<void> _onRequestOTP(AuthRequestOTP event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await ApiClient().sendOTP(event.phone);
      emit(AuthOTPSent(event.phone));
    } catch (e) {
      emit(AuthError('Failed to send OTP: $e'));
    }
  }

  Future<void> _onVerifyOTP(AuthVerifyOTP event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await ApiClient().verifyOTP(event.phone, event.otp);
      final data = response.data;

      if (data['status'] == 'success') {
        final resData = data['data'];
        final token = resData['token'] ?? resData['access'];
        final userData = Map<String, dynamic>.from(resData['user'] ?? {});
        await _saveSession(token, userData);
        emit(AuthAuthenticated(userData, token));
      } else {
        emit(AuthError(data['message'] ?? 'Verification failed'));
      }
    } on DioException catch (e) {
      emit(AuthError(ApiClient.extractError(e)));
    } catch (e) {
      emit(AuthError('Unknown error occurred: $e'));
    }
  }

  Future<void> _onCheckSession(AuthCheckSession event, Emitter<AuthState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyJwtToken);
      if (token != null) {
        final userData = {
          'id': prefs.getString(AppConstants.keyUserId) ?? 'user-id',
          'driverId': prefs.getString(AppConstants.keyDriverId) ?? 'driver-id',
          'fullName': prefs.getString('driver_name') ?? 'Driver',
          'status': prefs.getString('driver_status') ?? 'PENDING',
        };
        emit(AuthAuthenticated(userData, token));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyJwtToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyDriverId);
    emit(AuthUnauthenticated());
  }

  Future<void> _saveSession(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyJwtToken, token);
    await prefs.setString('driver_status', userData['status'] ?? 'PENDING');
    if (userData['id'] != null) await prefs.setString(AppConstants.keyUserId, userData['id']);
    if (userData['driverId'] != null) await prefs.setString(AppConstants.keyDriverId, userData['driverId']);
    if (userData['fullName'] != null) await prefs.setString('driver_name', userData['fullName']);

    // ─── Post-Auth Sync ──────────────────────────────────────────────────────
    // Note: Registration data is typically held in the AuthProvider/Repository.
    // If registrationData is detected here, we trigger the sync to Django.
    debugPrint('[AuthBloc] 🔄 Session saved. Ready for BABU sync...');
  }
}
