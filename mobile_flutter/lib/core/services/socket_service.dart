import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:saaradhi_go_driver/core/utils/constants.dart';

/// Production WebSocket service based on Django Channels
/// - Connects to Driver Location Consumer (polling, ride requests)
/// - Connects to Trip Status Consumer (during active trip)
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocketChannel? _locationChannel;
  WebSocketChannel? _tripChannel;

  String? _token;
  bool _isLocationConnected = false;
  bool _isTripConnected = false;

  bool get isConnected => _isLocationConnected;

  // ── Callbacks ─────────────────────────────────────────────────────────────
  Function(Map<String, dynamic> rideData)? onRideRequest;
  Function(Map<String, dynamic> tripUpdate)? onTripStatusUpdate;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String error)? onError;

  // ── Setup ─────────────────────────────────────────────────────────────
  void setup({
    String? token,
    Function(Map<String, dynamic>)? onRide,
    Function(Map<String, dynamic>)? onTripUpdate,
    Function()? onConnect,
    Function()? onDisconnect,
    Function(String)? onErr,
  }) {
    _token = token;
    onRideRequest = onRide;
    onTripStatusUpdate = onTripUpdate;
    onConnected = onConnect;
    onDisconnected = onDisconnect;
    onError = onErr;
  }

  // ── Connect Location Consumer ─────────────────────────────────────────────
  void connectLocation(double lat, double lng) {
    if (_token == null) return;
    _disconnectLocation();

    final url = '${AppConstants.wsUrl}/ws/driver/location/?token=$_token&lat=$lat&lng=$lng';
    debugPrint('[Socket] Connecting Location Consumer: $url');

    try {
      _locationChannel = WebSocketChannel.connect(Uri.parse(url));
      _isLocationConnected = true;

      _locationChannel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            final type = data['type'];
            
            if (type == 'connection_established') {
              debugPrint('[Socket] ✅ Location Connected: ${data['message']}');
              onConnected?.call();
            } else if (type == 'location_updated') {
              // Server confirmed location update
            } else if (type == 'ride_request') {
              debugPrint('[Socket] 🚗 New ride request: $data');
              // Map payload to local app expected structure if needed, or pass directly
              // Document structure: trip_id, rider_name, pickup_lat, pickup_lng, destination_lat, destination_lng, pickup_address, destination_address, estimated_fare
              onRideRequest?.call(data);
            }
          } catch (e) {
            debugPrint('[Socket] Decode error: $e');
          }
        },
        onDone: () {
          debugPrint('[Socket] ❌ Location Disconnected');
          _isLocationConnected = false;
          onDisconnected?.call();
        },
        onError: (error) {
          debugPrint('[Socket] ⚠️ Location Error: $error');
          _isLocationConnected = false;
          onError?.call('Location socket error: $error');
        },
      );
    } catch (e) {
      debugPrint('[Socket] ⚠️ Connection Error: $e');
      _isLocationConnected = false;
      onError?.call('Connection error: $e');
    }
  }

  void _disconnectLocation() {
    _locationChannel?.sink.close();
    _locationChannel = null;
    _isLocationConnected = false;
  }

  // ── Send Location Update ─────────────────────────────────────────────────
  void updateLocation(double lat, double lng) {
    if (!_isLocationConnected || _locationChannel == null) return;
    
    final payload = jsonEncode({
      'lat': lat,
      'lng': lng,
    });
    _locationChannel!.sink.add(payload);
  }

  // ── Connect Trip Status Consumer ──────────────────────────────────────────
  void connectTrip(String tripId) {
    if (_token == null) return;
    _disconnectTrip();

    final url = '${AppConstants.wsUrl}/ws/ride/trip/$tripId/?token=$_token';
    debugPrint('[Socket] Connecting Trip Consumer: $url');

    try {
      _tripChannel = WebSocketChannel.connect(Uri.parse(url));
      _isTripConnected = true;

      _tripChannel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            final type = data['type'];
            
            if (type == 'connection_established') {
              debugPrint('[Socket] ✅ Trip Connected: ${data['message']}');
            } else if (type == 'trip_status_update') {
              debugPrint('[Socket] 📋 Trip update: $data');
              onTripStatusUpdate?.call(data);
            }
          } catch (e) {
            debugPrint('[Socket] Trip Decode error: $e');
          }
        },
        onDone: () {
          debugPrint('[Socket] ❌ Trip Disconnected');
          _isTripConnected = false;
        },
        onError: (error) {
          debugPrint('[Socket] ⚠️ Trip Error: $error');
          _isTripConnected = false;
        },
      );
    } catch (e) {
      debugPrint('[Socket] ⚠️ Trip Connection Error: $e');
      _isTripConnected = false;
    }
  }

  void _disconnectTrip() {
    _tripChannel?.sink.close();
    _tripChannel = null;
    _isTripConnected = false;
  }

  // ── Actions (TripStatusConsumer) ──────────────────────────────────────────
  void _sendTripAction(Map<String, dynamic> payload) {
    if (!_isTripConnected || _tripChannel == null) return;
    _tripChannel!.sink.add(jsonEncode(payload));
  }

  void emitAcceptRide() {
    _sendTripAction({'action': 'accept'});
  }

  void emitRejectRide() {
    // In Django Channels docs, reject usually means ignoring it (timeout) 
    // but we can send reject or cancel if the backend supports it.
    _sendTripAction({'action': 'reject'});
  }

  void emitReachedPickup() {
    _sendTripAction({'action': 'reached'});
  }

  void emitStartRide(String otp) {
    _sendTripAction({'action': 'start', 'otp': otp});
  }

  void emitCompleteRide() {
    _sendTripAction({'action': 'complete'});
  }

  void emitCancelRide() {
    _sendTripAction({'action': 'cancel'});
  }

  // ── Driver Status ─────────────────────────────────────────────────────────
  void setDriverStatus(bool isOnline) {
    // Usually managed by connecting/disconnecting the Location Consumer
    // If backend requires an explicit payload over location socket:
    if (_isLocationConnected && _locationChannel != null) {
      // _locationChannel!.sink.add(jsonEncode({'status': isOnline ? 'online' : 'offline'}));
    }
  }

  // ── Disconnect ────────────────────────────────────────────────────────────
  void disconnect() {
    _disconnectLocation();
    _disconnectTrip();
    debugPrint('[Socket] Disconnected cleanly');
  }

  void dispose() {
    disconnect();
  }
}
