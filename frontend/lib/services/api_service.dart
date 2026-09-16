import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:roadwatch/models/complaint.dart';

// Define your backend/Ngrok base URL here so all methods can access it
const String baseUrl = 'https://underwire-grumble-shifting.ngrok-free.dev';

class ApiService {
  // ── Complaints ──────────────────────────────────────────────────────────

  static Future<List<Complaint>> fetchComplaints({String? statusFilter}) async {
    final uri = Uri.parse('$baseUrl/api/complaints').replace(
      queryParameters:
          statusFilter != null ? {'status_filter': statusFilter} : null,
    );
    final res = await http.get(
      uri,
      headers: {'ngrok-skip-browser-warning': 'true'},
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load complaints (${res.statusCode})');
    }
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => Complaint.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Complaint> updateComplaint(
    String id, {
    String? status,
    String? assignedDepartment,
    String? notes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/complaints/$id');
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    if (assignedDepartment != null) body['assigned_department'] = assignedDepartment;
    if (notes != null) body['notes'] = notes;

    final res = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('Update failed (${res.statusCode})');
    }

    return Complaint.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  static Future<Complaint> submitComplaint({
    required File photo,
    required double latitude,
    required double longitude,
    required String description,
    required String? deviceToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/complaints');
    final request = http.MultipartRequest('POST', uri);
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();

    if (description.isNotEmpty) {
      request.fields['description'] = description;
    }
    if (deviceToken != null) {
      request.fields['device_token'] = deviceToken;
    }

    request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    request.headers['ngrok-skip-browser-warning'] = 'true';
    
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
          'Photo submission failed (${res.statusCode}): ${res.body}');
    }

    return Complaint.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  static Future<Complaint> submitVideoComplaint({
    required File video,
    required double latitude,
    required double longitude,
    required String description,
    required String? deviceToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/complaints/video');
    final request = http.MultipartRequest('POST', uri);
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();

    if (description.isNotEmpty) {
      request.fields['description'] = description;
    }
    if (deviceToken != null) {
      request.fields['device_token'] = deviceToken;
    }

    request.files.add(await http.MultipartFile.fromPath('video', video.path));
    request.headers['ngrok-skip-browser-warning'] = 'true';
    
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
          'Video submission failed (${res.statusCode}): ${res.body}');
    }

    return Complaint.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Builds the full URL for a relative image path returned by the backend.
  static String imageUrl(String relativePath) => '$baseUrl$relativePath';
}