import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:saaradhi_go_driver/features/ride/presentation/providers/ride_provider.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';
import 'package:saaradhi_go_driver/features/ride/presentation/widgets/saaradhi_map.dart';
import 'package:saaradhi_go_driver/core/widgets/driver_button.dart';

class PickupNavigationScreen extends StatefulWidget {
  const PickupNavigationScreen({super.key});

  @override
  State<PickupNavigationScreen> createState() => _PickupNavigationScreenState();
}

class _PickupNavigationScreenState extends State<PickupNavigationScreen> {
  @override
  Widget build(BuildContext context) {
    final rideProvider = context.watch<RideProvider>();
    final ride = rideProvider.currentRide;

    // Safety check
    if (ride == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold)));
    }

    final driverLocation =
        (rideProvider.currentLat != null && rideProvider.currentLng != null)
            ? LatLng(rideProvider.currentLat!, rideProvider.currentLng!)
            : null;

    final etaText = rideProvider.etaMinutes > 0
        ? '${rideProvider.etaMinutes.toStringAsFixed(1)} min • ${rideProvider.distanceKm.toStringAsFixed(1)} km'
        : 'Computing ETA...';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Map Background
          Positioned.fill(
            child: SaaradhiMap(
              isOnline: true,
              driverLocation: driverLocation,
              currentRoute: rideProvider.currentRoute,
            ),
          ),

          // Floating Back Button
          Positioned(
            top: 60,
            left: 20,
            child: FadeIn(
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: AppTheme.primaryGold, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
              ),
            ),
          ),

          // ETA Overlay
          if (rideProvider.etaMinutes > 0)
            Positioned(
              top: 60,
              right: 20,
              child: FadeInDown(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: AppTheme.primaryGold, size: 16),
                      const SizedBox(width: 8),
                      Text(etaText,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212).withValues(alpha: 0.2),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(44)),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 100,
                      offset: const Offset(0, -30),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        height: 5,
                        width: 48,
                        decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(100))),
                    const SizedBox(height: 24),
                    // Passenger Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.primaryGold,
                                    Color(0xFFB8860B)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGold
                                        .withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(22)),
                                child: Center(
                                  child: Text(
                                    (ride['riderName'] as String)
                                        .substring(0, 2)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryGold,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ride['riderName'] ?? 'Passenger',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star,
                                              color: AppTheme.primaryGold,
                                              size: 12),
                                          const SizedBox(width: 4),
                                          Text('${ride['riderRating'] ?? 4.9}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "ECONOMY TRIP",
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Action Buttons
                        Row(
                          children: [
                            _buildCircleBtn(Icons.phone, "CALL", () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Calling passenger...")));
                            }),
                            const SizedBox(width: 12),
                            _buildCircleBtn(Icons.chat_bubble_outline, "CHAT",
                                () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Opening chat...")));
                            }),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Metadata Stripe
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                            horizontal: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_outlined,
                              color: AppTheme.successGreen, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            "IDENTITY CHECKED",
                            style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1),
                          ),
                          const Spacer(),
                          Text(
                            "₹${ride['fare']}",
                            style: const TextStyle(
                                color: AppTheme.primaryGold,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (ride['paymentMode'] ?? 'UPI').toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 8,
                                fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Address Panel
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: const Border(
                            left: BorderSide(
                                color: AppTheme.primaryGold, width: 4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: AppTheme.primaryGold, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "ARRIVING AT PICKUP POINT",
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ride['pickupAddr'] ?? "Unknown Location",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Master Action Button
                    DriverButton(
                      onPressed: () {
                        // Strict Geofence Check
                        bool isArrived = rideProvider.arrivedAtPickup();
                        if (isArrived) {
                          Navigator.pushNamed(context, '/start-ride');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'You are still too far from the pickup location (>30m).'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      backgroundColor: AppTheme.successGreen,
                      height: 80,
                      borderRadius: 24,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("ARRIVED AT PICKUP",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900)),
                          Text(
                            "NOTIFY PASSENGER OF ARRIVAL",
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Icon(icon, color: AppTheme.primaryGold, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1),
        ),
      ],
    );
  }
}
