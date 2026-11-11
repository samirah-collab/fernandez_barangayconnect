import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/local_db.dart';
import 'assign_crew_screen.dart';
import 'chat_screen.dart';
import 'common_widgets.dart';
import 'ui_helpers.dart';

// Staff: one resident report
class ReviewReportScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> user; // the staff member
  const ReviewReportScreen({super.key, required this.item, required this.user});

  @override
  State<ReviewReportScreen> createState() => _ReviewReportScreenState();
}

class _ReviewReportScreenState extends State<ReviewReportScreen> {
  late String status = displayStatus(fresh);
  late final TextEditingController note = TextEditingController(text: (widget.item['note'] ?? '').toString());
  bool busy = false;

  // newest saved version of this report
  Map<String, dynamic> get fresh {
    for (final e in LocalDb.reports) {
      if (e['id'] == widget.item['id']) return e;
    }
    return widget.item;
  }

  @override
  void initState() {
    super.initState();
    _markUnderReview();
  }

  // When staff opens a NEW report it becomes "Under review",
  // so the resident can see that staff is reviewing it.
  Future<void> _markUnderReview() async {
    if ((fresh['status'] ?? 'Submitted') != 'Submitted') return;
    await LocalDb.updateItem(widget.item['id'], true, {'status': 'Under review'});
    if (mounted) setState(() => status = 'Under review');
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  // The app stores "Submitted"; the design calls it "New"
  String stored(String s) => s == 'New' ? 'Submitted' : s;

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await LocalDb.updateItem(widget.item['id'], true, {
        'status': stored(status),
        'note': note.text.trim(),
      });
      if (!mounted) return;
      snack(context, 'Report updated');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      snack(context, 'Failed to update report.');
    }
  }

  Future<void> openAssign() async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AssignCrewScreen(item: fresh, user: widget.user)),
    );
    if (done == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final it = fresh;
    final created = createdOf(it);
    final anonymous = it['owner'] == 'anonymous' || it['anonymous'] == true;
    final phone = (accountOf(it['owner'])?['phone'] ?? '').toString();

    return Scaffold(
      appBar: stdBar('Report', dashed: true),
      body: ListView(children: [
        Container(
          height: 140,
          color: const Color(0xFFCFE0E0),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.photo_camera_outlined, size: 36, color: Colors.blueGrey.shade400),
            const SizedBox(height: 4),
            const Text('No photo attached', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(itemTitle(it), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              StatusPill(displayStatus(it)),
            ]),
            Text(created == null ? '' : fmtFull(created), style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 10),
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((it['description'] ?? '').toString(), style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text('Reported by ${ownerName(it)}', style: const TextStyle(fontSize: 12, color: appTeal, fontWeight: FontWeight.w600)),
              ]),
            ),
            Panel(
              child: Row(children: [
                const Icon(Icons.location_on, color: appDanger),
                const SizedBox(width: 8),
                Expanded(child: Text((it['location'] ?? '—').toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              ]),
            ),

            // Resident asked for a response → staff can contact them here
            if (it['wantsResponse'] == true && !anonymous)
              Panel(
                color: const Color(0xFFFFF6DD),
                border: appYellow,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.support_agent, color: Color(0xFFD99100)),
                    SizedBox(width: 8),
                    Text('Resident wants a response', style: TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 6),
                  Text(phone.isEmpty ? 'No mobile number saved' : 'Mobile: $phone', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: BigButton('Message resident', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(item: it, user: widget.user))), outline: true),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: BigButton('Copy number', () {
                          Clipboard.setData(ClipboardData(text: phone));
                          snack(context, 'Number copied');
                        }, outline: true),
                      ),
                    ],
                  ]),
                ]),
              ),

            if ((it['crew'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Assigned: ${it['crew']}${it['urgent'] == true ? ' · Responding immediately' : ((it['responseTime'] ?? '').toString().isEmpty ? '' : ' · ${it['responseTime']}')}',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ),
            formLabel('Update status'),
            DropdownButtonFormField<String>(
              initialValue: status,
              items: const ['New', 'Under review', 'In progress', 'Resolved'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: busy ? null : (v) => setState(() => status = v ?? status),
            ),
            formLabel('Note to resident'),
            TextField(controller: note, maxLines: 3, enabled: !busy),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: BigButton('Assign crew', busy ? null : openAssign, outline: true)),
              const SizedBox(width: 10),
              Expanded(child: BigButton('Save update', busy ? null : save)),
            ]),
          ]),
        ),
      ]),
    );
  }
}
