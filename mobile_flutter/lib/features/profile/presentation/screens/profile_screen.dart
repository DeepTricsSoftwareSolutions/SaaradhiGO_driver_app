import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:saaradhi_go_driver/features/auth/presentation/providers/auth_provider.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';
import 'package:saaradhi_go_driver/core/widgets/glass_card.dart';
import 'package:saaradhi_go_driver/core/widgets/driver_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = auth.user ?? {};
        final name = user['fullName'] ?? 'Driver Name';

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
              "MY PROFILE",
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

                // Profile Header with Gradient Border
                FadeInDown(
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryGold,
                                AppTheme.primaryGold.withValues(alpha: 0.1)
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(0xFF1A1A1A),
                            child: Text(
                              name.isNotEmpty ? name[0] : "D",
                              style: const TextStyle(
                                  color: AppTheme.primaryGold,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          name,
                          style: const TextStyle(
                              color: AppTheme.primaryGold,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "ELITE DRIVER • HYDERABAD",
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Stats Section
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Row(
                    children: [
                      _buildProfileStat("RIDES", "12"),
                      const SizedBox(width: 16),
                      _buildProfileStat("RATING", "4.9", isGold: true),
                      const SizedBox(width: 16),
                      _buildProfileStat("YEARS", "0.5"),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Settings Menu
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "MANAGEMENT",
                        style: TextStyle(
                            color: AppTheme.primaryGold,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildProfileMenuItem(
                                Icons.edit_rounded,
                                "Edit Profile",
                                () => Navigator.pushNamed(
                                    context, '/edit-profile')),
                            _buildProfileMenuItem(
                                Icons.account_balance_wallet_rounded,
                                "Earnings & Wallet",
                                () => Navigator.pushNamed(context, '/wallet')),
                            _buildProfileMenuItem(
                                Icons.history_rounded,
                                "Trip History",
                                () =>
                                    Navigator.pushNamed(context, '/earnings')),
                            _buildProfileMenuItem(
                                Icons.verified_user_rounded,
                                "KYC Documents",
                                () =>
                                    Navigator.pushNamed(context, '/documents')),
                            _buildProfileMenuItem(
                                Icons.directions_car_rounded,
                                "Vehicle Management",
                                () => Navigator.pushNamed(
                                    context, '/vehicle-management')),
                            _buildProfileMenuItem(Icons.help_center_rounded,
                                "Support Center", () {}),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Logout
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: DriverButton(
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (route) => false);
                      }
                    },
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    child: const Text("LOGOUT SESSION",
                        style: TextStyle(color: AppTheme.errorRed)),
                  ),
                ),

                const SizedBox(height: 40),
                const Center(
                  child: Opacity(
                    opacity: 0.1,
                    child: Text(
                      "v2.5.0-PRO BUILD 2024",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1),
                    ),
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

  Widget _buildProfileStat(String label, String value, {bool isGold = false}) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: isGold ? AppTheme.primaryGold : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(
      IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white38, size: 20),
      title: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
