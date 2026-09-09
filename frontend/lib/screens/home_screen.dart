import 'package:flutter/material.dart';

import 'package:roadwatch/theme/app_theme.dart';
import 'report_screen.dart';
import 'map_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('RoadWatch')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo / hero image from assets/images/
              Image.asset(
                'assets/images/roadwatch_logo.png', // Replace with your actual logo filename in assets/images/
                height: 72,
                width: 72,
              ),
              const SizedBox(height: 12),
              const Text(
                'RoadWatch',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy),
              ),
              const Text(
                'AI-Powered Pothole Reporting\n& Road Maintenance',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 40),

              // Navigation buttons with custom asset icons from assets/icons/
              _NavTile(
                assetIconPath: 'assets/icons/pothole_icon.png',
                label: 'Report a Pothole',
                subtitle: 'Photo · GPS · AI severity',
                color: AppTheme.navy,
                onTap: () => _push(context, const ReportScreen()),
              ),
              const SizedBox(height: 14),
              _NavTile(
                assetIconPath: 'assets/icons/map_icon.png',
                label: 'Live Map',
                subtitle: 'All reports, color-coded by severity',
                color: AppTheme.severityMedium,
                onTap: () => _push(context, const MapScreen()),
              ),
              const SizedBox(height: 14),
              _NavTile(
                assetIconPath: 'assets/icons/admin_icon.png',
                label: 'Admin Dashboard',
                subtitle: 'Manage status · assign department',
                color: AppTheme.severityHigh,
                onTap: () => _push(context, const AdminScreen()),
              ),

              const Spacer(),
              const Text(
                'Smart India Hackathon 2026 · MB-04 · Team Tech Titans',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class _NavTile extends StatelessWidget {
  final String assetIconPath;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavTile({
    required this.assetIconPath,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Image.asset(
                assetIconPath,
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}