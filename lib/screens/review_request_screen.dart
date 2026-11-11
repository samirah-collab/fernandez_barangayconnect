import 'package:flutter/material.dart';
import '../services/local_db.dart';
import 'chat_screen.dart';
import 'common_widgets.dart';
import 'id_picker.dart';
import 'ui_helpers.dart';

// Staff: review one certificate request
class ReviewRequestScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> user; // the staff member
  const ReviewRequestScreen({super.key, required this.item, required this.user});

  @override
  State<ReviewRequestScreen> createState() => _ReviewRequestScreenState();
}

class _ReviewRequestScreenState extends State<ReviewRequestScreen> {
  bool busy = false;

  Future<void> setStatus(String status, {String? note, required String message}) async {
    setState(() => busy = true);
    try {
      await LocalDb.updateItem(widget.item['id'], false, {
        'status': status,
        if (note != null) 'note': note,
      });
      if (!mounted) return;
      snack(context, message);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      snack(context, 'Failed to update request.');
    }
  }

  void returnForCorrection() {
    final reason = TextEditingController();
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Return for correction'),
        content: TextField(controller: reason, maxLines: 3, decoration: const InputDecoration(hintText: 'What needs to be corrected?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (reason.text.trim().isEmpty) return;
              Navigator.pop(d);
              setStatus('Returned', note: reason.text.trim(), message: 'Returned to resident');
            },
            child: const Text('Return'),
          ),
        ],
      ),
    );
  }

  void enlargeId() {
    final img = (widget.item['idImage'] ?? '').toString();
    if (img.isEmpty) {
      snack(context, 'The resident did not upload an ID photo.');
      return;
    }
    showPhotoDialog(context, 'Valid ID', img);
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final status = displayStatus(it);
    final acc = accountOf(it['owner']);
    final fee = it['fee'] is int ? it['fee'] as int : feeFor((it['type'] ?? '').toString());
    final feePaid = it['feePaid'] == true;

    Widget actions;
    if (status == 'Ready for pickup') {
      actions = BigButton('Mark as released', busy ? null : () => setStatus('Released', message: 'Marked as released'));
    } else if (status == 'Released' || status == 'Returned') {
      actions = Center(child: Text('This request is ${status.toLowerCase()}.', style: const TextStyle(color: Colors.blueGrey)));
    } else {
      actions = Column(children: [
        BigButton('Approve and mark ready', busy ? null : () => setStatus('Ready for pickup', message: 'Marked ready for pickup')),
        const SizedBox(height: 10),
        BigButton('Return for correction', busy ? null : returnForCorrection, outline: true),
      ]);
    }

    return Scaffold(
      appBar: stdBar('Request', dashed: true),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(itemTitle(it), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(peso(fee), style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 6),
            StatusPill(status),
          ]),
        ),
        Panel(
          child: Column(children: [
            kvRow('Applicant', ownerName(it)),
            kvRow('Address', (acc?['address'] ?? '—').toString()),
            kvRow('Purpose', (it['purpose'] ?? '—').toString()),
            kvRow('Claim method', (it['method'] ?? '—').toString()),
            kvRow('Payment', (it['paymentMethod'] ?? '—').toString()),
            if ((it['paymentRef'] ?? '').toString().isNotEmpty) kvRow('Ref. no.', it['paymentRef'].toString()),
          ]),
        ),
        const Padding(padding: EdgeInsets.only(bottom: 6, top: 4), child: Text('Valid ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey))),
        InkWell(
          onTap: enlargeId,
          child: Container(
            height: 110,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: const Color(0xFFCFE0E0), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: (it['idImage'] ?? '').toString().isNotEmpty
                ? photoFromBase64(it['idImage'].toString(), height: 110)
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_outline, size: 34, color: Colors.blueGrey.shade600),
                    const Text('No ID uploaded', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  ]),
          ),
        ),
        const SizedBox(height: 10),
        Panel(
          child: Row(children: [
            const Expanded(child: Text('Payment received', style: TextStyle(fontWeight: FontWeight.w600))),
            Switch(
              value: feePaid,
              activeThumbColor: Colors.white,
              activeTrackColor: appTeal,
              onChanged: busy
                  ? null
                  : (v) async {
                      setState(() => it['feePaid'] = v);
                      await LocalDb.updateItem(it['id'], false, {'feePaid': v}, touch: false);
                    },
            ),
          ]),
        ),
        const SizedBox(height: 6),
        BigButton('Message resident', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(item: it, user: widget.user))), outline: true),
        const SizedBox(height: 10),
        actions,
      ]),
    );
  }
}