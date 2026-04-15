import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../features/ride/ride_provider.dart';
import 'widgets/glass_card.dart';
import 'widgets/driver_button.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, rideProvider, _) {
        final balance = rideProvider.totalEarnings > 0 ? rideProvider.totalEarnings : 8450.0;

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
              "WALLET",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Silver/Glass Balance Card
                FadeInDown(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "AVAILABLE BALANCE",
                          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "₹${balance.toInt()}",
                          style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -1),
                        ),
                        const SizedBox(height: 32),
                        DriverButton(
                          onPressed: () {},
                          child: const Text("WITHDRAW TO BANK"),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bank Methods
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.account_balance_rounded, color: AppTheme.primaryGold),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("HDFC BANK •••• 8829", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                              Text("PRIMARY ACCOUNT", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Transactions
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "RECENT TRANSACTIONS",
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 16),
                      _buildTxItem("Weekly Bonus", "Mar 07", "+₹500", AppTheme.successGreen),
                      _buildTxItem("Bank Transfer", "Mar 05", "-₹2500", Colors.white38),
                      _buildTxItem("Ride Earning", "Mar 05", "+₹340", AppTheme.successGreen),
                      _buildTxItem("Ride Earning", "Mar 04", "+₹190", AppTheme.successGreen),
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

  Widget _buildTxItem(String label, String date, String amount, Color amountColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                amount.startsWith('+') ? Icons.add_rounded : Icons.call_made_rounded,
                color: amountColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(date, style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Text(amount, style: TextStyle(color: amountColor, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
