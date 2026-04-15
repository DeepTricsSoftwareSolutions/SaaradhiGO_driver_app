import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../features/ride/ride_provider.dart';
import '../core/theme.dart';
import 'widgets/saaradhi_map.dart';
import 'widgets/driver_button.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _pinError = "";

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _handleStartRide(String rideId) async {
    if (_pinController.text.length != 4) {
      setState(() => _pinError = "Enter 4-digit PIN");
      return;
    }
    final success = await Provider.of<RideProvider>(context, listen: false).verifyPinAndStartRide(_pinController.text);
    if (!success) {
      setState(() => _pinError = "Invalid PIN or too far from pickup");
    }
  }

  void _handleEndRide(String rideId) async {
    await Provider.of<RideProvider>(context, listen: false).completePayment('CASH');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, rideProvider, _) {
        if (rideProvider.currentRide == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final ride = rideProvider.currentRide!;
        final status = rideProvider.status;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Full Screen Map
              const Positioned.fill(
                child: SaaradhiMap(isOnline: true),
              ),

              // Glass HUD Header
              _buildTripHeader(context, status),

              // Dynamic Control Panel
              _buildControlPanel(context, ride, status),
              
              // SOS Overlay (Internal dialog)
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripHeader(BuildContext context, RideStatus status) {
    String label = "NAVIGATING TO PICKUP";
    if (status == RideStatus.inTrip) label = "TRIP IN PROGRESS";
    if (status == RideStatus.completed) label = "TRIP COMPLETED";

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: FadeInDown(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.navigation_rounded, color: AppTheme.primaryGold, size: 18),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, Map<String, dynamic> ride, RideStatus status) {
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
                color: const Color(0xFF0F0F0F).withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rider Info Row
                  Row(
                    children: [
                      _buildRiderAvatar(ride['riderName']),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ride['riderName'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppTheme.primaryGold, size: 14),
                                const SizedBox(width: 4),
                                Text(ride['riderRating']?.toString() ?? "4.5", style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildActionBtn(Icons.call_rounded, AppTheme.successGreen, () => _launchPhone(ride['riderPhone'])),
                      const SizedBox(width: 12),
                      _buildActionBtn(Icons.chat_bubble_rounded, Colors.white, () {}), 
                    ],
                  ),

                  const SizedBox(height: 32),
                  
                  // Status Specific Controls
                  if (status == RideStatus.accepted)
                     _buildPickupControls(context, ride),
                  if (status == RideStatus.inTrip)
                     _buildInTripControls(context, ride),
                  if (status == RideStatus.completed)
                     _buildPaymentControls(context, ride),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickupControls(BuildContext context, Map<String, dynamic> ride) {
    return Column(
      children: [
        _buildLocationLine(Icons.my_location_rounded, AppTheme.successGreen, "PICKUP FROM", ride['pickupAddr']),
        const SizedBox(height: 32),
        const Text(
          "ENTER 4-DIGIT PIN TO START",
          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 4,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primaryGold, letterSpacing: 12),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            hintText: "0 0 0 0",
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        if (_pinError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_pinError, style: const TextStyle(color: AppTheme.errorRed, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
        const SizedBox(height: 24),
        DriverButton(
          onPressed: () => _handleStartRide(ride['id']),
          child: const Text("START TRIP NOW"),
        ),
      ],
    );
  }

  Widget _buildInTripControls(BuildContext context, Map<String, dynamic> ride) {
    return Column(
      children: [
        _buildLocationLine(Icons.location_on_rounded, AppTheme.errorRed, "DROPPING AT", ride['dropAddr']),
        const SizedBox(height: 32),
        SlideActionBtn(
          onSubmit: () => _handleEndRide(ride['id']),
        ),
      ],
    );
  }

  Widget _buildPaymentControls(BuildContext context, Map<String, dynamic> ride) {
    return Column(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 64),
        const SizedBox(height: 16),
        const Text("Arrived at Destination", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("COLLECT CASH", style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.w900, fontSize: 16)),
              Text("₹${ride['fare']}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        DriverButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("BACK TO DASHBOARD"),
        ),
      ],
    );
  }

  Widget _buildLocationLine(IconData icon, Color color, String label, String address) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRiderAvatar(String name) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : "R",
          style: const TextStyle(color: AppTheme.primaryGold, fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _launchPhone(String? phone) async {
    final url = Uri.parse("tel:${phone ?? '9000000000'}");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}

class SlideActionBtn extends StatefulWidget {
  final VoidCallback onSubmit;
  const SlideActionBtn({super.key, required this.onSubmit});
  @override
  State<SlideActionBtn> createState() => _SlideActionBtnState();
}

class _SlideActionBtnState extends State<SlideActionBtn> {
  double _dragRatio = 0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - 64;
        return Container(
          height: 64,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              const Center(
                child: Text(
                  "SLIDE TO END TRIP",
                  style: TextStyle(color: AppTheme.errorRed, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ),
              Positioned(
                left: _dragRatio * maxDrag,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_completed) return;
                    setState(() {
                      _dragRatio += details.delta.dx / maxDrag;
                      _dragRatio = _dragRatio.clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    if (_completed) return;
                    if (_dragRatio > 0.8) {
                      setState(() {
                        _dragRatio = 1.0;
                        _completed = true;
                      });
                      widget.onSubmit();
                    } else {
                      setState(() => _dragRatio = 0.0);
                    }
                  },
                  child: Container(
                    width: 58,
                    height: 58,
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.errorRed,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppTheme.errorRed, blurRadius: 10)],
                    ),
                    child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
