import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:saaradhi_go_driver/features/ride/presentation/providers/ride_provider.dart';
import 'package:saaradhi_go_driver/core/widgets/glass_card.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<RideProvider>(context, listen: false);
        provider.fetchEarnings();
        provider.loadRideHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, rideProvider, _) {
        final totalEarnings = rideProvider.totalEarnings > 0
            ? rideProvider.totalEarnings
            : rideProvider.todayEarnings;
        final completedRides = rideProvider.totalRides;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "DRIVER EARNINGS",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryGold,
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
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryGold, Color(0xFFCCAC00)],
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
                        const SizedBox(height: 12),
                        Text(
                          "Today: ₹${rideProvider.todayEarnings.toInt()}",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1),
                          ),
                          Text(
                            "This week",
                            style: TextStyle(
                                color: Colors.white24,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          height: 200,
                          child: Builder(
                            builder: (_) {
                              final weeklyValues = rideProvider.weeklyEarnings;
                              final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                              final maxValue = weeklyValues.any((value) => value > 0)
                                  ? weeklyValues.reduce((a, b) => a > b ? a : b)
                                  : 100.0;

                              return BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: maxValue * 1.2,
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (_) => Colors.black.withValues(alpha: 0.8),
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          '₹${rod.toY.toInt()}',
                                          const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              days[value.toInt()],
                                              style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          );
                                        },
                                        reservedSize: 28,
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: List.generate(7, (i) {
                                    return BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: weeklyValues[i].toDouble(),
                                          color: weeklyValues[i] == maxValue ? AppTheme.primaryGold : AppTheme.primaryGold.withValues(alpha: 0.3),
                                          width: 16,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Earning Guarantees Section (FR-D26)
                FadeInUp(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "EARNING GUARANTEES",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1),
                      ),
                      const SizedBox(height: 20),
                      _buildGuaranteeCard(
                        "HOURLY GUARANTEE",
                        "₹250/hour minimum",
                        "Active when online",
                        Icons.access_time_rounded,
                        AppTheme.successGreen,
                        "Guaranteed minimum earnings per hour when accepting rides",
                      ),
                      const SizedBox(height: 16),
                      _buildGuaranteeCard(
                        "PERFORMANCE BONUS",
                        "Up to ₹500/day",
                        "Based on acceptance rate",
                        Icons.trending_up_rounded,
                        AppTheme.primaryGold,
                        "Bonus for maintaining 90%+ ride acceptance rate",
                      ),
                      const SizedBox(height: 16),
                      _buildGuaranteeCard(
                        "STREAK REWARDS",
                        "₹50 per 10 rides",
                        "Current: 7 rides",
                        Icons.local_fire_department_rounded,
                        Colors.orange,
                        "Build streaks for consecutive completed rides",
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
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1),
                      ),
                      const SizedBox(height: 16),
                      if (rideProvider.rideHistory.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              "No recent trips available yet.",
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        )
                      else
                        ...rideProvider.rideHistory.map((trip) {
                          return _buildTripItem(
                            trip['from']?.toString() ?? 'Unknown',
                            trip['to']?.toString() ?? 'Unknown',
                            "₹${trip['fare']}",
                            trip['date']?.toString() ?? 'Recent',
                          );
                        }),
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

  Widget _buildStatItem(
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
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
              child: const Icon(Icons.history_rounded,
                  color: Colors.white38, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$from → $to",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(time,
                      style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Text(amount,
                style: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildGuaranteeCard(String title, String value, String subtitle,
      IconData icon, Color color, String description) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
