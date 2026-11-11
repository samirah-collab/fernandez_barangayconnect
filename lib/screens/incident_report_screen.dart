import 'package:flutter/material.dart';
import '../services/local_db.dart';
import 'common_widgets.dart';
import 'report_sent_screen.dart';

class IncidentReportScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const IncidentReportScreen({
    super.key,
    required this.user,
  });

  @override
  State<IncidentReportScreen> createState() =>
      _IncidentReportScreenState();
}

class _IncidentReportScreenState
    extends State<IncidentReportScreen> {

  final TextEditingController description =
      TextEditingController();

  final TextEditingController location =
      TextEditingController();

  final List<String> categories = [
    'Flooding',
    'Garbage',
    'Road damage',
    'Noise',
    'Streetlight',
    'Peace & order',
    'Other',
  ];

  String category = 'Flooding';

  bool anonymous = false;
  bool wantsResponse = false; // resident asks staff to contact them
  bool busy = false;

  // Display message
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Submit incident report
  Future<void> submit() async {
    if (description.text.trim().isEmpty ||
        location.text.trim().isEmpty) {
      showMessage(
        'Please describe the problem and enter its location.',
      );
      return;
    }

    setState(() {
      busy = true;
    });

    try {
      final report = <String, dynamic>{
        'id': DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        'type': 'Incident report',
        'category': category,
        'description': description.text.trim(),
        'location': location.text.trim(),
        'anonymous': anonymous,
        'wantsResponse': wantsResponse && !anonymous,
        'owner': anonymous
            ? 'anonymous'
            : widget.user['email'],
        'submittedBy': widget.user['email'],
        'status': 'Submitted',
        'created': DateTime.now().toIso8601String(),
      };

      await LocalDb.addReport(report);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReportSentScreen(report: report, user: widget.user),
        ),
      );

    } catch (e) {
      if (!mounted) return;

      showMessage('Failed to submit report: $e');

    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    description.dispose();
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an incident'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [

          pageTitle('What happened?'),

          // Incident categories
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((c) {
              return ChoiceChip(
                label: Text(c),
                selected: category == c,
                selectedColor: appTeal,
                labelStyle: TextStyle(
                  color: category == c
                      ? Colors.white
                      : Colors.blueGrey,
                ),
                onSelected: busy
                    ? null
                    : (_) {
                        setState(() {
                          category = c;
                        });
                      },
              );
            }).toList(),
          ),

          // Problem description
          formLabel('Describe the problem'),

          TextField(
            controller: description,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tell us what happened...',
              border: OutlineInputBorder(),
            ),
          ),

          // Incident location
          formLabel('Location'),

          TextField(
            controller: location,
            decoration: const InputDecoration(
              hintText: 'Street, sitio, or landmark',
              prefixIcon: Icon(
                Icons.location_on_outlined,
              ),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          // Anonymous reporting
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Send without my name',
            ),
            subtitle: const Text(
              'Your identity will be hidden in the report.',
            ),
            value: anonymous,

            // Updated deprecated property
            activeThumbColor: appYellow,

            onChanged: busy
                ? null
                : (v) {
                    setState(() {
                      anonymous = v;
                      if (v) wantsResponse = false;
                    });
                  },
          ),

          // Resident wants staff to contact them about this report
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('I want a response from staff'),
            subtitle: Text(
              anonymous
                  ? 'Not available when sending without your name.'
                  : 'Staff may message or call you about this report.',
            ),
            value: wantsResponse && !anonymous,
            activeThumbColor: appYellow,
            onChanged: (busy || anonymous)
                ? null
                : (v) => setState(() => wantsResponse = v),
          ),

          const SizedBox(height: 10),

          // Submit button
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: appTeal,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: busy ? null : submit,
            child: busy
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Text('Submit report'),
          ),
        ],
      ),
    );
  }
}