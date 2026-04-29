import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:saaradhi_go_driver/core/services/socket_service.dart';
import 'package:saaradhi_go_driver/core/services/location_service.dart';
import 'package:saaradhi_go_driver/core/services/routing_service.dart';
import 'package:saaradhi_go_driver/core/network/api_client.dart';
import 'package:saaradhi_go_driver/core/utils/constants.dart';

enum RideStatus {
  idle,
  requested,
  accepted,
  atPickup,
  inTrip,
  payment,
  completed
}

/// Production RideProvider with:
/// - Real WebSocket ride requests
/// - Real API calls for ride lifecycle
/// - Live GPS tracking during trips
/// - Live OSRM polyline rendering
/// - Strict 30-meter Geofenced Actions (FR-D22)
/// - Auto-expire ride requests (30s timer)
/// - Edge case handling
class RideProvider extends ChangeNotifier {
  final SocketService _socket = SocketService();
  final LocationService _location = LocationService();
  final RoutingService _routing = RoutingService();

  RideStatus _status = RideStatus.idle;
  Map<String, dynamic>? _currentRide;
  Map<String, dynamic>? _incomingRequest;
  bool _isOnline = false;
  bool _isLoading = false;

  double _etaMinutes = 0;
  double _distanceKm = 0;

  // ─── Earnings Data ─────────────────────────────────────────────────────────
  double _todayEarnings = 0.0;
  final List<double> _weeklyEarnings = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  double _totalEarnings = 0.0;
  int _totalRides = 0;
  double _incentiveBonus = 0.0;
  final List<Map<String, dynamic>> _rideHistory = [];
  final List<Map<String, dynamic>> _payoutHistory = [];
  double _walletBalance = 0.0;

  // ─── Rejection Tracking (FR-D21) ──────────────────────────────────────────
  int _dailyRejections = 0;
  DateTime _rejectionResetDate = DateTime.now();
  static const int MAX_DAILY_REJECTIONS = 5;

  // Routing State
  List<LatLng> _currentRoute = [];

  // Ride request expire timer
  Timer? _rideRequestTimer;
  Timer? _locationUpdateTimer;
  int _rideRequestSecondsLeft = AppConstants.rideRequestTimeoutSeconds;

  // Location tracking
  double? _currentLat;
  double? _currentLng;

  // Getters
  RideStatus get status => _status;
  Map<String, dynamic>? get currentRide => _currentRide;
  Map<String, dynamic>? get incomingRequest => _incomingRequest;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  int get totalRides => _totalRides;
  double get totalEarnings => _totalEarnings;
  double get todayEarnings => _todayEarnings;
  double get incentiveBonus => _incentiveBonus;
  List<Map<String, dynamic>> get rideHistory => _rideHistory;
  List<Map<String, dynamic>> get payoutHistory => _payoutHistory;
  List<double> get weeklyEarnings => _weeklyEarnings;
  int get rideRequestSecondsLeft => _rideRequestSecondsLeft;
  double? get currentLat => _currentLat;
  double? get currentLng => _currentLng;
  bool get isSocketConnected => _socket.isConnected;
  double get walletBalance => _walletBalance;

  List<LatLng> get currentRoute => _currentRoute;
  double get etaMinutes => _etaMinutes;
  double get distanceKm => _distanceKm;

  // ─── Rejection Tracking Getters (FR-D21) ─────────────────────────────────
  int get dailyRejections => _dailyRejections;
  int get maxDailyRejections => MAX_DAILY_REJECTIONS;
  bool get canRejectRide => _dailyRejections < MAX_DAILY_REJECTIONS;

