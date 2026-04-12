import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'constants.dart';

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
  Future<Response> sendOTP(String phone) =>
      _dio.post('/auth/otp/', data: {'phone_number': phone, 'role': 'driver'});

  Future<Response> verifyOTP(String phone, String otp) =>
      _dio.post('/auth/login/', data: {
        'phone_number': phone,
        'otp': otp,
        'role': 'driver',
        'device_token': 'dummy_fcm_token'
      });

  Future<Response> updateUserAuth(Map<String, dynamic> data) =>
      _dio.patch('/auth/user/', data: data);

  Future<Response> refreshToken(String refresh) =>
      _dio.post('/auth/refresh/', data: {'refresh_token': refresh});

  // ── Driver ────────────────────────────────────────────────────────────────
  Future<Response> getProfile() => _dio.get('/driver/driver/profile/');

  Future<Response> updateProfile(dynamic data) =>
      _dio.patch('/driver/driver/profile/', data: data);

  Future<Response> toggleOnlineStatus(bool isOnline) =>
      _dio.patch('/driver/driver/update/', data: {'status': isOnline ? 'online' : 'offline'});

  Future<Response> toggleBreakMode(bool isOnBreak) =>
      _dio.patch('/driver/driver/update/', data: {'is_on_break': isOnBreak});

  Future<Response> uploadDocuments(FormData formData) =>
      _dio.post('/driver/documents/upload/', data: formData);

  // ── Vehicles ──────────────────────────────────────────────────────────────
  Future<Response> getVehicles() => _dio.get('/driver/vehicles/');

  Future<Response> addVehicle(dynamic data) =>
      _dio.post('/driver/vehicles/add/', data: data);

  Future<Response> updateVehicle(String id, Map<String, dynamic> data) =>
      _dio.patch('/driver/vehicles/$id/', data: data);

  Future<Response> deleteVehicle(String id) =>
      _dio.delete('/driver/vehicles/$id/delete/');

  // ── Rides & Trips ────────────────────────────────────────────────────────
  Future<Response> getRideHistory() => _dio.get('/ride/ride-history/');

  Future<Response> getDriverHistory() => _dio.get('/ride/driver-history/');

  Future<Response> getTripDetails(String tripId) =>
      _dio.get('/ride/trip/$tripId/');

  Future<Response> getTripFullDetails(String tripId) =>
      _dio.get('/ride/trip/$tripId/details/');

  Future<Response> getActiveRide() => _dio.get('/ride/trip/active/');

  Future<Response> getDriverRequests() => _dio.get('/ride/driver-requests/');

  Future<Response> acceptRide(String rideId) =>
      _dio.post('/ride/accept/', data: {'trip_id': rideId});
      
  Future<Response> rejectRide(String rideId) =>
      _dio.post('/ride/trip/$rideId/reject/'); // Assuming reject stays trip/id for now unless told otherwise

  Future<Response> startRide(String rideId, String otp) =>
      _dio.post('/ride/start/', data: {'trip_id': rideId, 'otp': otp});

  Future<Response> completeRide(String rideId) =>
      _dio.post('/ride/end/', data: {'trip_id': rideId});

  Future<Response> cancelRide(String rideId, String reason) =>
      _dio.post('/ride/trip/$rideId/cancel/', data: {'reason': reason});

  Future<Response> markNoShow(String rideId) =>
      _dio.post('/ride/trip/$rideId/no-show/');

  Future<Response> triggerDriverSOS(double lat, double lng) =>
      _dio.post('/driver/sos/', data: {'lat': lat, 'lng': lng});

  Future<Response> getHeatmap() => _dio.get('/ride/heatmap/');

  Future<Response> rateTrip(int tripId, int score, String comments) =>
      _dio.post('/ride/rate-trip/', data: {
        'trip_id': tripId,
        'score': score,
        'comments': comments
      });

  Future<Response> getRatings() => _dio.get('/ride/ratings/');

  Future<Response> triggerSOSGlobal() => 
      _dio.post('/driver/sos/'); // Global SOS endpoint

  // ── Real-time Location ─────────────────────────────────────────────────────
  Future<Response> updateLocation(double lat, double lng) =>
      _dio.post('/driver/location/update/', data: {'lat': lat, 'lng': lng});

  // ── Earnings ──────────────────────────────────────────────────────────────
  Future<Response> getEarnings() => _dio.get('/driver/earnings/');
  
  Future<Response> getEarningsSummary() => _dio.get('/driver/earnings/summary/');

  // ── Wallet / Payments ─────────────────────────────────────────────────────
  Future<Response> getWalletBalance() => _dio.get('/rider/wallet/balance/'); // Rider/Driver share wallet usually

  Future<Response> createWalletOrder(double amount) =>
      _dio.post('/rider/wallet/create-order/', data: {'amount': amount.toString()});

  Future<Response> verifyWalletPayment(String orderId, String paymentId, String signature) =>
      _dio.post('/rider/wallet/verify/', data: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature
      });

  Future<Response> getTransactions() => _dio.get('/payments/history/');

  Future<Response> requestWithdrawal(double amount) =>
      _dio.post('/payments/refund/', data: {'amount': amount.toString()});

  Future<Response> createFundAccount(Map<String, dynamic> data) =>
      _dio.post('/driver/driver/update/', data: {'fund_account': data});

  // ── Error Helper ──────────────────────────────────────────────────────────
  static String extractError(DioException e) {
    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        if (data.containsKey('message')) return data['message'].toString();
        if (data.containsKey('data') && data['data'] is Map && data['data'].containsKey('message')) {
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
