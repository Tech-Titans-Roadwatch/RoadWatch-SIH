// ── API ─────────────────────────────────────────────────────────────────────
// Android emulator → 127.0.0.1 maps to your computer's localhost.
// Physical phone on same Wi-Fi → change to your machine's LAN IP, e.g. 192.168.1.x
const String kBaseUrl = 'https://underwire-grumble-shifting.ngrok-free.dev';

// ── Complaint workflow ───────────────────────────────────────────────────────
const List<String> kStatusFlow = [
  'Reported',
  'Verified',
  'Assigned',
  'Repair in Progress',
  'Resolved',
];

const List<String> kDepartments = [
  'Unassigned',
  'Public Works Department',
  'Municipal Corporation - Roads Cell',
  'Traffic & Road Safety Cell',
];

// ── Map ──────────────────────────────────────────────────────────────────────
// Default map centre — change to your city's coordinates for the demo.
const double kDefaultLat = 20.5937;
const double kDefaultLng = 78.9629;
const double kDefaultZoom = 5.0;
const double kReportZoom = 14.0;

// ── Duplicate clustering ─────────────────────────────────────────────────────
// Must match DUPLICATE_RADIUS_METERS in backend/5_routers/1_complaints.py
const double kDuplicateRadiusMeters = 25.0;

// ── Image ────────────────────────────────────────────────────────────────────
const int kImageQuality = 85; // 0-100, passed to image_picker
