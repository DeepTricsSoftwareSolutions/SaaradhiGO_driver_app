import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import '../core/theme.dart';
import '../features/ride/bloc/ride_bloc.dart';
import '../features/ride/bloc/ride_state.dart';
import 'widgets/glass_card.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideBloc, RideState>(
      builder: (context, state) {
        // Fallback or real data from state
        final totalEarnings = 1250.0; // In production, get from state/API
        final completedRides = 12;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "EARNINGS",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Primary Multiplier Card
                FadeInDown(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryGold, const Color(0xFFCCAC00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGold.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "TOTAL EARNINGS",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "₹${totalEarnings.toInt()}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            "TOP 1% OF DRIVERS",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: FadeInLeft(
                        child: _buildStatItem(
                          icon: Icons.directions_car_rounded,
                          label: "RIDES",
                          value: "$completedRides",
                          color: AppTheme.primaryGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FadeInRight(
                        child: _buildStatItem(
                          icon: Icons.timer_rounded,
                          label: "ONLINE",
                          value: "5.4h",
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Weekly Performance Section
                FadeInUp(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "WEEKLY REPORT",
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                          Text(
                            "MAR 01 - MAR 07",
                            style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          height: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(7, (i) {
                              final heights = [0.4, 0.7, 0.5, 0.9, 0.6, 0.3, 0.5];
                              final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 100 * heights[i],
                                    decoration: BoxDecoration(
                                      color: i == 3 ? AppTheme.primaryGold : Colors.white10,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(days[i], style: TextStyle(color: i == 3 ? Colors.white : Colors.white24, fontSize: 10, fontWeight: FontWeight.w900)),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Transactions
                FadeInUp(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "LATEST TRIPS",
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 16),
                      _buildTripItem("Hitech City", "Gachibowli", "₹350", "10:30 AM"),
                      _buildTripItem("Banjara Hills", "Airport", "₹750", "08:15 AM"),
                      _buildTripItem("Kukatpally", "Miyapur", "₹150", "Yesterday"),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value, required Color color}) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildTripItem(String from, String to, String amount, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.history_rounded, color: Colors.white38, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$from → $to", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(time, style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Text(amount, style: const TextStyle(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
