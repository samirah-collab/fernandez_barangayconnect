
import 'package:flutter/material.dart';
import '../services/local_db.dart';

class StaffReviewScreen extends StatefulWidget {
  final bool isReport;

  const StaffReviewScreen({
    super.key,
    required this.isReport,
  });

  @override
  State<StaffReviewScreen> createState() => _StaffReviewScreenState();
}

class _StaffReviewScreenState extends State<StaffReviewScreen> {

  // Get reports or certificate requests
  List<Map<String, dynamic>> get items =>
      widget.isReport ? LocalDb.reports : LocalDb.requests;

  // Display notification
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Display status label
  Widget statusLabel(String status) {
    Color color;

    switch (status.toLowerCase()) {
      case 'resolved':
      case 'released':
        color = Colors.green;
        break;

      case 'in progress':
        color = Colors.orange;
        break;

      case 'ready for pickup':
        color = Colors.blue;
        break;

      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        // Updated deprecated withOpacity property
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Update submission status
  Future<void> update(
    Map<String, dynamic> item,
    String status,
  ) async {
    try {
      await LocalDb.updateStatus(
        item['id'],
        widget.isReport,
        status,
      );

      if (!mounted) return;

      setState(() {});

      showMessage('Status updated to $status.');

    } catch (e) {
      if (!mounted) return;

      showMessage('Failed to update status.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isReport
              ? 'Review reports'
              : 'Review requests',
        ),
      ),

      body: items.isEmpty
          ? const Center(
              child: Text('No submissions yet.'),
            )

          : ListView(
              padding: const EdgeInsets.all(16),

              children: items.map((item) {

                final category = (
                  item['category'] ??
                  item['type'] ??
                  'Submission'
                ).toString();

                final description = (
                  item['description'] ??
                  'Purpose: ${item['purpose'] ?? ''}'
                ).toString();

                final location = (
                  item['location'] ??
                  item['method'] ??
                  '—'
                ).toString();

                final status = (
                  item['status'] ?? 'Submitted'
                ).toString();

                final statusOptions = widget.isReport
                    ? ['In progress', 'Resolved']
                    : [
                        'In progress',
                        'Ready for pickup',
                        'Released',
                      ];

                return Card(
                  color: Colors.white,
                  elevation: 0,

                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(14),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        // Submission category
                        Text(
                          category,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Description or purpose
                        Text(description),

                        const SizedBox(height: 6),

                        // Location or claiming method
                        Text(
                          'Location / claim: $location',
                        ),

                        const SizedBox(height: 10),

                        // Current status
                        statusLabel(status),

                        const SizedBox(height: 12),

                        const Text(
                          'Update status:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Status update buttons
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,

                          children: statusOptions.map((option) {
                            return OutlinedButton(
                              onPressed: () {
                                if (option != status) {
                                  update(item, option);
                                }
                              },

                              child: Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
