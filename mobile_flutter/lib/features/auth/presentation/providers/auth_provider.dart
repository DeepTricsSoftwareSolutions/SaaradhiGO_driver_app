import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saaradhi_go_driver/core/network/api_client.dart';
import 'package:saaradhi_go_driver/core/utils/constants.dart';
import 'package:dio/dio.dart';

/// Production AuthProvider — backward-compatible with all existing screens.
/// - sendOTP() returns bool (as screens expect), devOtp stored internally
/// - verifyOTP() returns bool
/// - Real API calls with demo fallback when backend is unavailable
class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  bool _hasSeenSplash = false;
  String? _lastError;
  Map<String, dynamic>?
      _registrationData; // Temporary store for pre-auth reg data
  String? _lastDevOtp; // Stores dev OTP hint for display

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null && _hasSeenSplash;
  bool get isLoading => _isLoading;
  bool get hasSeenSplash => _hasSeenSplash;
  String? get lastError => _lastError;
  String? get lastDevOtp => _lastDevOtp;
  Map<String, dynamic>? get registrationData => _registrationData;

  void setRegistrationData(Map<String, dynamic> data) {
    _registrationData = data;
    notifyListeners();
  }

  String? get driverId => _user?['driverId'] as String?;

  void setSplashSeen() {
    _hasSeenSplash = true;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  // ─── Auto-Login from stored session ───────────────────────────────────────
  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));

      if (!prefs.containsKey(AppConstants.keyJwtToken)) return;

      _token = prefs.getString(AppConstants.keyJwtToken);
      final driverId = prefs.getString(AppConstants.keyDriverId);
      final userId = prefs.getString(AppConstants.keyUserId);

      _user = {
        'id': userId ?? 'cached-user',
        'driverId': driverId ?? 'cached-driver',
        'status': prefs.getString('driver_status') ?? 'PENDING',
        'fullName': prefs.getString('driver_name') ?? 'Driver',
      };

      notifyListeners();
      _refreshProfileSilently();
    } catch (_) {
      // Timeout or error — stay on login
    }
  }

  Future<void> _refreshProfileSilently() async {
    try {
      ApiClient().initialize();
      final response = await ApiClient().getProfile();
      final data = response.data;
      // Current Node backend returns:
      // { status:'OK', fullName, driverStatus, rating, ... }
      // Some deployments may return:
      // { status:'success', data:{ user:{full_name}, status } }
      if (data is Map && data['status'] != 'ERR') {
        final resolvedFullName = (data['fullName'] ??
                (data['data'] is Map
                    ? (data['data']['user'] is Map
                        ? data['data']['user']['full_name']
                        : null)
                    : null) ??
                'Driver')
            .toString();

        final resolvedStatus = (data['driverStatus'] ??
                (data['data'] is Map ? data['data']['status'] : null) ??
                _user?['status'] ??
                'PENDING')
            .toString();

        _user = {
          ..._user ?? {},
          'fullName': resolvedFullName,
          'status': resolvedStatus,
          'rating': data['rating'],
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('driver_status', resolvedStatus);
        await prefs.setString('driver_name', resolvedFullName);
        notifyListeners();
      }
    } catch (_) {
      // Silently fail — cached data is used
    }
  }

  // ─── Public method to refresh profile ─────────────────────────────────────
  Future<void> refreshProfile() async {
    await _refreshProfileSilently();
  }

  // ─── Send OTP — returns bool for backward compatibility ───────────────────
  Future<bool> sendOTP(String phone) async {
    _setLoading(true);
    _lastError = null;
    _lastDevOtp = null;

    try {
      final phoneE164 = _toE164(phone);
      final response =
          await ApiClient().requestOtp(phoneNumberE164: phoneE164, role: 'driver');
      final res = response.data;

      if (res is Map && res['status'] == 'success') {
        final data = (res['data'] is Map) ? (res['data'] as Map) : const {};
        _lastDevOtp = data['otp']?.toString(); // may be omitted in production
        _setLoading(false);
        return true;
      }

      _lastError = _extractMessage(res) ?? 'Failed to send OTP';
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('[AUTH] sendOTP failed: $e');
      if (e is DioError) {
        _lastError = ApiClient.extractError(e);
      } else {
        _lastError = 'Failed to send OTP. Please try again.';
      }

      if (AppConstants.allowDemoOtp) {
        debugPrint(
            '[AUTH] allowDemoOtp=true, falling back to DEMO OTP (123456).');
        _lastDevOtp = "123456";
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    }
  }

  // ─── Verify OTP — returns bool ────────────────────────────────────────────
  Future<bool> verifyOTP(String phone, String otp) async {
    _setLoading(true);
    _lastError = null;

    try {
      final phoneE164 = _toE164(phone);
      final response =
          await ApiClient().loginWithOtp(phoneNumberE164: phoneE164, otp: otp);
      final res = response.data;

      if (res is Map && res['status'] == 'success') {
        final data = (res['data'] is Map) ? (res['data'] as Map) : const {};
        final user = (data['user'] is Map) ? Map<String, dynamic>.from(data['user']) : <String, dynamic>{};

        await _handleSuccessfulAuth(
          token: (data['token'] ?? '').toString(),
          refreshToken: data['refresh_token']?.toString(),
          userData: user,
        );
        // Refresh with specific driver profile immediately after login
        await _refreshProfileSilently();

        _setLoading(false);
        return true;
      }

      _lastError = _extractMessage(res) ?? 'Invalid OTP';
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('[AUTH] verifyOTP failed: $e');
      if (e is DioException) {
        _lastError = ApiClient.extractError(e);
      } else {
        _lastError = 'Verification failed. Please try again.';
      }

      if (AppConstants.allowDemoOtp && otp == "123456") {
        debugPrint(
            '[AUTH] allowDemoOtp=true, fast-tracking verifyOTP in DEMO mode.');
        await _handleSuccessfulAuth(
          token: "simulated_jwt_token",
          refreshToken: null,
          userData: {
            'id': 'u_d3m0',
            'driverId': 'd_d3m0',
            'phone_number': _toE164(phone),
            'full_name': 'Demo Driver',
            'status': 'PENDING',
          },
        );
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    }
  }

  Future<void> _handleSuccessfulAuth({
    required String token,
    required String? refreshToken,
    required Map<String, dynamic> userData,
  }) async {
    _token = token;
    _user = {
      'id': (userData['id'] ?? 'user-id').toString(),
      // driverId comes from `/driver/driver/profile/` and is refreshed post-login
      'driverId': userData['driverId']?.toString(),
      'phone': userData['phone_number']?.toString(),
      'fullName': userData['full_name']?.toString() ?? 'Driver',
      'status': userData['status']?.toString() ?? 'PENDING',
    };

    // Auto-trigger sync if we go through the Provider's internal login flow
    await finalizeRegistrationSync();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyJwtToken, token);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await prefs.setString('refresh_token', refreshToken);
      }
      await prefs.setString('driver_status', userData['status'] ?? 'PENDING');
      final uid = userData['id'];
      final did = userData['driverId'];
      if (uid != null) await prefs.setString(AppConstants.keyUserId, uid);
      if (did != null) await prefs.setString(AppConstants.keyDriverId, did);
    } catch (_) {}

    notifyListeners();
  }

  static String _toE164(String input) {
    final v = input.trim();
    if (v.startsWith('+')) return v;
    // Current UI enforces 10-digit Indian numbers. If you change the UI later,
    // update this mapping accordingly.
    return '+91$v';
  }

  static String? _extractMessage(dynamic res) {
    if (res is Map) {
      if (res['message'] != null) return res['message'].toString();
      final data = res['data'];
      if (data is Map && data['message'] != null) return data['message'].toString();
    }
    return null;
  }

  Future<void> finalizeRegistrationSync() async {
    if (_registrationData != null) {
      debugPrint(
          '[AUTH] 🔄 Finalizing registration for BABU. Syncing to backend...');
      try {
        await ApiClient().updateProfile({
          'fullName': _registrationData!['full_name'],
          'vehicleNumber': _registrationData!['vehicle_number'],
          'vehicleType': _registrationData!['vehicle_type'],
          'status': 'PENDING',
        });
        debugPrint('[AUTH] ✅ BABU profile synced successfully!');
      } catch (e) {
        debugPrint('[AUTH] ❌ BABU sync failed: $e');
      }
      _registrationData = null; // Clear after sync attempt
    }
  }

  void updateUserData(Map<String, dynamic> data) {
    _user = {...(_user ?? {}), ...data};
    notifyListeners();
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _token = null;
    _user = null;
    _lastDevOtp = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyJwtToken);
      await prefs.remove(AppConstants.keyUserId);
      await prefs.remove(AppConstants.keyDriverId);
    } catch (_) {}
    notifyListeners();
  }

  // ─── Break Mode ──────────────────────────────────────────────────────────
  Future<bool> toggleBreakMode(bool isOnBreak) async {
    try {
      if (_user != null) {
        _user!['isOnBreak'] = isOnBreak;
        notifyListeners();
      }
      await ApiClient().toggleBreakMode(isOnBreak);
      return true;
    } catch (_) {
      return false;
    }
  }
}
