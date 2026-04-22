import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:saaradhi_go_driver/features/auth/presentation/providers/auth_provider.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';
import 'package:saaradhi_go_driver/core/widgets/driver_button.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final bool isRegistration;

  const OtpScreen({
    super.key,
    required this.phone,
    this.isRegistration = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _timer = 30;
  Timer? _countdownTimer;
  String _error = "";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = 30;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timer == 0) {
        timer.cancel();
      } else {
        setState(() => _timer--);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleVerify() async {
    final otpValue = _controllers.map((e) => e.text).join();
    if (otpValue.length != 6) return;
    setState(() => _error = "");
    
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOTP(widget.phone, otpValue);
    
    if (success && mounted) {
      if (widget.isRegistration) {
        auth.finalizeRegistrationSync();
        Navigator.pushReplacementNamed(context, '/verification');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else if (mounted) {
      setState(() {
        _error = auth.lastError ?? 'Invalid OTP';
        for (var c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      });
    }
  }

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _handleVerify();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                FadeInUp(
                  child: const Text(
                    'Verify Phone',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: RichText(
                    text: TextSpan(
                      text: 'Enter the 6-digit code sent to ',
                      style: const TextStyle(color: Colors.white38, fontSize: 15),
                      children: [
                        TextSpan(
                          text: widget.phone,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // OTP Input Row
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 50,
                        height: 65,
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _controllers[index].text.isNotEmpty
                                ? AppTheme.primaryGold.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.1),
                            width: 2,
                          ),
                          boxShadow: [
                            if (_controllers[index].text.isNotEmpty)
                              BoxShadow(
                                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                                blurRadius: 15,
                              ),
                          ],
                        ),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          onChanged: (value) => _onChanged(index, value),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  FadeIn(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error,
                          style: const TextStyle(color: AppTheme.errorRed, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 48),

                // Resend Timer
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Center(
                    child: Column(
                      children: [
                        if (_timer > 0)
                          Text(
                            'Resend code in ${_timer}s',
                            style: const TextStyle(color: Colors.white30, fontSize: 14),
                          )
                        else
                          TextButton(
                            onPressed: () {
                              auth.sendOTP(widget.phone);
                              _startTimer();
                            },
                            child: const Text(
                              'RESEND CODE',
                              style: TextStyle(
                                color: AppTheme.primaryGold,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: DriverButton(
                    onPressed: _handleVerify,
                    isLoading: auth.isLoading,
                    child: const Text('VERIFY & CONTINUE'),
                  ),
                ),

                const SizedBox(height: 40),

                // Keypad Tip
                const Center(
                  child: Opacity(
                    opacity: 0.2,
                    child: Text(
                      'TIP: Use 123456 for Demo Access',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
