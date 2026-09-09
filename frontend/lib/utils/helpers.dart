import 'package:intl/intl.dart';

/// Returns a human-readable relative date string.
/// e.g. "Just now", "5 min ago", "2 hours ago", "Yesterday", "24 Aug 2026"
String formatRelativeDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
  if (diff.inDays == 1) return 'Yesterday';
  return DateFormat('d MMM yyyy').format(dt);
}

/// Converts a GPS coordinate pair into a short readable string.
String formatCoords(double lat, double lng) =>
    '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

/// Truncates long text with ellipsis for card previews.
String truncate(String text, {int maxLength = 80}) =>
    text.length <= maxLength ? text : '${text.substring(0, maxLength)}…';

/// Maps a complaint status string to a step index (0-based) for a stepper widget.
int statusToStep(String status) {
  const steps = [
    'Reported',
    'Verified',
    'Assigned',
    'Repair in Progress',
    'Resolved',
  ];
  final idx = steps.indexOf(status);
  return idx < 0 ? 0 : idx;
}
