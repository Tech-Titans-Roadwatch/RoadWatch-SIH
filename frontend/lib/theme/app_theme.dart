import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color navy = Color(0xFF0B3D91);
  static const Color saffron = Color(0xFFFF9933);
  static const Color white = Color(0xFFFFFFFF);

  // ── Severity colours ────────────────────────────────────────────────────────
  static const Color severityHigh = Color(0xFFD32F2F);
  static const Color severityMedium = Color(0xFFF57C00);
  static const Color severityLow = Color(0xFF388E3C);

  // ── Status colours ──────────────────────────────────────────────────────────
  static const Color statusReported = Color(0xFF9E9E9E);
  static const Color statusVerified = Color(0xFF1976D2);
  static const Color statusAssigned = Color(0xFF7B1FA2);
  static const Color statusInProgress = Color(0xFFF57C00);
  static const Color statusResolved = Color(0xFF388E3C);

  // ── Main theme ──────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: navy,
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: white,
          elevation: 2,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: navy,
            foregroundColor: white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: navy,
            side: const BorderSide(color: navy),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        cardTheme: const CardThemeData(
         elevation: 2.0,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
       ), 
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );

  // ── Helpers ─────────────────────────────────────────────────────────────────
  static Color severityColor(String? severity) {
    switch (severity) {
      case 'High':
        return severityHigh;
      case 'Medium':
        return severityMedium;
      default:
        return severityLow;
    }
  }

  static Color statusColor(String? status) {
    switch (status) {
      case 'Verified':
        return statusVerified;
      case 'Assigned':
        return statusAssigned;
      case 'Repair in Progress':
        return statusInProgress;
      case 'Resolved':
        return statusResolved;
      default:
        return statusReported;
    }
  }
}
