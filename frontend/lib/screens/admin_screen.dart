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

  Future<void> _updateStatus(Complaint c, String newStatus) async {
    await ApiService.updateComplaint(c.id, status: newStatus);
    _load();
  }

  Future<void> _updateDepartment(Complaint c, String dept) async {
    await ApiService.updateComplaint(c.id, assignedDepartment: dept);
    _load();
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
                        itemBuilder: (context, i) =>
                            _AdminComplaintTile(
                          complaint: _complaints[i],
                          onStatusChanged: _updateStatus,
                          onDeptChanged: _updateDepartment,
                        ),
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
  final Future<void> Function(Complaint, String) onStatusChanged;
  final Future<void> Function(Complaint, String) onDeptChanged;

  const _AdminComplaintTile({
    required this.complaint,
    required this.onStatusChanged,
    required this.onDeptChanged,
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
            Row(
              children: [
                // Status dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: complaint.status,
                    decoration: const InputDecoration(
                        labelText: 'Status', isDense: true),
                    items: kStatusFlow
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s,
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppTheme.statusColor(s)))))
                        .toList(),
                    onChanged: (v) =>
                        v != null ? onStatusChanged(complaint, v) : null,
                  ),
                ),
                const SizedBox(width: 10),
                // Department dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: complaint.assignedDepartment,
                    decoration: const InputDecoration(
                        labelText: 'Department', isDense: true),
                    items: kDepartments
                        .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d,
                                style: const TextStyle(fontSize: 11))))
                        .toList(),
                    onChanged: (v) =>
                        v != null ? onDeptChanged(complaint, v) : null,
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
