import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../ride/ride_provider.dart';
import '../../../services/socket_service.dart';
import '../../../services/location_service.dart';
import '../../../services/routing_service.dart';
import '../../../core/api_client.dart';
import 'ride_event.dart';
import 'ride_state.dart';

class RideBloc extends Bloc<RideEvent, RideState> {
  final SocketService _socket = SocketService();
  final LocationService _location = LocationService();
  final RoutingService _routing = RoutingService();

  RideBloc() : super(RideInitial()) {
    on<RideUpdateLocation>(_onUpdateLocation);
    on<RideAcceptRequested>(_onAcceptRide);
    on<RideStartRequested>(_onStartRide);
    on<RideEndRequested>(_onEndRide);
    on<RideStatusSynced>(_onStatusSync);
  }

  Future<void> _onUpdateLocation(RideUpdateLocation event, Emitter<RideState> emit) async {
    final currentState = state;
    if (currentState is RideStateUpdated) {
      emit(currentState.copyWith(currentLat: event.lat, currentLng: event.lng));
      _socket.updateLocation(event.lat, event.lng);
      
      // Update route if in trip
      if (currentState.status == RideStatus.accepted || currentState.status == RideStatus.inTrip) {
        if (currentState.activeRide != null) {
          final destLat = (currentState.status == RideStatus.accepted) 
              ? currentState.activeRide!['pickupLat'] as double 
              : currentState.activeRide!['dropLat'] as double;
          final destLng = (currentState.status == RideStatus.accepted) 
              ? currentState.activeRide!['pickupLng'] as double 
              : currentState.activeRide!['dropLng'] as double;
          
          // Note: Full routing logic with ETA/Distance would be updated here
        }
      }
    } else {
      emit(RideStateUpdated(
        status: RideStatus.idle,
        currentLat: event.lat,
        currentLng: event.lng,
      ));
    }
  }

  Future<void> _onAcceptRide(RideAcceptRequested event, Emitter<RideState> emit) async {
    final currentState = state;
    if (currentState is! RideStateUpdated) return;

    emit(currentState.copyWith(status: RideStatus.accepted)); // Optimistic UI
    try {
      await ApiClient().acceptRide(event.rideId);
      _socket.emitAcceptRide(event.rideId);
    } catch (e) {
      emit(currentState.copyWith(error: 'Failed to accept ride: $e', status: RideStatus.idle));
    }
  }

  Future<void> _onStartRide(RideStartRequested event, Emitter<RideState> emit) async {
    final currentState = state;
    if (currentState is! RideStateUpdated) return;

    try {
      await ApiClient().startRide(event.rideId, event.pin);
      _socket.sendTripUpdate(
        rideId: event.rideId,
        status: 'IN_PROGRESS',
        riderId: currentState.activeRide?['riderId'] ?? 'rider',
      );
      emit(currentState.copyWith(status: RideStatus.inTrip));
    } catch (e) {
      emit(currentState.copyWith(error: 'Failed to start ride: $e'));
    }
  }

  Future<void> _onEndRide(RideEndRequested event, Emitter<RideState> emit) async {
    final currentState = state;
    if (currentState is! RideStateUpdated) return;

    try {
      await ApiClient().completeRide(event.rideId);
      _socket.sendTripUpdate(
        rideId: event.rideId,
        status: 'COMPLETED',
        riderId: currentState.activeRide?['riderId'] ?? 'rider',
      );
      emit(currentState.copyWith(status: RideStatus.completed));
    } catch (e) {
      emit(currentState.copyWith(error: 'Failed to end ride: $e'));
    }
  }

  void _onStatusSync(RideStatusSynced event, Emitter<RideState> emit) {
    if (state is RideStateUpdated) {
      emit((state as RideStateUpdated).copyWith(
        status: event.status,
        activeRide: event.activeRide,
      ));
    } else {
      emit(RideStateUpdated(
        status: event.status,
        activeRide: event.activeRide,
      ));
    }
  }
}
