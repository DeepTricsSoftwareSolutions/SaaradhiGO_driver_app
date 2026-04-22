import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:saaradhi_go_driver/features/auth/presentation/providers/auth_provider.dart';
import 'package:saaradhi_go_driver/features/ride/presentation/providers/ride_provider.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';

import 'package:saaradhi_go_driver/core/widgets/driver_button.dart';
import 'package:saaradhi_go_driver/features/ride/presentation/widgets/saaradhi_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:saaradhi_go_driver/features/ride/presentation/widgets/ride_request_sheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:saaradhi_go_driver/core/network/api_client.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RideProvider>(context, listen: false).fetchEarnings();
    });
  }

  void _toggleOnline() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final isNowOnline = !rideProvider.isOnline;

    // FR-D20: Online Validation - Check requirements before going online
    if (isNowOnline) {
      // 1. Check driver status
      final driverStatus = auth.user?['status'] ?? 'PENDING';
      if (driverStatus != 'APPROVED') {
        _showValidationError(
            'Account not approved. Please complete verification.');
        return;
      }

      // 2. Check GPS/Location permissions and availability
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _showValidationError('Location permission required to go online.');
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          _showValidationError(
              'Location permission permanently denied. Enable in settings.');
          return;
        }

        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _showValidationError(
              'Location services must be enabled to go online.');
          return;
        }

        // Get current position to ensure GPS is working
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10));

        // Update location in ride provider
        rideProvider.updateLocation(position.latitude, position.longitude);
      } catch (e) {
        _showValidationError(
            'Unable to access location. Please check GPS settings.');
        return;
      }

      // 3. Check document verification status
      try {
        final response = await ApiClient().getDocuments();
        if (response.data['status'] == 'OK') {
          final documents = response.data['documents'] as List<dynamic>;

          // Check if all required documents are verified
          bool allDocumentsVerified = true;
          List<String> pendingDocuments = [];

          for (var doc in documents) {
            if (doc['status'] != 'VERIFIED') {
              allDocumentsVerified = false;
              pendingDocuments.add(doc['type']);
            }
          }

          if (!allDocumentsVerified) {
            _showValidationError(
                'Documents pending verification: ${pendingDocuments.join(', ')}');
            return;
          }
        }
      } catch (e) {
        _showValidationError(
            'Unable to verify documents. Please check your connection.');
        return;
      }

      // 4. Check vehicle registration
      final vehicleNumber = auth.user?['vehicleNumber'];
      if (vehicleNumber == null || vehicleNumber.isEmpty) {
        _showValidationError(
            'Vehicle not registered. Please complete vehicle details.');
        return;
      }

      // 5. Check for expired documents (FR-D28)
      try {
        final response = await ApiClient().getDocuments();
        if (response.data['status'] == 'OK') {
          final documents = response.data['documents'] as List<dynamic>;

          bool hasExpiredDocuments = false;
          List<String> expiredDocs = [];

          for (var doc in documents) {
            final expiryDate = doc['expiryDate'];
            if (expiryDate != null) {
              try {
                final expiry = DateTime.parse(expiryDate);
                if (expiry.isBefore(DateTime.now())) {
                  hasExpiredDocuments = true;
                  expiredDocs.add(doc['type']);
                }
              } catch (e) {
                // Invalid date format, skip
              }
            }
          }

          if (hasExpiredDocuments) {
            _showValidationError(
                'Documents expired: ${expiredDocs.join(', ')}. Please renew to continue driving.');
            return;
          }
        }
      } catch (e) {
        _showValidationError(
            'Unable to verify document expiry. Please check your connection.');
        return;
      }
    }

    // All validations passed, proceed with online toggle
    if (isNowOnline && !rideProvider.isSocketConnected) {
      rideProvider.initSocket(auth.user?['driverId'] ?? 'demo_driver',
          token: auth.token);
    }

    await rideProvider.setOnlineStatus(isNowOnline);
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, RideProvider>(
      builder: (context, authProvider, rideProvider, _) {
        if (authProvider.user == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
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
                  driverLocation: (status != RideStatus.idle &&
                          rideProvider.currentLat != null)
                      ? LatLng(
                          rideProvider.currentLat!, rideProvider.currentLng!)
                      : null,
                ),
              ),

              // HUD (Heads Up Display) Overlay
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildTopHUD(context, user),
                    ],
                  ),
                ),
              ),

              // Bottom Action Panel
              _buildBottomPanel(context, rideProvider),

              // Active Request Overlay
              if (status == RideStatus.requested) const RideRequestSheet(),
            ],
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
                    color: Provider.of<RideProvider>(context).isOnline
                        ? AppTheme.successGreen
                        : Colors.white24,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  (Provider.of<RideProvider>(context).isOnline
                          ? "ONLINE"
                          : "OFFLINE")
                      .toUpperCase(),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(40)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 32),
                  Text(
                    rideProvider.isOnline
                        ? "Searching for rides..."
                        : "Go online to start earnings",
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
                    backgroundColor: rideProvider.isOnline
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppTheme.successGreen,
                    child: Text(
                        rideProvider.isOnline ? "GO OFFLINE" : "GO ONLINE NOW"),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMiniStat("TRIPS", "${rideProvider.totalRides}"),
                      Container(width: 1, height: 30, color: Colors.white10),
                      _buildMiniStat("HOURS", "5.4"),
                      Container(width: 1, height: 30, color: Colors.white10),
                      _buildMiniStat(
                          "EARNINGS", "₹${rideProvider.totalEarnings.toInt()}",
                          onTap: () =>
                              Navigator.pushNamed(context, '/earnings')),
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

  Widget _buildMiniStat(String label, String value, {VoidCallback? onTap}) {
    final content = Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: Colors.white24,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }

  Widget _buildHUDBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text("EMERGENCY SOS",
              style: TextStyle(
                  color: AppTheme.errorRed, fontWeight: FontWeight.w900)),
          content: const Text(
              "Triggering SOS will instantly alert the control hub and nearby emergency services. Proceed?",
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text("CANCEL", style: TextStyle(color: Colors.white24)),
            ),
            TextButton(
              onPressed: () {
                // Call Bloc SOS event
                Navigator.pop(ctx);
              },
              child: const Text("CONFIRM SOS",
                  style: TextStyle(
                      color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
