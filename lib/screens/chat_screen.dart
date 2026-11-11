import 'dart:async';
import 'package:flutter/material.dart';
import '../services/local_db.dart';
import 'common_widgets.dart';
import 'ui_helpers.dart';

// Message thread about one report / request.
// Resident: "Message staff".  Staff: "Message resident".
class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> user;
  const ChatScreen({super.key, required this.item, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController text = TextEditingController();
  final ScrollController scroll = ScrollController();
  Timer? timer;

  bool get isStaff => widget.user['role'] == 'staff';
  String get itemId => widget.item['id'].toString();

  @override
  void initState() {
    super.initState();
    // pick up new replies while the chat is open
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    text.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final t = text.text.trim();
    if (t.isEmpty) return;
    text.clear();
    await LocalDb.addMessage({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'itemId': itemId,
      'from': isStaff ? 'staff' : 'resident',
      'sender': widget.user['email'],
      'text': t,
      'time': DateTime.now().toIso8601String(),
    });
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  Widget bubble(Map<String, dynamic> m) {
    final mine = (m['from'] == 'staff') == isStaff;
    final time = DateTime.tryParse('${m['time']}');
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: mine ? appTeal : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: mine ? null : Border.all(color: appLine),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${m['text']}', style: TextStyle(color: mine ? Colors.white : Colors.black, fontSize: 14)),
          if (time != null)
            Text(fmtFull(time), style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : Colors.blueGrey)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final msgs = LocalDb.messagesFor(itemId)
      ..sort((a, b) => '${a['time']}'.compareTo('${b['time']}'));
    final title = isStaff ? ownerName(widget.item) : 'Barangay staff';

    return Scaffold(
      appBar: stdBar(title),
      body: Column(children: [
        Container(
          width: double.infinity,
          color: appTealLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('${itemTitle(widget.item)} · ${refCode(widget.item)}', style: const TextStyle(fontSize: 12, color: appTeal, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: msgs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isStaff ? 'No messages yet. Write to the resident below.' : 'No messages yet. Write to the barangay staff below.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ),
                )
              : ListView(
                  controller: scroll,
                  padding: const EdgeInsets.all(16),
                  children: msgs.map(bubble).toList(),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: text,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => send(),
                  decoration: const InputDecoration(hintText: 'Type your message', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: appTeal),
                onPressed: send,
                icon: const Icon(Icons.send, size: 20),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
