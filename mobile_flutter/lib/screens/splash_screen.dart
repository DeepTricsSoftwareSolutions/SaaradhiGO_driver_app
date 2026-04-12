import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/auth_provider.dart';
import '../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Master orchestrator
  late AnimationController _masterCtrl;

  // Logo 3D flip
  late AnimationController _logoFlipCtrl;
  late Animation<double> _logoFlipAnim;

  // Logo glow pulse
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  // Vehicle move across screen
  late AnimationController _vehicleCtrl;
  late Animation<double> _vehicleX;
  late Animation<double> _vehicleY;

  // Text reveal
  late AnimationController _textCtrl;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleOpacity;

  // Gold line draw
  late AnimationController _lineCtrl;
  late Animation<double> _lineWidth;

  // Star particles
  late AnimationController _particleCtrl;

  // Loading dots
  late AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();

    // ── Master (wait for animations) ──
    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..forward();

    // ── Logo 3D Flip (0 → 1.2s) ──
    _logoFlipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _logoFlipAnim = Tween<double>(begin: math.pi, end: 0).animate(
      CurvedAnimation(parent: _logoFlipCtrl, curve: Curves.easeOutBack),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoFlipCtrl.forward();
    });

    // ── Glow pulse (repeating) ──
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // ── Vehicle animation — drives across at 1.2s ──
    _vehicleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _vehicleX = Tween<double>(begin: -0.7, end: 1.2).animate(
      CurvedAnimation(parent: _vehicleCtrl, curve: Curves.easeInOut),
    );
    _vehicleY = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -6), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: -6, end: 0), weight: 50),
    ]).animate(_vehicleCtrl);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _vehicleCtrl.forward();
    });

    // Step 4: After animations end, transition state
    Future.delayed(const Duration(milliseconds: 3800), () {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).setSplashSeen();
      }
    });

    // ── Text reveal (1.0s) ──
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _textCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOut)));
    _subtitleOpacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _textCtrl, curve: const Interval(0.5, 1, curve: Curves.easeOut)));
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _textCtrl.forward();
    });

    // ── Gold line draw (2.2s) ──
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _lineWidth = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _lineCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) _lineCtrl.forward();
    });

    // ── Particles ──
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // ── Loading dots ──
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _logoFlipCtrl.dispose();
    _glowCtrl.dispose();
    _vehicleCtrl.dispose();
    _textCtrl.dispose();
    _lineCtrl.dispose();
    _particleCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── 1) DEEP BACKGROUND GRADIENT ──
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF0D0A00), Color(0xFF000000)],
              ),
            ),
          ),

          // ── 2) STAR PARTICLES ──
          ...List.generate(30, (i) => _buildStar(i, size)),

          // ── 3) AMBIENT GOLD GLOW (behind logo) ──
          Center(
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.2),
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 4) MAIN CONTENT ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3D Logo flip
                AnimatedBuilder(
                  animation: _logoFlipAnim,
                  builder: (_, child) {
                    final angle = _logoFlipAnim.value;
                    final isBack = angle > math.pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (_, __) => Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1500),
                            borderRadius: BorderRadius.circular(52),
                            border: Border.all(
                              color: AppTheme.primaryGold.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGold.withValues(alpha: 0.2),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(22),
                          child: isBack
                              ? const SizedBox()
                              : Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.directions_car,
                                    color: AppTheme.primaryGold,
                                    size: 100,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 44),

                // Title
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleOpacity,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFE97A), Color(0xFFC9A227), Color(0xFFFFE97A)],
                        stops: [0.0, 0.5, 1.0],
                      ).createShader(bounds),
                      child: const Text(
                        'SaaradhiGO',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Subtitle
                FadeTransition(
                  opacity: _subtitleOpacity,
                  child: const Text(
                    'DRIVER PARTNER',
                    style: TextStyle(
                      color: AppTheme.primaryGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Gold line draw animation
                AnimatedBuilder(
                  animation: _lineWidth,
                  builder: (_, __) => Container(
                    width: 160 * _lineWidth.value,
                    height: 2.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGold.withValues(alpha: 0.2),
                          AppTheme.primaryGold,
                          AppTheme.primaryGold.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Animated loading dots
                AnimatedBuilder(
                  animation: _dotsCtrl,
                  builder: (_, __) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── 5) ANIMATED VEHICLE SWEEP ──
          AnimatedBuilder(
            animation: _vehicleCtrl,
            builder: (_, __) {
              if (!_vehicleCtrl.isAnimating && _vehicleCtrl.value == 0) {
                return const SizedBox();
              }
              return Positioned(
                left: size.width * _vehicleX.value,
                top: size.height * 0.72 + _vehicleY.value,
                child: Opacity(
                  opacity: (_vehicleCtrl.value < 0.1
                      ? _vehicleCtrl.value / 0.1
                      : _vehicleCtrl.value > 0.9
                          ? (1 - _vehicleCtrl.value) / 0.1
                          : 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC9A227), Color(0xFFFFE97A)],
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGold.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car, color: Colors.black, size: 20),
                        SizedBox(width: 6),
                        Text('●  ●  ●',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── 6) BOTTOM TAGLINE ──
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _subtitleOpacity,
              child: const Center(
                child: Text(
                  'SECURED BY SAARADHIGO CLOUD',
                  style: TextStyle(
                    color: Colors.white12,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStar(int i, Size size) {
    final rand = math.Random(i * 7919);
    final x = rand.nextDouble();
    final y = rand.nextDouble();
    final radius = rand.nextDouble() * 1.5 + 0.5;

    return AnimatedBuilder(
      animation: _particleCtrl,
      builder: (_, __) {
        return Positioned(
          left: size.width * x,
          top: size.height * y,
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: i % 5 == 0
                  ? AppTheme.primaryGold.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
