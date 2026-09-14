import 'package:flutter/material.dart';
import 'package:roadwatch/models/complaint.dart';
import 'package:roadwatch/services/api_service.dart';
import 'package:roadwatch/utils/helpers.dart';
import 'package:roadwatch/theme/app_theme.dart';
import 'severity_badge.dart';

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback? onStatusChanged;

  const ComplaintCard({
    super.key,
    required this.complaint,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(complaint.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail image with red bounding box
            // Thumbnail image with red bounding box (Tap to enlarge)
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.black,
                    child: Stack(
                      children: [
                        Center(
                          child: InteractiveViewer(
                            child: Image.network(
                              ApiService.imageUrl(complaint.imageUrl),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 28),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ApiService.imageUrl(complaint.imageUrl),
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Content column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Severity & Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SeverityBadge(severity: complaint.severity),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          complaint.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // AI Confidence Score
                  if (complaint.aiConfidence != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "AI Confidence: ${(complaint.aiConfidence! * 100).toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),

                  // Place Name
                  if (complaint.placeName != null && complaint.placeName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              complaint.placeName!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // GPS Coordinates
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "GPS: ${complaint.latitude.toStringAsFixed(4)}, ${complaint.longitude.toStringAsFixed(4)}",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ),

                  // Description
                  Text(
                    complaint.description ?? '(no description)',
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Meta row (Time)
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.black45),
                      const SizedBox(width: 3),
                      Text(
                        formatRelativeDate(complaint.createdAt),
                        style: const TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}