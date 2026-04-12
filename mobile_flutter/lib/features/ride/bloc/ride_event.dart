import 'package:equatable/equatable.dart';
import '../../ride/ride_provider.dart';

abstract class RideEvent extends Equatable {
  const RideEvent();

  @override
  List<Object?> get props => [];
}

class RideUpdateLocation extends RideEvent {
  final double lat;
  final double lng;
  const RideUpdateLocation(this.lat, this.lng);

  @override
  List<Object?> get props => [lat, lng];
}

class RideAcceptRequested extends RideEvent {
  final String rideId;
  const RideAcceptRequested(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class RideStartRequested extends RideEvent {
  final String rideId;
  final String pin;
  const RideStartRequested(this.rideId, this.pin);

  @override
  List<Object?> get props => [rideId, pin];
}

class RideEndRequested extends RideEvent {
  final String rideId;
  const RideEndRequested(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class RideStatusSynced extends RideEvent {
  final RideStatus status;
  final Map<String, dynamic>? activeRide;
  const RideStatusSynced(this.status, {this.activeRide});

  @override
  List<Object?> get props => [status, activeRide];
}
