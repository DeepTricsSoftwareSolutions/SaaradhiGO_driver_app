import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:saaradhi_go_driver/core/utils/constants.dart';

/// Production WebSocket service with:
/// - Auto-reconnect with exponential backoff
/// - Driver registration + room joining
/// - Location broadcasting (every 3s)
/// - Ride request/trip status handling
/// - Connection state management
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  String? _driverId;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // ── Callbacks ─────────────────────────────────────────────────────────────
  Function(Map<String, dynamic> rideData)? onRideRequest;
  Function(Map<String, dynamic> tripUpdate)? onTripStatusUpdate;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String error)? onError;

  // ── Connect to Server ─────────────────────────────────────────────────────
  void connect({
    required String driverId,
    String? token,
    Function(Map<String, dynamic>)? onRide,
    Function(Map<String, dynamic>)? onTripUpdate,
    Function()? onConnect,
    Function()? onDisconnect,
    Function(String)? onErr,
  }) {
    _driverId = driverId;
    onRideRequest = onRide;
    onTripStatusUpdate = onTripUpdate;
    onConnected = onConnect;
    onDisconnected = onDisconnect;
    onError = onErr;

    _initSocket(token: token);
  }

  void _initSocket({String? token}) {
    _socket?.disconnect();
    _socket?.dispose();

    _socket = io.io(
      AppConstants.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token ?? ''})
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .setReconnectionAttempts(5)
          .setTimeout(10000)
          .build(),
    );

    // ── Event Listeners ───────────────────────────────────────────────────
    _socket!.onConnect((_) {
      _isConnected = true;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      debugPrint('[Socket] ✅ Connected: ${_socket?.id}');

      // Register driver in server room
      _socket!.emit('register_driver', _driverId);
      onConnected?.call();
    });

    _socket!.onDisconnect((reason) {
      _isConnected = false;
      debugPrint('[Socket] ❌ Disconnected: $reason');
      onDisconnected?.call();

      // Auto-reconnect (unless intentional disconnect)
      if (reason != 'io client disconnect') {
        _scheduleReconnect();
      }
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      debugPrint('[Socket] ⚠️ Connect error: $error');
      onError?.call('Connection error: $error');
      _scheduleReconnect();
    });

    _socket!.onError((error) {
      debugPrint('[Socket] ⚠️ Error: $error');
      onError?.call('Socket error: $error');
    });

    // ── Ride Request ──────────────────────────────────────────────────────
    _socket!.on('new_ride_request', (data) {
      debugPrint('[Socket] 🚗 New ride request: $data');
      final rideData = Map<String, dynamic>.from(data ?? {});
      onRideRequest?.call(rideData);
    });

    // ── Trip Status Updates ───────────────────────────────────────────────
    _socket!.on('trip_status', (data) {
      debugPrint('[Socket] 📋 Trip update: $data');
      final tripData = Map<String, dynamic>.from(data ?? {});
      onTripStatusUpdate?.call(tripData);
    });

    // ── Ride Cancelled by Rider ───────────────────────────────────────────
    _socket!.on('ride_cancelled', (data) {
      debugPrint('[Socket] ❌ Ride cancelled by rider: $data');
      onTripStatusUpdate?.call({'status': 'CANCELLED', ...Map<String, dynamic>.from(data ?? {})});
    });

    _socket!.connect();
  }

  // ── Exponential Backoff Reconnect ─────────────────────────────────────────
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[Socket] Max reconnect attempts reached');
      return;
    }

    final delay = Duration(
      milliseconds: (1000 * (2 << _reconnectAttempts.clamp(0, 7))).clamp(1000, 30000),
    );

    debugPrint('[Socket] Reconnecting in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _initSocket();
    });
  }

  // ── Send Location Update ─────────────────────────────────────────────────
  void updateLocation(double lat, double lng) {
    if (!_isConnected || _driverId == null) return;

    _socket!.emit('update_location', {
      'driverId': _driverId,
      'lat': lat,
      'lng': lng,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ── Send Trip Status Update ───────────────────────────────────────────────
  void sendTripUpdate({required String rideId, required String status, required String riderId}) {
    if (!_isConnected) return;

    _socket!.emit('trip_update', {
      'rideId': rideId,
      'status': status,
      'riderId': riderId,
      'driverId': _driverId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    debugPrint('[Socket] 📤 Trip update sent: $rideId → $status');
  }

  // ── Accept Ride ───────────────────────────────────────────────────────────
  void emitAcceptRide(String rideId) {
    if (!_isConnected) return;
    _socket!.emit('accept_ride', {'rideId': rideId, 'driverId': _driverId});
  }

  // ── Reject Ride ───────────────────────────────────────────────────────────
  void emitRejectRide(String rideId) {
    if (!_isConnected) return;
    _socket!.emit('reject_ride', {'rideId': rideId, 'driverId': _driverId});
  }

  // ── Driver Status ─────────────────────────────────────────────────────────
  void setDriverStatus(bool isOnline) {
    if (!_isConnected) return;
    _socket!.emit('driver_status', {'driverId': _driverId, 'isOnline': isOnline});
  }

  // ── Disconnect ────────────────────────────────────────────────────────────
  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.emit('driver_offline', {'driverId': _driverId});
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    debugPrint('[Socket] Disconnected cleanly');
  }

  void dispose() {
    disconnect();
  }
}
