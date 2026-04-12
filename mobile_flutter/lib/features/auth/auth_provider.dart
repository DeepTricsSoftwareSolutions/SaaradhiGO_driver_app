import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

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
  Map<String, dynamic>? _registrationData; // Temporary store for pre-auth reg data
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
      if (response.data['status'] == 'success') {
        final profileData = response.data['data'];
        final userData = profileData['user'] ?? {};
        
        _user = {
          ..._user ?? {},
          'fullName': userData['full_name'] ?? 'Driver',
          'status': profileData['status'] ?? 'PENDING',
          'rating': profileData['ratings'],
        };
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('driver_status', profileData['status'] ?? 'PENDING');
        if (userData['full_name'] != null) {
          await prefs.setString('driver_name', userData['full_name']);
        }
        notifyListeners();
      }
    } catch (_) {
      // Silently fail — cached data is used
    }
  }

  // ─── Send OTP — returns bool for backward compatibility ───────────────────
  Future<bool> sendOTP(String phone) async {
    _setLoading(true);
    _lastError = null;
    _lastDevOtp = null;

    try {
      final response = await ApiClient().sendOTP(phone);
      final data = response.data;
      
      if (data['status'] == 'success') {
        _lastDevOtp = data['data']?['otp']?.toString();
        _setLoading(false);
        return true;
      }
      
      _lastError = data['message'] ?? 'Failed to send OTP';
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _lastError = ApiClient.extractError(e);
      _setLoading(false);
      return false;
    } catch (_) {
      _lastError = 'Unknown error occurred.';
      _setLoading(false);
      return false;
    }
  }

  // ─── Verify OTP — returns bool ────────────────────────────────────────────
  Future<bool> verifyOTP(String phone, String otp) async {
    _setLoading(true);
    _lastError = null;

    try {
      final response = await ApiClient().verifyOTP(phone, otp);
      final data = response.data;

      if (data['status'] == 'success') {
        final resData = data['data'];
        await _handleSuccessfulAuth(
          token: resData['token'] ?? resData['access'],
          userData: Map<String, dynamic>.from(resData['user'] ?? {}),
        );
        // Refresh with specific driver profile immediately after login
        await _refreshProfileSilently();
        
        _setLoading(false);
        return true;
      }

      _lastError = data['message'] ?? 'Verification failed';
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _lastError = ApiClient.extractError(e);
      _setLoading(false);
      return false;
    } catch (_) {
      _lastError = 'Unknown error occurred.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> _handleSuccessfulAuth({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    _token = token;
    _user = {
      'id': userData['id'] ?? 'user-id',
      'driverId': userData['driverId'] ?? 'driver-id',
      'phone': userData['phone'],
      'fullName': userData['fullName'] ?? 'Driver',
      'status': userData['status'] ?? 'PENDING',
    };

  Future<void> _handleSuccessfulAuth({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    _token = token;
    _user = {
      'id': userData['id'] ?? 'user-id',
      'driverId': userData['driverId'] ?? 'driver-id',
      'phone': userData['phone'],
      'fullName': userData['fullName'] ?? 'Driver',
      'status': userData['status'] ?? 'PENDING',
    };

    // Auto-trigger sync if we go through the Provider's internal login flow
    await finalizeRegistrationSync();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyJwtToken, token);
      await prefs.setString('driver_status', userData['status'] ?? 'PENDING');
      final uid = userData['id'];
      final did = userData['driverId'];
      if (uid != null) await prefs.setString(AppConstants.keyUserId, uid);
      if (did != null) await prefs.setString(AppConstants.keyDriverId, did);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> finalizeRegistrationSync() async {
    if (_registrationData != null) {
      debugPrint('[AUTH] 🔄 Finalizing registration for BABU. Syncing to Django...');
      try {
        await ApiClient().updateProfile({
          'full_name': _registrationData!['full_name'],
          'vehicle_number': _registrationData!['vehicle_number'],
          'vehicle_type': _registrationData!['vehicle_type'],
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
