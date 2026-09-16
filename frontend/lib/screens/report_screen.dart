import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';

import 'package:roadwatch/models/complaint.dart';
import 'package:roadwatch/services/api_service.dart';
import 'package:roadwatch/services/notification_service.dart';
import 'package:roadwatch/widgets/severity_badge.dart';
import 'package:roadwatch/theme/app_theme.dart';
import 'package:roadwatch/utils/constants.dart';
import 'package:roadwatch/screens/video_record_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  File? _mediaFile; // Can hold either a photo or a video
  bool _isVideo = false;
  Position? _position;
  final _descCtrl = TextEditingController();
  bool _capturingGps = false;
  bool _submitting = false;
  String? _statusMsg;
  Complaint? _submitted;

  // ── Media Selection (Photo or Video) ───────────────────────────────────────
  Future<void> _pickPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: kImageQuality);
    
    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _mediaFile = File(picked.path);
        _isVideo = false;
      });
    }
  }

  Future<void> _recordVideo() async {
    try {
      final cameras = await availableCameras();

      // Guard check: ensures the widget is still in the tree before using context or setState
      if (!mounted) return;

      if (cameras.isEmpty) {
        setState(() => _statusMsg = 'No cameras available on this device.');
        return;
      }

      final File? recordedVideo = await Navigator.push<File?>(
        context,
        MaterialPageRoute(
          builder: (context) => VideoRecordScreen(cameras: cameras),
        ),
      );

      // Guard check: ensures the widget is still mounted after returning from VideoRecordScreen
      if (!mounted) return;

      if (recordedVideo != null) {
        setState(() {
          _mediaFile = recordedVideo;
          _isVideo = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMsg = 'Video recording error: $e');
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Take Road Photo (AI Analysis)'),
            onTap: () {
              Navigator.pop(context);
              _pickPhoto();
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam_rounded),
            title: const Text('Record Live Video Option'),
            onTap: () {
              Navigator.pop(context);
              _recordVideo();
            },
          ),
        ],
      ),
    );
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
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      setState(() {
        _position = pos;
        _statusMsg = 'GPS acquired successfully!';
      });
    } catch (e) {
      setState(() => _statusMsg = 'GPS error: $e');
    } finally {
      setState(() => _capturingGps = false);
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_mediaFile == null) {
      setState(() => _statusMsg = 'Please add a photo or video first.');
      return;
    }
    if (_position == null) {
      setState(() => _statusMsg = 'Please capture GPS location first.');
      return;
    }
    setState(() {
      _submitting = true;
      _statusMsg = _isVideo ? 'Uploading video report…' : 'Uploading photo and running AI detection…';
      _submitted = null;
    });
    try {
      final token = await NotificationService.getDeviceToken();
      
      Complaint c;
      if (_isVideo) {
        c = await ApiService.submitVideoComplaint(
          video: _mediaFile!,
          latitude: _position!.latitude,
          longitude: _position!.longitude,
          description: _descCtrl.text,
          deviceToken: token,
        );
      } else {
        c = await ApiService.submitComplaint(
          photo: _mediaFile!,
          latitude: _position!.latitude,
          longitude: _position!.longitude,
          description: _descCtrl.text,
          deviceToken: token,
        );
      }

      if (!mounted) return;

      // ── TRIGGER LIFECYCLE NOTIFICATION (SUBMITTED) ────────────────────────
      await NotificationService.showLocalStatus(
        id: 1,
        title: 'Report Submitted! 🚀',
        body: 'Your pothole report has been successfully sent to RoadWatch.',
      );

      setState(() {
        _submitted = c;
        _statusMsg = 'Report submitted successfully!';
        _mediaFile = null;
        _isVideo = false;
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
            _MediaPicker(mediaFile: _mediaFile, isVideo: _isVideo, onTap: _showMediaOptions),
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

class _MediaPicker extends StatelessWidget {
  final File? mediaFile;
  final bool isVideo;
  final VoidCallback onTap;
  const _MediaPicker({required this.mediaFile, required this.isVideo, required this.onTap});

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
        child: mediaFile == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded, size: 44, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Tap to capture photo or record video',
                      style: TextStyle(color: Colors.grey)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: isVideo
                    ? Container(
                        color: Colors.black,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam, size: 50, color: Colors.white),
                              SizedBox(height: 8),
                              Text('Video Recorded Ready to Submit',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      )
                    : Image.file(mediaFile!, fit: BoxFit.cover,
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