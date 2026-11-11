import 'package:flutter/material.dart';
import 'common_widgets.dart';
import 'request_status_screen.dart';
import 'resident_home_screen.dart';
import 'ui_helpers.dart';

// "Report sent" screen (also used to view a report's progress from My requests)
class ReportSentScreen extends StatelessWidget {
  final Map<String, dynamic> report;
  final Map<String, dynamic> user;
  final bool justSent;
  const ReportSentScreen({super.key, required this.report, required this.user, this.justSent = true});

  @override
  Widget build(BuildContext context) {
    final status = displayStatus(report);
    final states = status == 'New' ? [1, 0, 0] : (status == 'Under review' ? [1, 2, 0] : (status == 'In progress' ? [1, 1, 2] : [1, 1, 1]));
    const labels = ['Report received', 'Staff review', 'Action taken'];
    final steps = [for (var i = 0; i < 3; i++) TimelineStep(labels[i], null, states[i])];
    final note = (report['note'] ?? '').toString();
    final created = createdOf(report);

    return Scaffold(
      appBar: justSent ? null : stdBar('Report status'),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const SizedBox(height: 16),
          const Center(
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFFD7EFE0),
              child: CircleAvatar(radius: 26, backgroundColor: appOk, child: Icon(Icons.check, color: Colors.white, size: 30)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(justSent ? 'Report sent' : itemTitle(report),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              justSent
                  ? 'Brgy. ${barangayOf(report)} will review it within 2 working days.'
                  : '${created == null ? '' : '${fmtFull(created)} · '}$status',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          DashedBox(
            pad: const EdgeInsets.symmetric(vertical: 12),
            child: Center(child: Text(refCode(report), style: const TextStyle(color: appTeal, fontWeight: FontWeight.w600, fontSize: 13))),
          ),
          const SizedBox(height: 20),
          Panel(child: Timeline(steps)),
          if (note.isNotEmpty) Panel(color: appTealLight, child: Text('Staff note: $note', style: const TextStyle(fontSize: 13))),
          const SizedBox(height: 12),
          if (justSent) ...[
            // opens the live status screen: received → staff review → action taken
            BigButton('Track this report', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => RequestStatusScreen(item: report, user: user)),
              );
            }),
            const SizedBox(height: 10),
            BigButton('Back to home', () {
              Navigator.popUntil(context, (r) => r.isFirst);
              residentTab.value = 0;
            }, outline: true),
          ],
        ]),
      ),
    );
  }
}