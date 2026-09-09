import 'package:flutter/material.dart';
import 'package:roadwatch/theme/app_theme.dart';

/// Colored pin shown on the live map for each complaint.
/// Tapping it calls [onTap] so the parent screen can show a detail sheet.
class MapMarkerIcon extends StatelessWidget {
  final String? severity;
  final VoidCallback? onTap;

  const MapMarkerIcon({super.key, required this.severity, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.severityColor(severity);
    return GestureDetector(
      onTap: onTap,
      child: Icon(Icons.location_on_rounded, color: color, size: 36),
    );
  }
}
