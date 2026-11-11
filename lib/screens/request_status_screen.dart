import 'dart:async';
import 'package:flutter/material.dart';
import '../services/local_db.dart';
import 'chat_screen.dart';
import 'common_widgets.dart';
import 'ui_helpers.dart';

// Status screen for BOTH certificate requests and incident reports (resident side).
// Shows the live progress and a "Message staff" button (no QR any more).
class RequestStatusScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> user;
  const RequestStatusScreen({super.key, required this.item, required this.user});

  @override
  State<RequestStatusScreen> createState() => _RequestStatusScreenState();
}

class _RequestStatusScreenState extends State<RequestStatusScreen> {
  static const certStages = ['Submitted', 'Received by barangay', 'Under review', 'Ready for pickup', 'Released'];
  static const reportStages = ['Report received', 'Staff review', 'Action taken'];

  Timer? timer;

  @override
  void initState() {
    super.initState();
    // refresh so the resident sees staff updates while this screen is open
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // always read the newest saved version of this item
  Map<String, dynamic> get item {
    final id = widget.item['id'];
    final list = isReportItem(widget.item) ? LocalDb.reports : LocalDb.requests;
    for (final e in list) {
      if (e['id'] == id) return e;
    }
    return widget.item;
  }

  int certStageOf(String s) =>
      s == 'Submitted' ? 0 : s == 'Under review' ? 2 : s == 'Ready for pickup' ? 3 : s == 'Released' ? 4 : 1;

  int reportStageOf(String s) => s == 'New' ? 0 : s == 'Under review' ? 1 : 2;

  void messageStaff() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(item: item, user: widget.user)),
      ).then((_) {
        if (mounted) setState(() {});
      });

  @override
  Widget build(BuildContext context) {
    final it = item;
    final isReport = isReportItem(it);
    final status = displayStatus(it);
    final created = createdOf(it);
    final history = it['history'] is Map ? Map<String, dynamic>.from(it['history'] as Map) : <String, dynamic>{};
    DateTime? at(String k) => history[k] == null ? null : DateTime.tryParse(history[k].toString());

    final List<String> stages;
    final int idx;
    final List<DateTime?> times;
    if (isReport) {
      stages = reportStages;
      idx = reportStageOf(status);
      times = [created, at('Under review'), at('In progress') ?? at('Resolved')];
    } else {
      stages = certStages;
      idx = certStageOf(status);
      final firstAction = history.values
          .map((v) => DateTime.tryParse(v.toString()))
          .whereType<DateTime>()
          .fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
      times = [created, firstAction, at('In progress') ?? at('Under review'), at('Ready for pickup'), at('Released')];
    }
    final last = stages.length - 1;

    String? subFor(int i) {
      if (isReport && i == 2 && idx == 2) {
        final crew = (it['crew'] ?? '').toString();
        final parts = <String>[
          if (times[i] != null) fmtFull(times[i]!),
          if (crew.isNotEmpty) 'Assigned: $crew',
          if (it['urgent'] == true) 'Responding immediately',
        ];
        return parts.isEmpty ? null : parts.join('\n');
      }
      return i <= idx && times[i] != null ? fmtFull(times[i]!) : null;
    }

    final steps = <TimelineStep>[
      for (var i = 0; i < stages.length; i++)
        TimelineStep(
          stages[i],
          subFor(i),
          i < idx ? 1 : (i == idx ? (idx == last && (!isReport || status == 'Resolved') ? 1 : 2) : 0),
        ),
    ];

    final fee = it['fee'] is int ? it['fee'] as int : feeFor((it['type'] ?? '').toString());
    final note = (it['note'] ?? '').toString();

    return Scaffold(
      appBar: stdBar(isReport ? 'Report status' : 'Request status'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(itemTitle(it), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              if (!isReport) Text(peso(fee), style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            Text(refCode(it), style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            if (isReport && (it['location'] ?? '').toString().isNotEmpty)
              Text('Location: ${it['location']}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            StatusPill(status),
          ]),
        ),
        if (status == 'Returned')
          Panel(
            color: const Color(0xFFFBE9E9),
            child: Text('Returned for correction: $note', style: const TextStyle(fontSize: 13)),
          ),
        if (isReport && note.isNotEmpty)
          Panel(color: appTealLight, child: Text('Staff note: $note', style: const TextStyle(fontSize: 13))),
        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Progress', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        Timeline(steps),
        const SizedBox(height: 8),
        if (!isReport) ...[
          if ((it['paymentMethod'] ?? '').toString().isNotEmpty)
            Panel(
              child: Row(children: [
                const Icon(Icons.payments_outlined, color: appTeal),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Payment: ${it['paymentMethod']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if ((it['paymentRef'] ?? '').toString().isNotEmpty)
                      Text('Ref. no. ${it['paymentRef']}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    if (fee > 0) Text(it['feePaid'] == true ? 'Payment received' : 'Waiting for payment confirmation', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  ]),
                ),
              ]),
            ),
          Panel(
            child: Row(children: [
              const Icon(Icons.location_on, color: appDanger),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pick up at Brgy. ${barangayOf(it)} Hall', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Text('Mon–Fri, 8:00 AM–5:00 PM. Bring a valid ID.', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ]),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 8),
        BigButton('Message staff', messageStaff),
      ]),
    );
  }
}
