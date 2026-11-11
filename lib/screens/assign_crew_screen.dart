import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/local_db.dart';
import 'chat_screen.dart';
import 'common_widgets.dart';
import 'ui_helpers.dart';

const List<String> reportCrews = [
  'Drainage crew',
  'Sanitation crew',
  'Electrical crew',
  'Road maintenance crew',
  'Peace & order team',
];

const List<String> responseTimes = ['Within 24 hours', 'Within 2–3 days', 'Scheduled'];

// Suggested crew for each incident category
String suggestedCrew(String category) {
  switch (category) {
    case 'Flooding':
      return 'Drainage crew';
    case 'Garbage':
      return 'Sanitation crew';
    case 'Streetlight':
      return 'Electrical crew';
    case 'Road damage':
      return 'Road maintenance crew';
    case 'Noise':
    case 'Peace & order':
      return 'Peace & order team';
    default:
      return reportCrews.first;
  }
}

// Staff: assign a crew to a report, choose if it must be responded to immediately,
// and contact the resident who asked for a response.
class AssignCrewScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> user; // the staff member
  const AssignCrewScreen({super.key, required this.item, required this.user});

  @override
  State<AssignCrewScreen> createState() => _AssignCrewScreenState();
}

class _AssignCrewScreenState extends State<AssignCrewScreen> {
  late String crew = (widget.item['crew'] ?? '').toString().isNotEmpty
      ? widget.item['crew'].toString()
      : suggestedCrew((widget.item['category'] ?? '').toString());
  late bool urgent = widget.item['urgent'] == true;
  late String responseTime = responseTimes.contains(widget.item['responseTime']) ? widget.item['responseTime'] as String : responseTimes.first;
  late final TextEditingController instructions = TextEditingController(text: (widget.item['crewNote'] ?? '').toString());
  bool busy = false;

  bool get anonymous => widget.item['owner'] == 'anonymous' || widget.item['anonymous'] == true;
  bool get wantsResponse => widget.item['wantsResponse'] == true && !anonymous;

  @override
  void dispose() {
    instructions.dispose();
    super.dispose();
  }

  Future<void> assign() async {
    setState(() => busy = true);
    try {
      await LocalDb.updateItem(widget.item['id'], true, {
        'status': 'In progress',
        'crew': crew,
        'urgent': urgent,
        'responseTime': urgent ? 'Immediately' : responseTime,
        'crewNote': instructions.text.trim(),
      });
      // tell the resident right away if they asked for a response
      if (wantsResponse) {
        await LocalDb.addMessage({
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'itemId': widget.item['id'].toString(),
          'from': 'staff',
          'sender': widget.user['email'],
          'text': 'We assigned the $crew to your report. ${urgent ? 'They are responding immediately.' : 'Expected response: ${responseTime.toLowerCase()}.'}',
          'time': DateTime.now().toIso8601String(),
        });
      }
      if (!mounted) return;
      snack(context, '$crew assigned');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      snack(context, 'Failed to assign crew.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final acc = accountOf(it['owner']);
    final phone = (acc?['phone'] ?? '').toString();

    return Scaffold(
      appBar: stdBar('Assign crew', dashed: true),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(itemTitle(it), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${it['location'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ]),
        ),
        const Text('Choose a crew', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 8),
        for (final c in reportCrews)
          Panel(
            onTap: busy ? null : () => setState(() => crew = c),
            color: crew == c ? appTealLight : Colors.white,
            border: crew == c ? appTeal : appLine,
            borderWidth: crew == c ? 1.5 : 1,
            pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Icon(crew == c ? Icons.radio_button_checked : Icons.radio_button_off, color: crew == c ? appTeal : Colors.grey),
              const SizedBox(width: 10),
              Expanded(child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
              if (c == suggestedCrew((it['category'] ?? '').toString()))
                const Text('Suggested', style: TextStyle(fontSize: 11, color: appTeal, fontWeight: FontWeight.w600)),
            ]),
          ),
        const SizedBox(height: 4),
        Panel(
          pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(children: [
            const Icon(Icons.bolt, color: appDanger),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Respond immediately', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('Crew goes to the location right away', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
              ]),
            ),
            Switch(
              value: urgent,
              activeThumbColor: Colors.white,
              activeTrackColor: appDanger,
              onChanged: busy ? null : (v) => setState(() => urgent = v),
            ),
          ]),
        ),
        if (!urgent) ...[
          formLabel('Response time'),
          DropdownButtonFormField<String>(
            initialValue: responseTime,
            items: responseTimes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: busy ? null : (v) => setState(() => responseTime = v ?? responseTime),
          ),
        ],
        formLabel('Instructions for the crew'),
        TextField(controller: instructions, maxLines: 3, enabled: !busy, decoration: const InputDecoration(hintText: 'Optional')),
        const SizedBox(height: 14),

        // ── Contact the resident who wants a response ──
        if (wantsResponse)
          Panel(
            color: const Color(0xFFFFF6DD),
            border: appYellow,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.support_agent, color: Color(0xFFD99100)),
                SizedBox(width: 8),
                Text('Resident wants a response', style: TextStyle(fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              kvRow('Resident', ownerName(it)),
              kvRow('Mobile', phone.isEmpty ? 'No number saved' : phone),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: BigButton('Message', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(item: it, user: widget.user))), outline: true),
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
          )
        else if (anonymous)
          const Panel(child: Text('This report was sent anonymously, so the resident cannot be contacted.', style: TextStyle(fontSize: 12, color: Colors.blueGrey))),
        const SizedBox(height: 6),
        BigButton(busy ? 'Assigning...' : 'Assign crew', busy ? null : assign),
      ]),
    );
  }
}
