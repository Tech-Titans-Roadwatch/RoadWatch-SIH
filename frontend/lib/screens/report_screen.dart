import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import 'package:roadwatch/models/complaint.dart';
import 'package:roadwatch/services/api_service.dart';
import 'package:roadwatch/services/notification_service.dart';
import 'package:roadwatch/widgets/severity_badge.dart';
import 'package:roadwatch/theme/app_theme.dart';
import 'package:roadwatch/utils/constants.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  File? _photo;
  Position? _position;
  final _descCtrl = TextEditingController();
  bool _capturingGps = false;
  bool _submitting = false;
  String? _statusMsg;
  Complaint? _submitted;

  // ── Photo ──────────────────────────────────────────────────────────────────
 // ── Photo ──────────────────────────────────────────────────────────────────
  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker()
        .pickImage(source: source, imageQuality: kImageQuality);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  void _showPhotoOptions() {
    // Strictly enforce live camera capture to prevent gallery tampering
    _pickPhoto(ImageSource.camera);
  }
  // ── GPS ────────────────────────────────────────────────────────────────────
  Future<void> _captureGps() async {
    setState(() {
      _capturingGps = true;
      _statusMsg = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled on this device.');
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception(
            'Location permission permanently denied — enable it in Settings.');
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _position = pos);
    } catch (e) {
      setState(() => _statusMsg = 'GPS error: $e');
    } finally {
      setState(() => _capturingGps = false);
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_photo == null) {
      setState(() => _statusMsg = 'Please add a photo first.');
      return;
    }
    if (_position == null) {
      setState(() => _statusMsg = 'Please capture GPS location first.');
      return;
    }
    setState(() {
      _submitting = true;
      _statusMsg = 'Uploading photo and running AI detection…';
      _submitted = null;
    });
    try {
      final token = await NotificationService.getDeviceToken();
      final c = await ApiService.submitComplaint(
        photo: _photo!,
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        description: _descCtrl.text,
        deviceToken: token,
      );
      setState(() {
        _submitted = c;
        _statusMsg = 'Report submitted successfully!';
        // Reset form
        _photo = null;
        _position = null;
        _descCtrl.clear();
      });
    } catch (e) {
      setState(() => _statusMsg = 'Submission failed: $e');
    } finally {
      setState(() => _submitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a Pothole')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PhotoPicker(photo: _photo, onTap: _showPhotoOptions),
            const SizedBox(height: 16),
            _GpsButton(
              position: _position,
              loading: _capturingGps,
              onTap: _captureGps,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. Large pothole near speed-breaker',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Report'),
            ),
            if (_statusMsg != null) ...[
              const SizedBox(height: 12),
              Text(_statusMsg!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _submitted != null ? Colors.green : Colors.black54)),
            ],
            if (_submitted != null) ...[
              const SizedBox(height: 16),
              _ResultCard(complaint: _submitted!),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets (private to this screen) ─────────────────────────────────────

class _PhotoPicker extends StatelessWidget {
  final File? photo;
  final VoidCallback onTap;
  const _PhotoPicker({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: photo == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded, size: 44, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Tap to take / choose a photo',
                      style: TextStyle(color: Colors.grey)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(photo!, fit: BoxFit.cover,
                    width: double.infinity)),
      ),
    );
  }
}

class _GpsButton extends StatelessWidget {
  final Position? position;
  final bool loading;
  final VoidCallback onTap;
  const _GpsButton(
      {required this.position, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.my_location_rounded),
      label: Text(
        loading
            ? 'Capturing GPS…'
            : position == null
                ? 'Capture GPS location'
                : '📍 ${position!.latitude.toStringAsFixed(5)}, ${position!.longitude.toStringAsFixed(5)}',
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Complaint complaint;
  const _ResultCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.severityColor(complaint.severity).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.severityColor(complaint.severity).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Detection Result',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SeverityBadge(severity: complaint.severity),
          const SizedBox(height: 8),
          Text(complaint.aiSummary ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}
