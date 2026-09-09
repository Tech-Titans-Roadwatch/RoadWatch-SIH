import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:roadwatch/models/complaint.dart';
import 'package:roadwatch/services/api_service.dart';
import 'package:roadwatch/widgets/severity_badge.dart';
import 'package:roadwatch/widgets/map_marker.dart';
import 'package:roadwatch/utils/constants.dart';
import 'package:roadwatch/utils/helpers.dart';
import 'package:roadwatch/theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Complaint> _complaints = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.fetchComplaints();
      setState(() => _complaints = data);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _complaints.isNotEmpty
        ? LatLng(_complaints.first.latitude, _complaints.first.longitude)
        : const LatLng(kDefaultLat, kDefaultLng);

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Map  (${_complaints.length} reports)'),
        actions: [
          IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh')
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: _complaints.isNotEmpty
                            ? kReportZoom
                            : kDefaultZoom,
                      ),
                      children: [
                        // OpenStreetMap tiles — no API key required
                        TileLayer(
                          urlTemplate: kIsWeb
                              ? 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
                              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.roadwatch.app',
                        ),
                        MarkerLayer(
                          markers: _complaints
                              .map((c) => Marker(
                                    point: LatLng(c.latitude, c.longitude),
                                    width: 40,
                                    height: 40,
                                    child: MapMarkerIcon(
                                      severity: c.severity,
                                      onTap: () => _showDetail(c),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                    // Legend overlay
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: _MapLegend(),
                    ),
                  ],
                ),
    );
  }

  void _showDetail(Complaint c) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              SeverityBadge(severity: c.severity),
              const SizedBox(width: 10),
              Text(c.status,
                  style: TextStyle(
                      color: AppTheme.statusColor(c.status),
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 10),
            if (c.description != null)
              Text(c.description!,
                  style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text(c.aiSummary ?? '',
                style:
                    const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 6),
            Text('📍 ${formatCoords(c.latitude, c.longitude)}',
                style:
                    const TextStyle(color: Colors.black45, fontSize: 12)),
            Text('🏢 ${c.assignedDepartment}',
                style:
                    const TextStyle(color: Colors.black45, fontSize: 12)),
            Text('🕐 ${formatRelativeDate(c.createdAt)}',
                style:
                    const TextStyle(color: Colors.black45, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendRow(color: AppTheme.severityHigh, label: 'High'),
            _LegendRow(color: AppTheme.severityMedium, label: 'Medium'),
            _LegendRow(color: AppTheme.severityLow, label: 'Low'),
          ],
        ),
      );
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
}
