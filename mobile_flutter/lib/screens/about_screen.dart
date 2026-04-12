import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/theme.dart';
import 'widgets/glass_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.primaryGold),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 120),
            
            // App Logo and Version
            FadeInDown(
              child: Column(
                children: [
                   Container(
                     width: 120,
                     height: 120,
                     decoration: BoxDecoration(
                       color: const Color(0xFF1A1500),
                       borderRadius: BorderRadius.circular(30),
                       border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1), width: 1.5),
                       boxShadow: [
                         BoxShadow(
                           color: AppTheme.primaryGold.withValues(alpha: 0.2),
                           blurRadius: 30,
                           spreadRadius: 5,
                         ),
                       ],
                     ),
                     padding: const EdgeInsets.all(16),
                     child: Image.asset(
                       'assets/images/logo.png',
                       fit: BoxFit.contain,
                       errorBuilder: (_, __, ___) => const Icon(
                         Icons.directions_car,
                         color: AppTheme.primaryGold,
                         size: 60,
                       ),
                     ),
                   ),
                   const SizedBox(height: 24),
                   const Text(
                     "SaaradhiGO",
                     style: TextStyle(
                       fontSize: 32,
                       fontWeight: FontWeight.w900,
                       color: Colors.white,
                       letterSpacing: -1,
                     ),
                   ),
                   const SizedBox(height: 4),
                   const Text(
                     "DRIVER PARTNER APP v2.4.1",
                     style: TextStyle(
                       color: AppTheme.primaryGold,
                       fontSize: 10,
                       fontWeight: FontWeight.w900,
                       letterSpacing: 3,
                     ),
                   ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Links and Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "INFORMATION",
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildAboutItem(Icons.description_outlined, "Terms & Conditions"),
                          const Divider(height: 1, color: Colors.white10),
                          _buildAboutItem(Icons.privacy_tip_outlined, "Privacy Policy"),
                          const Divider(height: 1, color: Colors.white10),
                          _buildAboutItem(Icons.security, "Safety Guidelines"),
                          const Divider(height: 1, color: Colors.white10),
                          _buildAboutItem(Icons.gavel_outlined, "Legal Notices"),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  const Text(
                    "SUPPORT",
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildAboutItem(Icons.help_center_outlined, "Help Center & FAQs"),
                          const Divider(height: 1, color: Colors.white10),
                          _buildAboutItem(Icons.headset_mic_outlined, "Contact Support 24/7"),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "Made with \u2665 in India",
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "© 2026 SaaradhiGO Technologies",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutItem(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: AppTheme.primaryGold, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: () {},
    );
  }
}
