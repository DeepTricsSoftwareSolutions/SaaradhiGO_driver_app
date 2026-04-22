import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:saaradhi_go_driver/features/ride/presentation/providers/ride_provider.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';
import 'package:saaradhi_go_driver/features/ride/presentation/widgets/saaradhi_map.dart';
import 'package:saaradhi_go_driver/core/widgets/driver_button.dart';

class LiveTripScreen extends StatefulWidget {
  const LiveTripScreen({super.key});

  @override
  State<LiveTripScreen> createState() => _LiveTripScreenState();
}

class _LiveTripScreenState extends State<LiveTripScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RideProvider>();
    final ride = provider.currentRide;

    if (ride == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)));
    }

    final driverLocation = (provider.currentLat != null && provider.currentLng != null) 
      ? LatLng(provider.currentLat!, provider.currentLng!) 
      : null;

    final distanceStr = provider.distanceKm > 0 ? '\${provider.distanceKm.toStringAsFixed(1)}km' : '...';
    final etaStr = provider.etaMinutes > 0 ? '\${provider.etaMinutes.toStringAsFixed(0)} MIN' : '...';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Map Background Layer
          Positioned.fill(
            child: SaaradhiMap(
              isOnline: true,
              driverLocation: driverLocation,
              currentRoute: provider.currentRoute,
            )
          ),

          // Floating Status Indicator (Top Center)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: FadeInDown(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Pulse(
                        infinite: true,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.3), blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "TRIP ACTIVE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Emergency Action (Top Right)
          Positioned(
            top: 56,
            right: 20,
            child: FadeIn(
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.errorRed.withValues(alpha: 0.2),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.1)),
                  ),
                ),
              ),
            ),
          ),

          // Trip Info Bottom Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111).withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(44)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 80,
                      offset: const Offset(0, -30),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 5, width: 48, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(100))),
                    const SizedBox(height: 24),
                    // Rider info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primaryGold, Color(0xFFB8860B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  (ride['riderName'] as String).substring(0, 2).toUpperCase(), 
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ride['riderName'],
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: AppTheme.successGreen, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${ride['riderRating']} RATING",
                                      style: const TextStyle(color: Color(0x334CAF50), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        _buildFareColumn(ride),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Destination Panel
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: const Border(left: BorderSide(color: AppTheme.primaryGold, width: 4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: AppTheme.primaryGold, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "DROP LOCATION",
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ride['dropAddr'] ?? 'Destination',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(distanceStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                              Text(
                                etaStr,
                                style: TextStyle(color: AppTheme.primaryGold.withValues(alpha: 0.2), fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Support Actions
                    Row(
                      children: [
                        _buildSupportBtn(Icons.phone, "CALL"),
                        const SizedBox(width: 16),
                        _buildSupportBtn(Icons.chat_bubble_outline, "CHAT"),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Master Action Button
                    DriverButton(
                      onPressed: () {
                        provider.arrivedAtDestination();
                        Navigator.pushReplacementNamed(context, '/end-trip');
                      },
                      backgroundColor: AppTheme.successGreen,
                      height: 80,
                      borderRadius: 24,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 28),
                          SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("COMPLETE TRIP", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                              Text(
                                "COLLECT PAYMENT AND END TRIP",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54),
                              ),
                            ],
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

  Widget _buildFareColumn(Map<String, dynamic> ride) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "EST. FARE",
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        Text(
          "₹\${ride['fare']}",
          style: TextStyle(color: AppTheme.successGreen, fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, height: 1),
        ),
      ],
    );
  }

  Widget _buildSupportBtn(IconData icon, String label) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white38, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
