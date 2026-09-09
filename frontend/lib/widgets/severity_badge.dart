import 'package:flutter/material.dart';
import 'package:roadwatch/theme/app_theme.dart';

class SeverityBadge extends StatelessWidget {
  final String? severity;
  final double fontSize;

  const SeverityBadge({super.key, required this.severity, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_severityIcon(severity), size: fontSize + 2, color: color),
          const SizedBox(width: 4),
          Text(
            severity ?? 'Unknown',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: fontSize),
          ),
        ],
      ),
    );
  }

  IconData _severityIcon(String? severity) {
    switch (severity) {
      case 'High':
        return Icons.warning_rounded;
      case 'Medium':
        return Icons.error_outline_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }
}