  // ─── Initialize Socket + Location ─────────────────────────────────────────
  void initSocket(String driverId, {String? token}) {
    _socket.setup(
      token: token,
      onRide: _handleNewRideRequest,
      onTripUpdate: _handleTripStatusUpdate,
      onConnect: () {
        debugPrint('[RideProvider] Socket connected - Resyncing State');
        if (_isOnline) {
          _syncActiveTrip();
          _location.syncOfflineQueue((data) async {
            // Emulate sending bulk offline queue to socket or API
            await ApiClient()
                .dio
                .post('/driver/location/bulk', data: {'locations': data});
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
      },
      onDisconnect: () {
        debugPrint('[RideProvider] Socket disconnected');
        WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
      },
    );
  }

  // ─── Go Online / Offline ──────────────────────────────────────────────────
  Future<void> setOnlineStatus(bool online) async {
    _isOnline = online;
    notifyListeners();

    // Sync with server
    try {
      await ApiClient().toggleOnlineStatus(online);
    } catch (_) {}

    _socket.setDriverStatus(online);

    if (online) {
      _startLocationTracking();
    } else {
      await _stopLocationTracking();
    }
  }

  // ─── Location Tracking ────────────────────────────────────────────────────
  Future<void> _startLocationTracking() async {
    await _location.startTracking(
      onUpdate: (lat, lng) {
        if (!_socket.isConnected) {
          _socket.connectLocation(lat, lng);
        } else {
          _socket.updateLocation(lat, lng);
        }
        _currentLat = lat;
        _currentLng = lng;
        notifyListeners(); // Refresh map position
      },
      onSpoofing: (reason) {
        debugPrint('[RideProvider] GPS spoofing detected: $reason');
      },
    );

    // Start periodic 3s update to backend for Django Admin visibility
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isOnline && _currentLat != null && _currentLng != null) {
        ApiClient().updateLocation(_currentLat!, _currentLng!);
      }
    });
  }

  Future<void> _stopLocationTracking() async {
    _locationUpdateTimer?.cancel();
    await _location.stopTracking();
  }

  // ─── Update Location (for validation) ─────────────────────────────────────
  void updateLocation(double lat, double lng) {
    _currentLat = lat;
    _currentLng = lng;
    _socket.updateLocation(lat, lng);
    notifyListeners();
  }

