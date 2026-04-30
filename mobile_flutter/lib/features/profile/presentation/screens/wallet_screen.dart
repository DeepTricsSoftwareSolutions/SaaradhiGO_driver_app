import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';
import 'package:saaradhi_go_driver/features/ride/presentation/providers/ride_provider.dart';
import 'package:saaradhi_go_driver/core/widgets/glass_card.dart';
import 'package:saaradhi_go_driver/core/widgets/driver_button.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<RideProvider>(context, listen: false);
        provider.fetchWalletBalance();
        provider.loadTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, rideProvider, _) {
        final balance = rideProvider.walletBalance;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "WALLET",
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGold,
                  letterSpacing: 2),
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
                          style: const TextStyle(color: AppTheme.primaryGold, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -1),
                        ),
                        const SizedBox(height: 32),
                        DriverButton(
                          onPressed: () => _showWithdrawalSheet(context, balance, rideProvider),
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
                      if (rideProvider.payoutHistory.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              "No recent transactions.",
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        )
                      else
                        ...rideProvider.payoutHistory.map((tx) {
                          final amount = tx['fare']?.toString() ?? '0';
                          final isCredit = !amount.startsWith('-');
                          return _buildTxItem(
                            tx['payment']?.toString() ?? 'Unknown',
                            tx['date']?.toString() ?? 'Today',
                            isCredit ? "+₹$amount" : amount, // `amount` includes '-' if negative
                            isCredit ? AppTheme.successGreen : Colors.white38,
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

  void _showWithdrawalSheet(BuildContext context, double maxBalance, RideProvider rideProvider) {
    final TextEditingController amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("WITHDRAW FUNDS", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  prefixText: "₹ ",
                  prefixStyle: const TextStyle(color: Colors.white38, fontSize: 32, fontWeight: FontWeight.w900),
                  hintText: "0",
                  hintStyle: const TextStyle(color: Colors.white10),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Text("Available: ₹${maxBalance.toInt()}", style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 32),
              DriverButton(
                onPressed: () {
                  final entered = double.tryParse(amountController.text) ?? 0.0;
                  if (entered > 0 && entered <= maxBalance) {
                    rideProvider.requestWithdrawal(entered);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal Requested Successfully', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppTheme.successGreen));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid withdrawal amount', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppTheme.errorRed));
                  }
                },
                child: const Text("CONFIRM WITHDRAWAL"),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
