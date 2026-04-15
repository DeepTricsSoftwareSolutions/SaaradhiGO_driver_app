import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Production-grade LocationService
/// - On Android/iOS: uses `location` package (real GPS)
/// - On Web/unsupported: uses simulated location for demo mode
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<dynamic>? _subscription;
  Timer? _webSimTimer;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  // Buffers and Queue for smoothing and offline recovery
  final List<({double lat, double lng})> _buffer = [];
  ({double lat, double lng})? _lastLoc;
  final List<Map<String, dynamic>> _offlineQueue = [];

  // Kalman Filter state
  double _kalmanP = 1.0;
  final double _kalmanQ = 0.0001; // Process noise
  final double _kalmanR = 0.01;   // Measurement noise
  double _kalmanK = 0.0;
  ({double lat, double lng})? _kalmanEst;

  // Callbacks
  void Function(double, double)? _onUpdate;
  void Function(String)? _onSpoofing;

  // ─── Start Tracking ────────────────────────────────────────────────────────
  Future<void> startTracking({
    required void Function(double lat, double lng) onUpdate,
    void Function(String reason)? onSpoofing,
  }) async {
    if (_isTracking) return;
    _onUpdate = onUpdate;
    _onSpoofing = onSpoofing;
    _isTracking = true;

    if (kIsWeb) {
      _startWebSimulation();
    } else {
      await _enforcePermissions();
      await _initBackgroundService();
      await _startNativeTracking();
    }
  }

  // ─── Background Service Config (Android) ──────────────────────────────────
  Future<void> _initBackgroundService() async {
    if (kIsWeb) return;
    try {
      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStartBackground,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: 'saaradhi_driver_gps',
          initialNotificationTitle: 'SaaradhiGO Driver',
          initialNotificationContent: 'GPS Streaming Active',
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStartBackground,
        ),
      );
      await service.startService();
    } catch (e) {
      debugPrint('[LocationService] Background service init failed (likely missing native setup): $e');
    }
  }

  // ─── Native Permissions & Hooks ───────────────────────────────────────────
  Future<void> _enforcePermissions() async {
    if (!kIsWeb) {
      // Background GPS Location Permission
      var locStatus = await Permission.locationAlways.request();
      if (!locStatus.isGranted) {
        await Permission.locationWhenInUse.request();
      }
      
      // Battery Optimization Handling
      var batteryStatus = await Permission.ignoreBatteryOptimizations.request();
      if (!batteryStatus.isGranted) {
        debugPrint('[LocationService] Battery optimization still active. This limits background GPS.');
      }
    }
  }

  // ─── Native GPS (mobile only) ──────────────────────────────────────────────
  Future<void> _startNativeTracking() async {
    try {
      if (kIsWeb) {
        _startWebSimulation(); 
        return;
      }

      final status = await Permission.locationAlways.status;
      if (!status.isGranted && !(await Permission.locationWhenInUse.status).isGranted) {
        debugPrint('[LocationService] Location permission denied. Fallback simulation.');
        _startWebSimulation();
        return;
      }

      _subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2, 
        ),
      ).listen((Position position) {
        processNativeLocation(
          position.latitude, 
          position.longitude, 
          isMocked: position.isMocked, 
          accuracy: position.accuracy
        );
      }, onError: (e) {
        debugPrint('[LocationService] Stream error: $e');
      });
      debugPrint('[LocationService] Native GPS stream started.');
    } catch (e) {
      debugPrint('[LocationService] Native GPS error: $e — falling back to simulation');
      _startWebSimulation();
    }
  }

  // ─── Web / Demo Simulation ─────────────────────────────────────────────────
  void _startWebSimulation() {
    debugPrint('[LocationService] 🌐 Web demo mode — simulating GPS');

    // Start at Hitech City, Hyderabad
    double lat = 17.4448;
    double lng = 78.3817;

    _webSimTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      // Simulate slight movement
      lat += (math.Random().nextDouble() - 0.5) * 0.0002;
      lng += (math.Random().nextDouble() - 0.5) * 0.0002;

      _processCoordinates(lat, lng);
    });
  }

  // ─── Process + Validate + Smooth ──────────────────────────────────────────
  void processNativeLocation(double lat, double lng, {bool isMocked = false, double accuracy = 50.0}) {
    if (isMocked) {
      _onSpoofing?.call('Mock location detected');
      return;
    }
    if (accuracy < 1.0) {
      _onSpoofing?.call('Suspiciously high accuracy');
      return;
    }
    _processCoordinates(lat, lng);
  }

  void _processCoordinates(double lat, double lng) {
    if (lat == 0.0 && lng == 0.0) return;

    if (_isImpossibleMovement(lat, lng)) {
      debugPrint('[LocationService] ⚠️ Impossible speed detected');
      return;
    }

    final smoothed = _kalmanFilter(lat, lng);
    _lastLoc = (lat: lat, lng: lng);

    _onUpdate?.call(smoothed.lat, smoothed.lng);
  }

  bool _isImpossibleMovement(double lat, double lng) {
    if (_lastLoc == null) return false;
    final dist = _haversineM(_lastLoc!.lat, _lastLoc!.lng, lat, lng);
    final speedKmh = dist * 3.6 / 3.0; // 3-second interval
    return speedKmh > 250;
  }

  // ─── Kalman Filter Smoothing ──────────────────────────────────────────────
  ({double lat, double lng}) _kalmanFilter(double meaLat, double meaLng) {
    if (_kalmanEst == null) {
      _kalmanEst = (lat: meaLat, lng: meaLng);
      return _kalmanEst!;
    }
    
    // Prediction Update
    _kalmanP = _kalmanP + _kalmanQ;
    
    // Measurement Update
    _kalmanK = _kalmanP / (_kalmanP + _kalmanR);
    final estLat = _kalmanEst!.lat + _kalmanK * (meaLat - _kalmanEst!.lat);
    final estLng = _kalmanEst!.lng + _kalmanK * (meaLng - _kalmanEst!.lng);
    
    _kalmanP = (1 - _kalmanK) * _kalmanP;
    _kalmanEst = (lat: estLat, lng: estLng);
    
    return _kalmanEst!;
  }

  // ─── Offline Queue Syncing ────────────────────────────────────────────────
  Future<void> queueOfflineLocation(double lat, double lng) async {
    _offlineQueue.add({
      'lat': lat,
      'lng': lng,
      'ts': DateTime.now().toIso8601String()
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_gps_queue', jsonEncode(_offlineQueue));
  }

  Future<void> syncOfflineQueue(Future<void> Function(List<Map<String, dynamic>> data) sendToServer) async {
    if (_offlineQueue.isEmpty) return;
    
    try {
      await sendToServer(_offlineQueue);
      _offlineQueue.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('offline_gps_queue');
      debugPrint('[LocationService] Synced offline GPS queue successfully.');
    } catch (_) {
      debugPrint('[LocationService] Offline sync failed, will retry.');
    }
  }

  double _haversineM(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * math.pi / 180;

  // ─── Stop Tracking ─────────────────────────────────────────────────────────
  Future<void> stopTracking() async {
    _isTracking = false;
    _webSimTimer?.cancel();
    _webSimTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    _buffer.clear();
    debugPrint('[LocationService] Stopped');
  }

  ({double lat, double lng})? get lastLocation => _lastLoc;

  void dispose() => stopTracking();
}

// Global hook for flutter_background_service Android isolate
@pragma('vm:entry-point')
void onStartBackground(ServiceInstance service) async {
  // Listen to platform events
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  
  Timer.periodic(const Duration(seconds: 3), (timer) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Fraud Detection: Spoofed GPS Trap
      if (position.isMocked) {
        debugPrint("🚨 FAKE GPS DETECTED! Halting driver coordinates broadcast.");
        // Notify backend about fraud (in a real scenario, use an API endpoint to freeze the account)
        await http.post(
          Uri.parse("${AppConstants.apiUrl}/driver/fraud-report"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "reason": "MOCKED_LOCATION",
            "lat": position.latitude, 
            "lng": position.longitude
          }),
        );
        return; // Halt coordinates broadcast
      }

      Map<String, dynamic> data = {
        "lat": position.latitude,
        "lng": position.longitude,
        "timestamp": DateTime.now().toIso8601String(),
      };

      await sendLocation(data);
    } catch (e) {
      debugPrint("Location error: $e");
    }
  });
}

Future<void> sendLocation(Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> queue = prefs.getStringList("location_queue") ?? [];

  try {
    final response = await http.post(
      Uri.parse("${AppConstants.apiUrl}/driver/location/update/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Send queued data if exists
      for (String item in queue) {
        await http.post(
          Uri.parse("${AppConstants.apiUrl}/driver/location/update/"),
          headers: {"Content-Type": "application/json"},
          body: item,
        );
      }
      await prefs.remove("location_queue");
    } else {
      queue.add(jsonEncode(data));
      await prefs.setStringList("location_queue", queue);
    }
  } catch (e) {
    queue.add(jsonEncode(data));
    await prefs.setStringList("location_queue", queue);
  }
}
