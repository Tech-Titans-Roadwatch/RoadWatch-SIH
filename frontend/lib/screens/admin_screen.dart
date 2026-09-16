import 'package:flutter/material.dart';

import 'package:roadwatch/models/complaint.dart';
import 'package:roadwatch/services/api_service.dart';
import 'package:roadwatch/widgets/complaint_card.dart';
import 'package:roadwatch/utils/constants.dart';
import 'package:roadwatch/theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Complaint> _complaints = [];
  bool _loading = true;
  String? _selectedStatus; // null = show all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.fetchComplaints(
          statusFilter: _selectedStatus);
      setState(() => _complaints = data);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard  (${_complaints.length})'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          _StatusFilterBar(
            selected: _selectedStatus,
            onChanged: (s) {
              setState(() => _selectedStatus = s);
              _load();
            },
          ),
          // Complaint list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _complaints.isEmpty
                    ? const Center(child: Text('No reports found.'))
                    : ListView.builder(
                        itemCount: _complaints.length,
                        itemBuilder: (context, i) {
                          return _AdminComplaintTile(
                            complaint: _complaints[i],
                          );
                        },
                       ),
          ),
        ],
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _StatusFilterBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  const _StatusFilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final chips = ['All', ...kStatusFlow];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = chips[i];
          final isSelected =
              (label == 'All' && selected == null) || label == selected;
          return ChoiceChip(
            label: Text(label, style: const TextStyle(fontSize: 12)),
            selected: isSelected,
            selectedColor: AppTheme.navy,
            labelStyle:
                TextStyle(color: isSelected ? Colors.white : Colors.black87),
            onSelected: (_) =>
                onChanged(label == 'All' ? null : label),
          );
        },
      ),
    );
  }
}

// ── Individual admin tile ─────────────────────────────────────────────────────

class _AdminComplaintTile extends StatelessWidget {
  final Complaint complaint;

  const _AdminComplaintTile({
    required this.complaint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ComplaintCard(complaint: complaint),
            const Divider(height: 16),
            // Read-only status display (No dropdowns or options)
            Row(
              children: [
                const Text(
                  "Status: ",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    complaint.status,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}