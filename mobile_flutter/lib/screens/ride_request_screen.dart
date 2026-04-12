import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/theme.dart';
import 'widgets/saaradhi_map.dart';
import 'widgets/driver_button.dart';
import 'widgets/bottom_sheet.dart';

class RideRequestScreen extends StatefulWidget {
  final Map<String, dynamic>? ride;
  const RideRequestScreen({super.key, this.ride});

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  int _timer = 15;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timer == 0) {
        timer.cancel();
        _handleReject();
      } else {
        setState(() => _timer--);
      }
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _handleAccept() {
    _countdown?.cancel();
    Navigator.pushReplacementNamed(context, '/pickup-navigation');
  }

  void _handleReject() {
    _countdown?.cancel();
    Navigator.pop(context); // Or pushReplacementNamed('/dashboard')
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Map Background
          const Positioned.fill(child: SaaradhiMap(isOnline: true)),

          // Timer Badge
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: FadeInDown(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.errorRed.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "${_timer}s",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Sheet (Inline implementation for the request details)
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeInUp(
              child: SaaradhiBottomSheet(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "New Ride Request",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                        ),
                        Pulse(
                          infinite: true,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppTheme.successGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildNavPoint(
                      icon: Icons.location_on,
                      color: AppTheme.successGreen,
                      label: "Pickup Location",
                      address: "MG Road, Brigade Road Junction",
                      dist: "2.3 km away",
                    ),
                    _buildDashedLine(),
                    _buildNavPoint(
                      icon: Icons.near_me,
                      color: AppTheme.primaryGold,
                      label: "Drop Location",
                      address: "Koramangala, 5th Block",
                      dist: "8.5 km trip",
                    ),
                    const SizedBox(height: 32),
                    // Earnings Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryGold, Color(0xFFF4D03F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ESTIMATED EARNINGS",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                "₹185",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.payments_outlined, color: Colors.black.withValues(alpha: 0.8), size: 52),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: DriverButton(
                            onPressed: _handleReject,
                            backgroundColor: AppTheme.errorRed,
                            child: const Text("REJECT"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DriverButton(
                            onPressed: _handleAccept,
                            backgroundColor: AppTheme.successGreen,
                            child: const Text("ACCEPT"),
                          ),
                        ),
                      ],
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

  Widget _buildNavPoint({
    required IconData icon,
    required Color color,
    required String label,
    required String address,
    required String dist,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(dist, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashedLine() {
    return Container(
      margin: const EdgeInsets.only(left: 21),
      height: 24,
      width: 1,
      child: ListView.builder(
        itemBuilder: (context, index) => Container(
          height: 4,
          width: 1,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(color: const Color(0xFF94A3B8).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2)),
        ),
        itemCount: 4,
        physics: const NeverScrollableScrollPhysics(),
      ),
    );
  }
}
