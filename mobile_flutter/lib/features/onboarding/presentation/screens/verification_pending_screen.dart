import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:saaradhi_go_driver/features/auth/presentation/providers/auth_provider.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';
import 'package:saaradhi_go_driver/core/widgets/glass_card.dart';
import 'package:saaradhi_go_driver/core/widgets/driver_button.dart';

class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to dashboard after 5 seconds (demo mode)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Color(0xFF0D0A00), Color(0xFF000000)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Verified / Pending Icon
                    FadeInDown(
                      child: Pulse(
                        infinite: true,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1500),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color:
                                    AppTheme.primaryGold.withValues(alpha: 0.1),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: AppTheme.primaryGold
                                      .withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  spreadRadius: 10),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.hourglass_bottom,
                                color: AppTheme.primaryGold,
                                size: 60),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Title
                    FadeInUp(
                    child: const Text(
                      "Verification Pending",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryGold,
                        letterSpacing: -1,
                      ),
                    ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: const Text(
                        "Your profile and documents are currently under review by our administration team. This process usually takes 24-48 hours.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Timeline Card
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildTimelineEvent(true, "Profile Created",
                                "Personal and vehicle details added"),
                            _buildTimelineEvent(true, "Documents Uploaded",
                                "Aadhaar, DL, and RC submitted"),
                            _buildTimelineEvent(
                                false, "Admin Verification", "In progress",
                                isLast: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Actions
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: Column(
                        children: [
                          DriverButton(
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Synchronizing with administration..."),
                                    duration: Duration(seconds: 2),
                                    backgroundColor: AppTheme.primaryGold),
                              );
                              // Calls getProfile internally to refresh status
                              await Provider.of<AuthProvider>(context,
                                      listen: false)
                                  .tryAutoLogin();

                              if (context.mounted) {
                                final auth = Provider.of<AuthProvider>(context,
                                    listen: false);
                                if (auth.user?['status'] != 'VERIFIED') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Account is still under review."),
                                        backgroundColor: AppTheme.errorRed),
                                  );
                                }
                              }
                            },
                            child: const Text("CHECK STATUS AGAIN"),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEvent(bool isDone, String title, String subtitle,
      {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? AppTheme.successGreen : Colors.white10,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isDone ? Colors.transparent : Colors.white24,
                    width: 2),
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.black, size: 16)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isDone ? AppTheme.successGreen : Colors.white12,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDone ? Colors.white : Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
