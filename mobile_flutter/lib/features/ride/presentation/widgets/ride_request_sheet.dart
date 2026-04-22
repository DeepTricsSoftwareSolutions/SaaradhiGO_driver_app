import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:saaradhi_go_driver/features/ride/presentation/providers/ride_provider.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';

class RideRequestSheet extends StatefulWidget {
  const RideRequestSheet({super.key});

  @override
  State<RideRequestSheet> createState() => _RideRequestSheetState();
}

class _RideRequestSheetState extends State<RideRequestSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerCtrl;

  @override
  void initState() {
    super.initState();
    _timerCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 30))
          ..forward().whenComplete(() {
            if (mounted) {
              // In production, the backend times out, but we can also trigger a local reject
            }
          });
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, rideProvider, _) {
        if (rideProvider.incomingRequest == null) return const SizedBox();
        final request = rideProvider.incomingRequest!;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F0F).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                              color:
                                  AppTheme.primaryGold.withValues(alpha: 0.3),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryGold.withValues(alpha: 0.05),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress bar at the very top
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: AnimatedBuilder(
                                animation: _timerCtrl,
                                builder: (context, _) =>
                                    LinearProgressIndicator(
                                  value: 1 - _timerCtrl.value,
                                  backgroundColor: Colors.white10,
                                  color: AppTheme.primaryGold,
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Rider Info & Fare
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.person_outline_rounded,
                                          color: AppTheme.primaryGold),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          request['riderName'] ?? 'New Rider',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                color: AppTheme.primaryGold,
                                                size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${request['riderRating'] ?? '5.0'}",
                                              style: const TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("EARNING",
                                        style: TextStyle(
                                            color: Colors.white24,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2)),
                                    Text(
                                      "₹${request['fare']}",
                                      style: const TextStyle(
                                          color: AppTheme.primaryGold,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -1),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Pickup Distance & ETA
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildDistanceInfo(
                                    Icons.location_on_outlined,
                                    "${request['pickupDistance'] ?? '2.3'} km",
                                    "PICKUP DISTANCE",
                                  ),
                                  Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.white10),
                                  _buildDistanceInfo(
                                    Icons.access_time_rounded,
                                    "${request['pickupETA'] ?? '8'} min",
                                    "ESTIMATED TIME",
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Route Details
                            _buildRouteInfo(
                                Icons.trip_origin_rounded,
                                AppTheme.successGreen,
                                "PICKUP",
                                request['pickupAddr'] ?? "Hitech City"),
                            _buildRouteConnector(),
                            _buildRouteInfo(
                                Icons.location_on_rounded,
                                AppTheme.errorRed,
                                "DROP",
                                request['dropAddr'] ?? "Airport"),

                            const SizedBox(height: 32),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: GestureDetector(
                                    onTap: rideProvider.canRejectRide
                                        ? () => context
                                            .read<RideProvider>()
                                            .rejectRide()
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      decoration: BoxDecoration(
                                        color: rideProvider.canRejectRide
                                            ? Colors.white
                                                .withValues(alpha: 0.05)
                                            : Colors.grey
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Center(
                                        child: Text(
                                          rideProvider.canRejectRide
                                              ? "REJECT"
                                              : "${rideProvider.dailyRejections}/${rideProvider.maxDailyRejections}",
                                          style: TextStyle(
                                              color: rideProvider.canRejectRide
                                                  ? Colors.white38
                                                  : Colors.grey,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                              fontSize:
                                                  rideProvider.canRejectRide
                                                      ? 14
                                                      : 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Pulse(
                                    infinite: true,
                                    duration: const Duration(seconds: 2),
                                    child: GestureDetector(
                                      onTap: () async {
                                        final success = await context
                                            .read<RideProvider>()
                                            .acceptRide();
                                        if (success && context.mounted) {
                                          Navigator.pushNamed(
                                              context, '/active-trip');
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 20),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppTheme.primaryGold,
                                              Color(0xFFCCAC00)
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.primaryGold
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 20,
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "ACCEPT RIDE",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRouteInfo(
      IconData icon, Color color, String label, String address) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              const SizedBox(height: 2),
              Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 9),
      height: 20,
      width: 1.5,
      color: Colors.white10,
    );
  }

  Widget _buildDistanceInfo(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryGold, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
              color: Colors.white38,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
