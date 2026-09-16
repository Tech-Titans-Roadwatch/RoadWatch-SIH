import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class VideoRecordScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const VideoRecordScreen({super.key, required this.cameras});

  @override
  State<VideoRecordScreen> createState() => _VideoRecordScreenState();
}

class _VideoRecordScreenState extends State<VideoRecordScreen> {
  late CameraController _controller;
  bool _isInitialized = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _controller = CameraController(widget.cameras[0], ResolutionPreset.high);
    await _controller.initialize();
    if (!mounted) return;
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _startRecording() async {
    if (!_controller.value.isInitialized || _isRecording) return;
    try {
      await _controller.startVideoRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      debugPrint('Error starting video recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      XFile videoFile = await _controller.stopVideoRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
      });
      if (!mounted) return;
      Navigator.pop(context, File(videoFile.path));
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Record Road Video')),
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller)),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: _isRecording ? Colors.red : Colors.white,
                onPressed:
                    _isRecording ? _stopRecording : _startRecording,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.fiber_manual_record,
                  color: _isRecording ? Colors.white : Colors.red,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}