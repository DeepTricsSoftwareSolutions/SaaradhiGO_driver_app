import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../features/auth/auth_provider.dart';
import '../features/ride/ride_provider.dart';
import '../core/theme.dart';
import '../services/location_service.dart';
import 'widgets/glass_card.dart';
import 'widgets/driver_button.dart';
import 'widgets/saaradhi_map.dart';
import 'package:latlong2/latlong.dart';
import 'widgets/ride_request_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _toggleOnline() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final isNowOnline = !rideProvider.isOnline;
    
    if (isNowOnline && !rideProvider.isSocketConnected) {
      rideProvider.initSocket(auth.user?['driverId'] ?? 'demo_driver', token: auth.token);
    }
    
    await rideProvider.setOnlineStatus(isNowOnline);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, RideProvider>(
      builder: (context, authProvider, rideProvider, _) {
        if (authProvider.user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final status = rideProvider.status;
        final user = authProvider.user!;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Background Map
              Positioned.fill(
                child: SaaradhiMap(
                  isOnline: rideProvider.isOnline,
                  driverLocation: (status != RideStatus.idle && rideProvider.currentLat != null) 
                      ? LatLng(rideProvider.currentLat!, rideProvider.currentLng!) 
                      : null,
                    ),
                  ),

                  // HUD (Heads Up Display) Overlay
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          _buildTopHUD(context, user),
                          const SizedBox(height: 16),
                  _buildEarningsCard(context, rideProvider),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Panel
                  _buildBottomPanel(context, rideProvider),

                  // Active Request Overlay
                  if (status == RideStatus.requested)
                    const RideRequestSheet(),
                ],
              ),
              ),
            );
      },
    );
  }

  Widget _buildTopHUD(BuildContext context, Map<String, dynamic> user) {
    return FadeInDown(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile/Menu
          _buildHUDBtn(
            icon: Icons.person_rounded,
            color: AppTheme.primaryGold,
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),

          // Online Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                if (Provider.of<RideProvider>(context).isOnline)
                  BoxShadow(
                    color: AppTheme.successGreen.withValues(alpha: 0.2),
                    blurRadius: 20,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Provider.of<RideProvider>(context).isOnline ? AppTheme.successGreen : Colors.white24,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  (Provider.of<RideProvider>(context).isOnline ? "ONLINE" : "OFFLINE").toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // SOS
          _buildHUDBtn(
            icon: Icons.emergency_rounded,
            color: AppTheme.errorRed,
            onPressed: () => _showSOSDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(BuildContext context, RideProvider rideProvider) {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "TODAY'S REVENUE",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "₹1,250", // Fetch from real state in next step
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text("4.9", style: TextStyle(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text("RATING", style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, RideProvider rideProvider) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: FadeInUp(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A).withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 32),
                  Text(
                    rideProvider.isOnline ? "Searching for rides..." : "Go online to start earnings",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  DriverButton(
                    onPressed: _toggleOnline,
                    backgroundColor: rideProvider.isOnline ? Colors.white.withValues(alpha: 0.05) : AppTheme.successGreen,
                    child: Text(rideProvider.isOnline ? "GO OFFLINE" : "GO ONLINE NOW"),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMiniStat("TRIPS", "12"),
                      Container(width: 1, height: 30, color: Colors.white10),
                      _buildMiniStat("HOURS", "5.4"),
                      Container(width: 1, height: 30, color: Colors.white10),
                      _buildMiniStat("WALLEt", "₹450"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildHUDBtn({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text("EMERGENCY SOS", style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w900)),
          content: const Text("Triggering SOS will instantly alert the control hub and nearby emergency services. Proceed?", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCEL", style: TextStyle(color: Colors.white24)),
            ),
            TextButton(
              onPressed: () {
                // Call Bloc SOS event
                Navigator.pop(ctx);
              },
              child: const Text("CONFIRM SOS", style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
