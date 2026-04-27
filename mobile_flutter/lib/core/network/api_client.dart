import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:saaradhi_go_driver/core/utils/constants.dart';

/// Centralized HTTP client — singleton, auto-initializes on first use.
/// - JWT auto-injection on every request
/// - Auto-retry with exponential backoff (3 attempts)
/// - Demo-safe: all methods work even without a backend
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    _init();
  }

  late final Dio _dio;

  Dio get dio => _dio;

  void initialize() {} // no-op: init happens in constructor

  void _init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // ── JWT Injection + Logging ───────────────────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final prefs = await SharedPreferences.getInstance()
              .timeout(const Duration(seconds: 2));
          final token = prefs.getString(AppConstants.keyJwtToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            debugPrint('[API-REQ] 🚀 ${options.method} ${options.path}');
            debugPrint('[API-REQ] 📦 Body: ${options.data}');
          }
        } catch (_) {}
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('[API-RES] ✅ ${response.requestOptions.method} '
              '${response.requestOptions.path} → ${response.statusCode}');
          debugPrint('[API-RES] 📄 Data: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint('[API-ERR] ❌ ${error.requestOptions.method} '
              '${error.requestOptions.path} → ${error.response?.statusCode}');
          debugPrint('[API-ERR] 📄 Response: ${error.response?.data}');
        }
        handler.next(error);
      },
    ));

    // ── Auto Retry (3 attempts, exponential backoff) ──────────────────────
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      retries: 2,
      retryDelays: const [Duration(seconds: 1), Duration(seconds: 2)],
    ));
  }

  // ── Auth ─────────────────────────────────────────────────────────────────
  Future<Response> requestOtp({
    required String phoneNumberE164,
    String role = 'driver',
  }) =>
      // IMPORTANT: do not prefix with "/" or Dio will drop the "/api" base path
      _dio.post('auth/otp',
          data: {'phone_number': phoneNumberE164, 'role': role});

  Future<Response> loginWithOtp({
    required String phoneNumberE164,
    required String otp,
    String? deviceToken,
  }) =>
      _dio.post('auth/login', data: {
        'phone_number': phoneNumberE164,
        'otp': otp,
        if (deviceToken != null && deviceToken.isNotEmpty)
          'device_token': deviceToken,
      });

  Future<Response> updateUserAuth(Map<String, dynamic> data) =>
      _dio.patch('auth/update', data: data);

  Future<Response> refreshToken(String refresh) =>
      _dio.post('auth/refresh', data: {'refresh_token': refresh});

  // ── Driver ────────────────────────────────────────────────────────────────
  Future<Response> getProfile() => _dio.get('driver/profile');

  Future<Response> updateProfile(dynamic data) =>
      _dio.patch('driver/profile', data: data);

  Future<Response> getDocuments() => _dio.get('driver/documents');

  Future<Response> reportRiderMisconduct(Map<String, dynamic> data) =>
      _dio.post('driver/rider-report', data: data);

  Future<Response> toggleOnlineStatus(bool isOnline) =>
      _dio.patch('driver/status', data: {'isOnline': isOnline});

  Future<Response> toggleBreakMode(bool isOnBreak) =>
      _dio.patch('driver/break', data: {'isOnBreak': isOnBreak});

  Future<Response> uploadDocuments(FormData formData) =>
      _dio.post('driver/documents', data: formData);

  // ── Vehicles ──────────────────────────────────────────────────────────────
  Future<Response> getVehicles() => _dio.get('/driver/vehicles/');

  Future<Response> addVehicle(dynamic data) =>
      _dio.post('/driver/vehicles/add/', data: data);

  Future<Response> updateVehicle(String id, Map<String, dynamic> data) =>
      _dio.patch('/driver/vehicles/$id/', data: data);

  Future<Response> deleteVehicle(String id) =>
      _dio.delete('/driver/vehicles/$id/delete/');

  // ── Rides & Trips ────────────────────────────────────────────────────────
  Future<Response> getRideHistory() => _dio.get('rides/history');

  Future<Response> getActiveRide() => _dio.get('rides/active');

  Future<Response> acceptRide(String rideId) =>
      _dio.post('rides/$rideId/accept');

  Future<Response> rejectRide(String rideId) =>
      _dio.post('rides/$rideId/reject');

  Future<Response> startRide(String rideId, String otp) =>
      _dio.post('rides/$rideId/start', data: {'otp': otp});

  Future<Response> completeRide(String rideId) =>
      _dio.post('rides/$rideId/complete');

  Future<Response> cancelRide(String rideId, String reason) =>
      _dio.post('rides/$rideId/cancel', data: {'reason': reason});

  Future<Response> markNoShow(String rideId) =>
      _dio.post('rides/$rideId/no-show');

  Future<Response> triggerDriverSOSForRide(
          String rideId, double lat, double lng) =>
      _dio.post('rides/$rideId/sos', data: {'lat': lat, 'lng': lng});

  Future<Response> getHeatmap() => _dio.get('rides/heatmap');

  Future<Response> triggerSOSGlobal(double lat, double lng) =>
      _dio.post('driver/sos', data: {'lat': lat, 'lng': lng});

  // ── Real-time Location ─────────────────────────────────────────────────────
  Future<Response> updateLocation(double lat, double lng) =>
      _dio.post('driver/location/update', data: {'lat': lat, 'lng': lng});

  // ── Earnings ──────────────────────────────────────────────────────────────
  Future<Response> getEarnings() => _dio.get('earnings');

  // Backward-compatible alias used by some screens/widgets.
  Future<Response> getEarningsSummary() => getEarnings();

  // ── Wallet / Payments ─────────────────────────────────────────────────────
  Future<Response> getWalletBalance() => _dio.get('wallet/balance');

  Future<Response> getTransactions() => _dio.get('wallet/transactions');

  Future<Response> requestWithdrawal(double amount) =>
      _dio.post('wallet/withdraw', data: {'amount': amount});

  Future<Response> createFundAccount(Map<String, dynamic> data) =>
      _dio.post('wallet/create-fund-account', data: data);

  // ── Legacy compatibility (older UI code) ──────────────────────────────────
  Future<Response> triggerDriverSOS(double lat, double lng) =>
      triggerSOSGlobal(lat, lng);

  Future<Response> getDriverRequests() => _dio.get('rides/requests');

  Future<Response> getDriverHistory() => getRideHistory();

  Future<Response> rateTrip(int tripId, int score, String comments) =>
      _dio.post('rides/$tripId/rate',
          data: {'score': score, 'comments': comments});

  // ── Error Helper ──────────────────────────────────────────────────────────
  static String extractError(DioException e) {
    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        if (data.containsKey('message')) return data['message'].toString();
        if (data.containsKey('data') &&
            data['data'] is Map &&
            data['data'].containsKey('message')) {
          return data['data']['message'].toString();
        }
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your internet.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
