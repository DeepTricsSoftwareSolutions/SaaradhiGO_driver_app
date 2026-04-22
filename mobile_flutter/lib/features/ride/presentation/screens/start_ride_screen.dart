import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:saaradhi_go_driver/features/ride/presentation/providers/ride_provider.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';
import 'package:saaradhi_go_driver/features/ride/presentation/widgets/saaradhi_map.dart';
import 'package:saaradhi_go_driver/core/widgets/driver_button.dart';
import 'package:saaradhi_go_driver/core/widgets/glass_card.dart';

class StartRideScreen extends StatefulWidget {
  const StartRideScreen({super.key});

  @override
  State<StartRideScreen> createState() => _StartRideScreenState();
}

class _StartRideScreenState extends State<StartRideScreen> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _waitTimer;
  int _waitSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startWaitTimer();
  }

  void _startWaitTimer() {
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _waitSeconds++;
      });
    });
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleStartTrip(RideProvider provider) async {
    final success = await provider.verifyPinAndStartRide(_otpController.text);
    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/live-trip');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid PIN or too far from pickup location."),
          backgroundColor: Colors.red,
        ),
      );
      _otpController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RideProvider>();
    final ride = provider.currentRide;

    if (ride == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Blurred Map Background
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.4,
              child: SaaradhiMap(isOnline: true),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Header
                  FadeIn(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: AppTheme.primaryGold, size: 24),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _buildProgressDot(AppTheme.successGreen),
                            const SizedBox(width: 8),
                            _buildProgressDot(AppTheme.primaryGold),
                            const SizedBox(width: 8),
                            _buildProgressDot(Colors.white10),
                          ],
                        ),
                        const SizedBox(width: 56),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rider Summary
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primaryGold,
                                      Color(0xFFB8860B)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                      (ride['riderName'] as String)
                                          .substring(0, 2)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ride['riderName'],
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successGreen
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star,
                                            color: AppTheme.successGreen,
                                            size: 12),
                                        const SizedBox(width: 4),
                                        Text("${ride['riderRating']} RATING",
                                            style: const TextStyle(
                                                color: AppTheme.successGreen,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildQuickInfo(
                                  Icons.directions_car_outlined, "Economy"),
                              _buildQuickInfo(
                                  Icons.account_balance_wallet_outlined,
                                  "${ride['paymentMode']} Payment"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Wait Timer / No-Show Handling
                  if (_waitSeconds < 300)
                    Center(
                      child: Text(
                        "Waiting for rider... ${(_waitSeconds ~/ 60).toString().padLeft(2, '0')}:${(_waitSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    )
                  else
                    FadeIn(
                      child: Column(
                        children: [
                          const Text("5 Minutes Passed. Rider not here?",
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: DriverButton(
                                  onPressed: () async {
                                    await provider.markNoShow();
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  },
                                  backgroundColor:
                                      Colors.red.withValues(alpha: 0.2),
                                  child: const Text("MARK NO-SHOW",
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DriverButton(
                                  onPressed: () =>
                                      _showReportRiderDialog(context, provider),
                                  backgroundColor:
                                      Colors.orange.withValues(alpha: 0.2),
                                  child: const Text("REPORT RIDER",
                                      style: TextStyle(
                                          color: Colors.orange, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // OTP Terminal
                  Expanded(
                    child: FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(44),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "VERIFY OTP",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Enter the 4-digit code from the rider",
                              style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 48),
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 16),
                              onChanged: (v) => setState(() {}),
                              decoration: InputDecoration(
                                counterText: "",
                                hintText: "0 0 0 0",
                                hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    letterSpacing: 16),
                                fillColor: Colors.black,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(32)),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.verified_user_outlined,
                                          color: AppTheme.primaryGold,
                                          size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        "SAFE RIDE",
                                        style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "Test OTP: ${ride['pin'] ?? '1111'}",
                                    style: const TextStyle(
                                        color: Colors.white24,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            DriverButton(
                              onPressed: _otpController.text.length == 4 &&
                                      !provider.isLoading
                                  ? () => _handleStartTrip(provider)
                                  : null,
                              backgroundColor: AppTheme.successGreen,
                              height: 80,
                              child: provider.isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.black)
                                  : const Text("START TRIP",
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(Color color) {
    return Container(
        width: 24,
        height: 6,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(100)));
  }

  Widget _buildQuickInfo(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13)),
      ],
    );
  }

  void _showReportRiderDialog(BuildContext context, RideProvider provider) {
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String selectedSeverity = 'MEDIUM';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Report Rider Misconduct',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reasonController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'e.g., Harassment, Safety Concern',
                    hintStyle: TextStyle(color: Colors.white38),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'Provide details about the incident',
                    hintStyle: TextStyle(color: Colors.white38),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSeverity,
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                  ),
                  items: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
                      .map((severity) => DropdownMenuItem(
                            value: severity,
                            child: Text(severity,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    selectedSeverity = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.isNotEmpty) {
                  final success = await provider.reportRiderMisconduct(
                    reasonController.text,
                    descriptionController.text,
                    selectedSeverity,
                  );

                  if (!context.mounted) return;

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Report submitted successfully'
                            : 'Failed to submit report',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Submit Report'),
            ),
          ],
        );
      },
    );
  }
}
