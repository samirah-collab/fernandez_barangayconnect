import 'package:flutter/material.dart';
import '../services/local_db.dart';
import 'chat_screen.dart';
import 'request_status_screen.dart';
import 'review_report_screen.dart';
import 'review_request_screen.dart';
import 'ui_helpers.dart';

class NotifItem {
  final String key, title, kind; // kind: ok | warn | doc
  final DateTime time;
  final String itemId; // the report/request this notification is about
  final bool isMessage; // true = chat message, opens the chat
  NotifItem(this.key, this.title, this.kind, this.time, {this.itemId = '', this.isMessage = false});
}

// Notifications the user has already tapped (kept while the app is open)
final Set<String> _readKeys = {};

// Notifications are built from the reports/requests (staff: everything, resident: only their own)
List<NotifItem> buildNotifs(Map<String, dynamic> user) {
  final staff = user['role'] == 'staff';
  final email = user['email'];
  final out = <NotifItem>[];

  for (final it in [...LocalDb.reports, ...LocalDb.requests]) {
    if (!staff && !isMine(it, email)) continue;
    final isRep = isReportItem(it);
    final s = displayStatus(it);
    final t = itemTitle(it);
    final time = updatedOf(it) ?? createdOf(it) ?? DateTime.now();
    String text;
    String kind;

    if (staff) {
      text = isRep ? 'New report: $t · ${it['location'] ?? ''}' : 'Certificate submitted: $t';
      kind = isRep ? 'warn' : 'doc';
    } else if (isRep) {
      if (s == 'Resolved') {
        text = '$t resolved';
        kind = 'ok';
      } else if (s == 'In progress') {
        text = '$t work started${(it['crew'] ?? '').toString().isEmpty ? '' : ' · ${it['crew']}'}';
        kind = 'warn';
      } else if (s == 'Under review') {
        text = '$t is being reviewed by staff';
        kind = 'warn';
      } else {
        text = 'Report received: $t';
        kind = 'doc';
      }
    } else {
      if (s == 'Ready for pickup') {
        text = '$t ready for pickup';
        kind = 'ok';
      } else if (s == 'Released') {
        text = '$t released';
        kind = 'ok';
      } else if (s == 'Returned') {
        text = '$t returned for correction';
        kind = 'warn';
      } else if (s == 'Under review') {
        text = '$t under review';
        kind = 'warn';
      } else {
        text = 'Request received';
        kind = 'doc';
      }
    }
    out.add(NotifItem('${it['id']}-$s', text, kind, time, itemId: '${it['id']}'));
  }

  // New chat messages from the other side
  final items = {for (final it in [...LocalDb.reports, ...LocalDb.requests]) it['id'].toString(): it};
  for (final m in LocalDb.messages) {
    final it = items[m['itemId'].toString()];
    if (it == null) continue;
    if (staff && m['from'] == 'resident') {
      out.add(NotifItem('msg-${m['id']}', 'Message from ${ownerName(it)}: ${m['text']}', 'doc', DateTime.tryParse('${m['time']}') ?? DateTime.now(), itemId: '${it['id']}', isMessage: true));
    } else if (!staff && m['from'] == 'staff' && isMine(it, email)) {
      out.add(NotifItem('msg-${m['id']}', 'Staff replied: ${m['text']}', 'doc', DateTime.tryParse('${m['time']}') ?? DateTime.now(), itemId: '${it['id']}', isMessage: true));
    }
  }

  out.sort((a, b) => b.time.compareTo(a.time));
  return out;
}

// When the user turns Notifications OFF in Profile, no badge is shown
int unreadCount(Map<String, dynamic> user) => !LocalDb.notificationsOn(user['email'])
    ? 0
    : buildNotifs(user).where((n) => !_readKeys.contains(n.key)).length;

class NotificationsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const NotificationsScreen({super.key, required this.user});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Tap a notification → mark as read and open the related screen
  void openNotif(NotifItem n) {
    setState(() => _readKeys.add(n.key));
    Map<String, dynamic>? item;
    for (final e in [...LocalDb.reports, ...LocalDb.requests]) {
      if (e['id'].toString() == n.itemId) item = e;
    }
    if (item == null) return;
    final staff = widget.user['role'] == 'staff';
    final Widget page = n.isMessage
        ? ChatScreen(item: item, user: widget.user)
        : staff
            ? (isReportItem(item) ? ReviewReportScreen(item: item, user: widget.user) : ReviewRequestScreen(item: item, user: widget.user))
            : RequestStatusScreen(item: item, user: widget.user);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget tile(NotifItem n) {
    final icon = n.kind == 'ok'
        ? Icons.check
        : n.kind == 'warn'
            ? Icons.warning_amber_rounded
            : Icons.description_outlined;
    final col = n.kind == 'ok'
        ? appOk
        : n.kind == 'warn'
            ? const Color(0xFFD99100)
            : const Color(0xFF2F6FDB);
    final unread = !_readKeys.contains(n.key);

    return Panel(
      onTap: () => openNotif(n),
      child: Row(children: [
        CircleAvatar(radius: 18, backgroundColor: col.withValues(alpha: 0.14), child: Icon(icon, color: col, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(notifTime(n.time), style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
          const SizedBox(height: 6),
          unread ? const CircleAvatar(radius: 4, backgroundColor: appDanger) : const SizedBox(height: 8),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!LocalDb.notificationsOn(widget.user['email'])) {
      return Scaffold(
        appBar: stdBar('Notifications'),
        body: const Center(child: Text('Notifications are turned off.\nTurn them on in Profile.', textAlign: TextAlign.center)),
      );
    }
    final all = buildNotifs(widget.user);
    final today = all.where((n) => isToday(n.time)).toList();
    final earlier = all.where((n) => !isToday(n.time)).toList();

    return Scaffold(
      appBar: stdBar('Notifications'),
      body: all.isEmpty
          ? const Center(child: Text('You have no notifications yet.'))
          : ListView(padding: const EdgeInsets.all(16), children: [
              if (today.isNotEmpty) ...[
                const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Today', style: TextStyle(color: Colors.blueGrey, fontSize: 12))),
                ...today.map(tile),
              ],
              if (earlier.isNotEmpty) ...[
                const Padding(padding: EdgeInsets.only(bottom: 8, top: 8), child: Text('Earlier', style: TextStyle(color: Colors.blueGrey, fontSize: 12))),
                ...earlier.map(tile),
              ],
            ]),
    );
  }
}