import 'package:flutter/material.dart';
import '../../core/theme.dart';

class DriverButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final double? width;
  final bool isLoading;
  final double height;
  final double borderRadius;

  const DriverButton({
    super.key,
    this.onPressed,
    required this.child,
    this.backgroundColor,
    this.width,
    this.isLoading = false,
    this.height = 58,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: (isLoading || onPressed == null) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.primaryGold,
          foregroundColor: Colors.black,
          disabledBackgroundColor: (backgroundColor ?? AppTheme.primaryGold).withValues(alpha: 0.2),
          disabledForegroundColor: Colors.black.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 3,
                ),
              )
            : DefaultTextStyle.merge(
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
                child: child,
              ),
      ),
    );
  }
}
