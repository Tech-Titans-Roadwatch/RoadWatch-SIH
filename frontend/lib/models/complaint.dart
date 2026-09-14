class Complaint {
  final String id;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String? placeName;
  final String? description;

  // AI output
  final String? severity;
  final double? aiConfidence;
  final int detectionsCount;
  final String? aiSummary;

  // Workflow
  final String status;
  final String assignedDepartment;
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  Complaint({
    required this.id,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.description,
    this.severity,
    this.aiConfidence,
    required this.detectionsCount,
    this.aiSummary,
    required this.status,
    required this.assignedDepartment,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
        id: json['id'] as String,
        imageUrl: json['image_url'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        placeName: json['place_name'] as String?,
        description: json['description'] as String?,
        severity: json['severity'] as String?,
        aiConfidence: json['ai_confidence'] == null
            ? null
            : (json['ai_confidence'] as num).toDouble(),
        detectionsCount: (json['detections_count'] as num?)?.toInt() ?? 0,
        aiSummary: json['ai_summary'] as String?,
        status: json['status'] as String? ?? 'Reported',
        assignedDepartment: json['assigned_department'] as String? ?? 'Unassigned',
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Complaint copyWith({
    String? status,
    String? assignedDepartment,
    String? notes,
  }) =>
      Complaint(
        id: id,
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
        placeName: placeName,
        description: description,
        severity: severity,
        aiConfidence: aiConfidence,
        detectionsCount: detectionsCount,
        aiSummary: aiSummary,
        status: status ?? this.status,
        assignedDepartment: assignedDepartment ?? this.assignedDepartment,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}