  // ─── Reconnect Recovery ───────────────────────────────────────────────────
  Future<void> _syncActiveTrip() async {
    try {
      final res = await ApiClient().getActiveRide();
      if (res.data != null &&
          (res.data['status'] == 'success' || res.data['status'] == 'OK')) {
        final activeRide = res.data['data']?['ride'] ?? res.data['ride'];
        if (activeRide == null) return;

        _currentRide = activeRide;

        switch (activeRide['status']) {
          case 'REQUESTED':
          case 'ACCEPTED':
            _status = RideStatus.accepted;
            _socket.connectTrip(activeRide['id'].toString());
            break;
          case 'OTP_VERIFIED':
          case 'STARTED':
            _status = RideStatus.inTrip;
            _socket.connectTrip(activeRide['id'].toString());
            break;
          default:
            _currentRide = null;
            _status = RideStatus.idle;
            break;
        }

        // Refetch route
        if (_currentLat != null &&
            _currentLng != null &&
            _currentRide != null) {
          final destLat = (_status == RideStatus.accepted)
              ? _currentRide!['pickupLat']
              : _currentRide!['dropLat'];
          final destLng = (_status == RideStatus.accepted)
              ? _currentRide!['pickupLng']
              : _currentRide!['dropLng'];
          await _fetchRoute(
              LatLng(_currentLat!, _currentLng!), LatLng(destLat, destLng));
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('[RideProvider] Sync Active Trip failed: $e');
    }
  }

  // ─── New Ride Request (from Socket or simulated) ──────────────────────────
  void _handleNewRideRequest(Map<String, dynamic> rideData) {
    debugPrint(
        '===== [RideProvider] NEW REQUEST ===== Status: $_status, isOnline: $_isOnline');

    if (!_isOnline) {
      debugPrint('[RideProvider] Ignored request because not online.');
      return;
    }

    // If we're stuck in 'completed' or 'requested' state, forcefully reset it to idle so they can get rides!
    if (_status == RideStatus.completed || _status == RideStatus.requested) {
      _status = RideStatus.idle;
    }

    if (_status != RideStatus.idle) {
      debugPrint(
          '[RideProvider] Ignored request because currently busy: $_status');
      return;
    }

    _incomingRequest = rideData;
    _status = RideStatus.requested;
    _rideRequestSecondsLeft = AppConstants.rideRequestTimeoutSeconds;
    _startRideRequestTimer();
    notifyListeners();
  }

  void _startRideRequestTimer() {
    _rideRequestTimer?.cancel();
    _rideRequestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_rideRequestSecondsLeft <= 0) {
        timer.cancel();
        _handleRideRequestExpiry();
      } else {
        _rideRequestSecondsLeft--;
        notifyListeners();
      }
    });
  }

  void _handleRideRequestExpiry() {
    if (_status == RideStatus.requested) {
      final expiredRideId = _incomingRequest?['id'];
      _incomingRequest = null;
      _status = RideStatus.idle;
      if (expiredRideId != null) {
        _socket.connectTrip(expiredRideId.toString());
        _socket.emitRejectRide(); // Auto-reject expired
      }
      notifyListeners();
    }
  }

  // ─── Trip Status Updates (from Socket) ───────────────────────────────────
  void _handleTripStatusUpdate(Map<String, dynamic> data) {
    final socketStatus = data['status'] as String?;
    if (socketStatus == 'CANCELLED') {
      _handleRiderCancelled();
    }
  }

  void _handleRiderCancelled() {
    _rideRequestTimer?.cancel();
    _currentRide = null;
    _incomingRequest = null;
    _currentRoute = [];
    _status = RideStatus.idle;
    notifyListeners();
  }

  // ─── Accept Ride ─────────────────────────────────────────────────────────
  Future<bool> acceptRide() async {
    if (_incomingRequest == null) return false;

    _rideRequestTimer?.cancel();
    _isLoading = true;
    notifyListeners();

    final rideId = _incomingRequest!['id'] as String;

    try {
      _socket.connectTrip(rideId);
      // Small delay to ensure websocket connection is established before emitting
      await Future.delayed(const Duration(milliseconds: 500));
      _socket.emitAcceptRide();
    } catch (e) {
      debugPrint('[RideProvider] ❌ Accept failed: $e');
      _isLoading = false;
      notifyListeners();
      return false; // Fail
    }

    _currentRide = _incomingRequest;
    _incomingRequest = null;
    _status = RideStatus.accepted;

    // Fetch Route to Pickup
    if (_currentLat != null && _currentLng != null) {
      final pickupLat = _currentRide!['pickupLat'] as double;
      final pickupLng = _currentRide!['pickupLng'] as double;
      await _fetchRoute(
          LatLng(_currentLat!, _currentLng!), LatLng(pickupLat, pickupLng));
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ─── Fetch Route ──────────────────────────────────────────────────────────
  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    final routeData = await _routing.getRoute(start: start, end: end);
    if (routeData != null) {
      _currentRoute = routeData['polyline'];
      _distanceKm = routeData['distanceMeters'] / 1000.0;
      _etaMinutes = routeData['durationSeconds'] / 60.0;
      notifyListeners();
    }
  }

  // ─── Reject Ride ──────────────────────────────────────────────────────────
  Future<void> rejectRide() async {
    // FR-D21: Check daily rejection limit
    if (!canRejectRide) {
      debugPrint('[RideProvider] Daily rejection limit reached');
      return; // Silently fail - UI should prevent this
    }

    _rideRequestTimer?.cancel();
    final rideId = _incomingRequest?['id']?.toString();
    if (rideId != null) {
      _socket.connectTrip(rideId);
      _socket.emitRejectRide();
    }
    _incomingRequest = null;
    _status = RideStatus.idle;

    // Track rejection
    _incrementDailyRejections();

    notifyListeners();
  }

  // ─── Rejection Tracking Methods ───────────────────────────────────────────
  void _incrementDailyRejections() {
    _checkRejectionReset();
    _dailyRejections++;
    debugPrint(
        '[RideProvider] Daily rejections: $_dailyRejections/$MAX_DAILY_REJECTIONS');
  }

  void _checkRejectionReset() {
    final now = DateTime.now();
    if (now.day != _rejectionResetDate.day ||
        now.month != _rejectionResetDate.month ||
        now.year != _rejectionResetDate.year) {
      _dailyRejections = 0;
      _rejectionResetDate = now;
      debugPrint('[RideProvider] Daily rejections reset to 0');
    }
  }

  // ─── Geofenced Distance Checker ──────────────────────────────────────────
  bool _isWithinGeofence(double targetLat, double targetLng,
      {double thresholdMeters = 30}) {
    if (_currentLat == null || _currentLng == null) return false;
    const distance = Distance();
    final meterDistance = distance.as(
      LengthUnit.Meter,
      LatLng(_currentLat!, _currentLng!),
      LatLng(targetLat, targetLng),
    );
    debugPrint('[RideProvider] Distance to target: \$meterDistance meters');
    return meterDistance <= thresholdMeters;
  }

  // ─── Arrived at Pickup ────────────────────────────────────────────────────
  bool arrivedAtPickup() {
    if (_currentRide == null) return false;

    final pickupLat = _currentRide!['pickupLat'] as double;
    final pickupLng = _currentRide!['pickupLng'] as double;

    if (!_isWithinGeofence(pickupLat, pickupLng)) {
      // Driver too far away, deny arrival
      debugPrint(
          '[RideProvider] Geofence denied: Too far from pickup location');
      return false;
    }

    _status = RideStatus.atPickup;
    _socket.emitReachedPickup();
    notifyListeners();
    return true;
  }

  // ─── Verify PIN and Start Ride ────────────────────────────────────────────
  Future<bool> verifyPinAndStartRide(String enteredPin) async {
    final pickupLat = _currentRide!['pickupLat'] as double;
    final pickupLng = _currentRide!['pickupLng'] as double;

    if (!_isWithinGeofence(pickupLat, pickupLng)) {
      debugPrint(
          '[RideProvider] Geofence denied: Cannot start trip away from pickup');
      return false;
    }

    final correctPin = _currentRide?['pin']?.toString() ?? '0000';
    if (enteredPin != correctPin) return false;

    _isLoading = true;
    notifyListeners();

    try {
      _socket.emitStartRide(enteredPin);
    } catch (e) {
      debugPrint('[RideProvider] ❌ Start ride failed: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _status = RideStatus.inTrip;

    // Now fetch route to Destination
    final dropLat = _currentRide!['dropLat'] as double;
    final dropLng = _currentRide!['dropLng'] as double;
    if (_currentLat != null && _currentLng != null) {
      await _fetchRoute(
          LatLng(_currentLat!, _currentLng!), LatLng(dropLat, dropLng));
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ─── Legacy PIN verifier (kept for UI backward compat) ───────────────────
  bool verifyPin(String enteredPin) {
    return false; // Deprecated by verifyPinAndStartRide
  }

  // ─── Arrived at Destination ───────────────────────────────────────────────
  void arrivedAtDestination() {
    _status = RideStatus.payment;
    notifyListeners();
  }

  // ─── Complete Payment + Finish Trip ──────────────────────────────────────
  Future<void> completePayment(String paymentMode) async {
    if (_currentRide == null) return;

    final fare = (_currentRide!['fare'] as num).toDouble();

    try {
      _socket.emitCompleteRide();
    } catch (e) {
      debugPrint('[RideProvider] ❌ Complete ride failed: $e');
    }

    // Update local stats
    _totalRides++;
    _totalEarnings += fare;
    _todayEarnings += fare;
    _weeklyEarnings[_weeklyEarnings.length - 1] += fare;
    _rideHistory.insert(0, {
      'from': _currentRide!['pickupAddr'],
      'to': _currentRide!['dropAddr'],
      'fare': fare.toInt(),
      'date': 'Today',
      'payment': paymentMode,
    });

    _currentRide = null;
    _status = RideStatus.completed;
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      _status = RideStatus.idle;
      notifyListeners();
    });
  }

  // ─── Fetch Earnings (API) ─────────────────────────────────────────────────
  Future<void> fetchEarnings() async {
    try {
      final response = await ApiClient().getEarningsSummary();
      final data = response.data;
      if (data == null) return;

      final status = data['status']?.toString().toLowerCase();
      if (status == 'success' || status == 'ok') {
        final earningsData = data['data'] ?? data;

        _todayEarnings =
            double.tryParse(earningsData['today_earned']?.toString() ?? '0') ??
                0.0;
        _totalEarnings = double.tryParse(
                earningsData['total_earned']?.toString() ??
                    earningsData['totalEarnings']?.toString() ??
                    '0') ??
            0.0;
        _totalRides = int.tryParse(earningsData['total_trips']?.toString() ??
                earningsData['totalTrips']?.toString() ??
                '0') ??
            0;
        _incentiveBonus = double.tryParse(
                earningsData['incentive_bonus']?.toString() ??
                    earningsData['incentiveBonus']?.toString() ??
                    '0') ??
            0.0;

        final weeklyPayload =
            earningsData['weekly_earnings'] ?? earningsData['weeklyEarnings'];

        if (weeklyPayload is List) {
          final rawWeekly = List.from(weeklyPayload);
          for (var i = 0; i < _weeklyEarnings.length; i++) {
            _weeklyEarnings[i] = i < rawWeekly.length
                ? double.tryParse(rawWeekly[i]?.toString() ?? '0') ?? 0.0
                : 0.0;
          }
        } else if (weeklyPayload is Map) {
          final rawWeekly = Map<String, dynamic>.from(weeklyPayload);
          const keys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
          const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
          for (var i = 0; i < _weeklyEarnings.length; i++) {
            _weeklyEarnings[i] = double.tryParse(
                  rawWeekly[keys[i]]?.toString() ??
                      rawWeekly[labels[i]]?.toString() ??
                      '0',
                ) ??
                0.0;
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('[RideProvider] fetchEarnings fail: $e');
    }
  }

  // ─── Cancel / No-Show ────────────────────────────────────────────────────
  Future<void> cancelActiveRide(String reason) async {
    if (_currentRide == null) return;
    try {
      _socket.emitCancelRide();

      _status = RideStatus.idle;
      _currentRide = null;
      _currentRoute = [];
      notifyListeners();
    } catch (e) {
      debugPrint('[RideProvider] cancelActiveRide error: $e');
    }
  }

  // ─── SOS Trigger ──────────────────────────────────────────────────────────
  Future<void> triggerSOSGlobal() async {
    try {
      await ApiClient()
          .triggerDriverSOS(_currentLat ?? 0.0, _currentLng ?? 0.0);
    } catch (_) {
      debugPrint('[RideProvider] SOS API Failed');
    }
  }

  Future<void> markNoShow() async {
    if (_currentRide == null) return;
    try {
      final res = await ApiClient().markNoShow(_currentRide!['id']);

      final comp = res.data['compensationAmount'] ?? 0;
      if (comp > 0) {
        _todayEarnings += comp;
        _totalEarnings += comp;
      }

      _status = RideStatus.idle;
      _currentRide = null;
      _currentRoute = [];
      notifyListeners();
    } catch (e) {
      debugPrint('[RideProvider] markNoShow error: $e');
    }
  }

  // ─── Report Rider Misconduct (FR-D23) ─────────────────────────────────────
  Future<bool> reportRiderMisconduct(
      String reason, String description, String severity) async {
    if (_currentRide == null) return false;

    try {
      final response = await ApiClient().reportRiderMisconduct({
        'rideId': _currentRide!['id'],
        'reason': reason,
        'description': description,
        'severity': severity,
        'lat': _currentLat,
        'lng': _currentLng,
      });

      if (response.data['status'] == 'OK') {
        debugPrint('[RideProvider] Rider misconduct reported successfully');
        return true;
      }
    } catch (e) {
      debugPrint('[RideProvider] Report rider misconduct error: $e');
    }
    return false;
  }

  // ─── Request Withdrawal ──────────────────────────────────────────────────
  Future<void> requestWithdrawal(double amount) async {
    try {
      await ApiClient().requestWithdrawal(amount);
      _payoutHistory.insert(0, {
        'date': 'Just Now',
        'payment': 'Bank Transfer',
        'fare': '-$amount',
        'status': 'Processing',
      });
      _totalEarnings -= amount;
      _walletBalance -= amount;
      notifyListeners();
    } catch (e) {
      debugPrint('[RideProvider] requestWithdrawal fail: $e');
    }
  }

  // ─── Fetch Wallet Balance ──────────────────────────────────────────────────
  Future<void> fetchWalletBalance() async {
    try {
      final response = await ApiClient().getWalletBalance();
      final data = response.data;
      if (data != null && data['status'] == 'success') {
        _walletBalance = double.tryParse(data['data']?['balance']?.toString() ?? '0') ?? 0.0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[RideProvider] fetchWalletBalance error: $e');
    }
  }

  // ─── Fetch Real Ride Requests (Backend) ───────────────────────────────────
  Future<void> fetchDriverRequests() async {
    try {
      final response = await ApiClient().getDriverRequests();
      final data = response.data;
      if (data != null && data['status'] == 'success') {
        final requestsList = data['data']?['requests'] as List?;
        if (requestsList != null && requestsList.isNotEmpty) {
          // Take the most recent/first request and show it
          _handleNewRideRequest(requestsList.first as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('[RideProvider] fetchDriverRequests failed: $e');
    }
  }

  // ─── Load Ride History from API ───────────────────────────────────────────
  Future<void> loadRideHistory() async {
    try {
      final response = await ApiClient().getDriverHistory();
      if (response.data['status'] == 'success') {
        final history = response.data['data']['results'] as List?;
        if (history != null) {
          _rideHistory.clear();
          _rideHistory.addAll(history.map((r) => {
                'from': r['pickup_addr'] ?? 'Unknown',
                'to': r['drop_addr'] ?? 'Unknown',
                'fare': double.tryParse(r['estimated_fare']?.toString() ?? '0')
                        ?.toInt() ??
                    0,
                'date':
                    r['created_at']?.toString().substring(0, 10) ?? 'Unknown',
                'payment': r['payment_mode'] ?? 'UPI',
              }));
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  // ─── Load Payout History from API ──────────────────────────────────────────
  Future<void> loadTransactions() async {
    try {
      // User prompt says wallet balance is /payments/history/ which is fetched here potentially depending on ApiClient method
      // Check ApiClient().getTransactions(); wait I need to make sure this is mapped.
      final response = await ApiClient().getTransactions();
      if (response.data['status'] == 'success') {
        final history = response.data['data']?['transactions'] as List?;
        if (history != null) {
          _payoutHistory.clear();
          _payoutHistory.addAll(history.map((t) => {
                'date':
                    t['created_at']?.toString().substring(0, 10) ?? 'Unknown',
                'payment': t['method'] ?? 'Bank Transfer',
                'fare': (t['amount'] as num?)?.toString() ?? '0',
                'status': t['status'] ?? 'Processing',
              }));
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _rideRequestTimer?.cancel();
    _socket.disconnect();
    _location.stopTracking();
    super.dispose();
  }
}
