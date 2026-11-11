import 'package:flutter/material.dart';
import '../services/local_db.dart';
import 'common_widgets.dart';
import 'request_status_screen.dart';
import 'ui_helpers.dart';

// "My requests" tab (shown inside the resident bottom navigation)
class MyRequestsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const MyRequestsScreen({super.key, required this.user});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  String filter = 'All';

  void open(Map<String, dynamic> it) {
    final Widget page = RequestStatusScreen(item: it, user: widget.user);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user['email'];
    final items = <Map<String, dynamic>>[
      if (filter != 'Certificates') ...LocalDb.reports.where((e) => isMine(e, email)),
      if (filter != 'Reports') ...LocalDb.requests.where((e) => isMine(e, email)),
    ];
    items.sort((a, b) => (b['created'] ?? '').toString().compareTo((a['created'] ?? '').toString()));

    return Column(children: [
      const TealHeader(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('My requests / reports', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          for (final t in ['All', 'Reports', 'Certificates'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(t),
                selected: filter == t,
                showCheckmark: false,
                selectedColor: const Color(0xFFD5ECEC),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: filter == t ? appTeal : Colors.black,
                  fontWeight: filter == t ? FontWeight.w600 : FontWeight.normal,
                ),
                onSelected: (_) => setState(() => filter = t),
              ),
            ),
        ]),
      ),
      Expanded(
        child: items.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inbox_outlined, size: 60, color: Colors.blueGrey.shade300),
                  const SizedBox(height: 10),
                  const Text('No reports or requests yet.', style: TextStyle(color: Colors.blueGrey)),
                ]),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: items.map((e) => ActivityCard(item: e, onTap: () => open(e))).toList(),
              ),
      ),
    ]);
  }
}