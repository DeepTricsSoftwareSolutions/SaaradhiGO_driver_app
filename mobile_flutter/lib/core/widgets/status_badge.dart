import 'package:flutter/material.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final EdgeInsetsGeometry? margin;

  const StatusBadge({
    super.key,
    required this.status,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'online':
        bgColor = AppTheme.successGreen.withValues(alpha: 0.2);
        textColor = AppTheme.successGreen;
        label = "Online";
        break;
      case 'offline':
        bgColor = Colors.white.withValues(alpha: 0.2);
        textColor = Colors.white38;
        label = "Offline";
        break;
      case 'pending':
        bgColor = AppTheme.primaryGold.withValues(alpha: 0.2);
        textColor = AppTheme.primaryGold;
        label = "Pending";
        break;
      case 'verified':
        bgColor = AppTheme.successGreen.withValues(alpha: 0.2);
        textColor = AppTheme.successGreen;
        label = "Verified";
        break;
      default:
        bgColor = Colors.white.withValues(alpha: 0.2);
        textColor = Colors.white;
        label = status.toUpperCase();
    }

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
