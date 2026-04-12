import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../features/ride/ride_provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'widgets/driver_button.dart';
import 'widgets/glass_card.dart';

class EndTripScreen extends StatefulWidget {
  const EndTripScreen({super.key});

  @override
  State<EndTripScreen> createState() => _EndTripScreenState();
}

class _EndTripScreenState extends State<EndTripScreen> {
  int _rating = 5;
  final TextEditingController _feedbackController = TextEditingController();

  Future<void> _handleComplete(RideProvider provider) async {
    final tripIdStr = provider.currentRide?['id']?.toString() ?? '0';
    // Remove non-numeric chars from ride ID if it's 'RIDE_123', just as a fallback
    // Or send it directly if the backend expects string IDs. The ApiClient says `int tripId`.
    int tripId = int.tryParse(tripIdStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    
    try {
      await ApiClient().rateTrip(tripId, _rating, _feedbackController.text);
    } catch (_) {}

    await provider.completePayment(provider.currentRide?['paymentMode'] ?? 'CASH');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RideProvider>();
    final ride = provider.currentRide;
    
    // Safety check just in case, though it shouldn't be null here
    if (ride == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)));
    }

    final totalFare = ride['fare'];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Celebratory Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [AppTheme.successGreen.withValues(alpha: 0.8), Colors.black],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Success Header
                  FadeInDown(
                    child: Column(
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.successGreen.withValues(alpha: 0.2),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 4),
                          ),
                          child: const Icon(Icons.check_circle, color: Colors.white, size: 64),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          "TRIP COMPLETE!",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -2,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "GREAT WORK, KEEP IT UP",
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Earnings Card
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryGold.withValues(alpha: 0.8), Colors.black],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(44),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 60, offset: const Offset(0, 30)),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "TOTAL PARTNER REVENUE",
                            style: TextStyle(
                              color: AppTheme.primaryGold,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "₹$totalFare",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: -4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.1)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_outlined, color: AppTheme.successGreen, size: 14),
                                SizedBox(width: 8),
                                Text(
                                  "ADDED TO WALLET",
                                  style: TextStyle(color: AppTheme.successGreen, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Route Summary
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          _buildRoutePoint(Icons.location_on, AppTheme.successGreen, "Departure Point", ride['pickupAddr'] ?? "Unknown Location"),
                          Padding(
                            padding: const EdgeInsets.only(left: 21),
                            child: Container(
                              width: 2,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppTheme.successGreen.withValues(alpha: 0.2), AppTheme.primaryGold.withValues(alpha: 0.2)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          _buildRoutePoint(Icons.near_me, AppTheme.primaryGold, "Arrival Point", ride['dropAddr'] ?? "Unknown Location"),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Rating Section
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            "HOW WAS YOUR PASSENGER?",
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) => IconButton(
                              onPressed: () => setState(() => _rating = index + 1),
                              icon: Icon(
                                index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: AppTheme.primaryGold,
                                size: 40,
                              ),
                            )),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _feedbackController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: "Add a note for the partner...",
                              hintStyle: const TextStyle(color: Colors.white24),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Finish Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: Column(
                      children: [
                        DriverButton(
                          onPressed: () => _handleComplete(provider),
                          backgroundColor: AppTheme.successGreen,
                          height: 80,
                          borderRadius: 24,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("FINALIZE MISSION", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                              Text(
                                "RETURN TO HOME HUB FOR NEXT TASK",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "REPORT AN ISSUE WITH THIS TRIP",
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              fontStyle: FontStyle.italic,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildRoutePoint(IconData icon, Color color, String label, String address) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(color: color.withValues(alpha: 0.2), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 4),
            Text(
              address,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ],
    );
  }
}
