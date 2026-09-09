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
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ApiService.imageUrl(complaint.imageUrl),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Severity + status row
                  Row(
                    children: [
                      SeverityBadge(severity: complaint.severity),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          complaint.status,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    truncate(complaint.description ?? '(no description)'),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Meta row
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: Colors.black45),
                      const SizedBox(width: 3),
                      Text(
                        formatRelativeDate(complaint.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.business, size: 12, color: Colors.black45),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          complaint.assignedDepartment,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black45),
                          overflow: TextOverflow.ellipsis,
                        ),
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
