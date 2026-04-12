import 'package:equatable/equatable.dart';
import '../../ride/ride_provider.dart';

abstract class RideState extends Equatable {
  const RideState();

  @override
  List<Object?> get props => [];
}

class RideInitial extends RideState {}

class RideStateUpdated extends RideState {
  final RideStatus status;
  final Map<String, dynamic>? activeRide;
  final double? currentLat;
  final double? currentLng;
  final String? error;

  const RideStateUpdated({
    required this.status,
    this.activeRide,
    this.currentLat,
    this.currentLng,
    this.error,
  });

  @override
  List<Object?> get props => [status, activeRide, currentLat, currentLng, error];

  RideStateUpdated copyWith({
    RideStatus? status,
    Map<String, dynamic>? activeRide,
    double? currentLat,
    double? currentLng,
    String? error,
  }) {
    return RideStateUpdated(
      status: status ?? this.status,
      activeRide: activeRide ?? this.activeRide,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      error: error,
    );
  }
}
