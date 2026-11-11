// Shared helpers + widgets for the new screens (reports, requests, notifications, staff).
import 'package:flutter/material.dart';
import '../services/local_db.dart';
import 'common_widgets.dart';

const Color appDanger = Color(0xFFD64545);
const Color appOk = Color(0xFF2E9E5B);
const Color appLine = Color(0xFFDDE8E6);
const Color appTealLight = Color(0xFFE3F0F0);

// ───────────── certificates ─────────────
class CertType {
  final String name;
  final int fee;
  final String ready;
  const CertType(this.name, this.fee, this.ready);
}

const List<CertType> certTypes = [
  CertType('Barangay Clearance', 50, '1–2 days'),
  CertType('Certificate of Residency', 30, '1 day'),
  CertType('Certificate of Indigency', 0, '1 day'),
  CertType('Business Clearance', 200, '3 days'),
];

// Ways to pay a certificate fee
const List<String> paymentMethods = ['Cash at barangay hall', 'GCash', 'Maya'];
const String eWalletNumber = '09XX XXX XXXX';

int feeFor(String type) {
  for (final t in certTypes) {
    if (t.name == type) return t.fee;
  }
  return 50;
}

String peso(int f) => f == 0 ? 'Free' : '₱$f.00';

// ───────────── dates ─────────────
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';
String clock(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
}

String fmtFull(DateTime d) => '${fmtDate(d)}, ${clock(d)}';

String ago(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  return fmtDate(d);
}

bool isToday(DateTime d) {
  final n = DateTime.now();
  return d.year == n.year && d.month == n.month && d.day == n.day;
}

String notifTime(DateTime d) {
  final n = DateTime.now();
  final days = DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (days == 0) return clock(d);
  if (days == 1) return 'Yesterday';
  return fmtDate(d);
}

// ───────────── data helpers ─────────────
DateTime? createdOf(Map<String, dynamic> item) => DateTime.tryParse((item['created'] ?? '').toString());
DateTime? updatedOf(Map<String, dynamic> item) => DateTime.tryParse((item['updated'] ?? '').toString());

// reports have a 'category'; certificate requests do not
bool isReportItem(Map<String, dynamic> item) => item.containsKey('category');

bool isMine(Map<String, dynamic> item, dynamic email) => item['owner'] == email || item['submittedBy'] == email;

String itemTitle(Map<String, dynamic> item) =>
    ((isReportItem(item) ? item['category'] : item['type']) ?? 'Request').toString();

// Status words used in the Figma design
String displayStatus(Map<String, dynamic> item) {
  final s = (item['status'] ?? 'Submitted').toString();
  if (isReportItem(item)) return s == 'Submitted' ? 'New' : s;
  return s == 'In progress' ? 'Under review' : s;
}

Color statusColor(String s) {
  switch (s) {
    case 'Ready for pickup':
    case 'Resolved':
      return appOk;
    case 'In progress':
    case 'Under review':
      return const Color(0xFFD99100);
    case 'New':
    case 'Returned':
      return appDanger;
    case 'Submitted':
      return const Color(0xFF2F6FDB);
    default:
      return Colors.blueGrey;
  }
}

Map<String, dynamic>? accountOf(dynamic email) {
  for (final a in LocalDb.accounts) {
    if (a['email'] == email) return a;
  }
  return null;
}

String ownerName(Map<String, dynamic> item) {
  final owner = (item['owner'] ?? '').toString();
  if (owner == 'anonymous' || item['anonymous'] == true) return 'Anonymous';
  return (accountOf(owner)?['name'] ?? owner).toString();
}

String barangayOf(Map<String, dynamic> item) {
  final acc = accountOf(item['owner']) ?? accountOf(item['submittedBy']);
  return (acc?['barangay'] ?? 'Abongan').toString();
}

String shortName(String name) {
  final p = name.trim().split(RegExp(r'\s+'));
  return p.length < 2 ? name : '${p.first[0]}. ${p.last}';
}

String initialsOf(String name) {
  final p = name.trim().split(RegExp(r'\s+'));
  if (p.isEmpty || p.first.isEmpty) return 'U';
  return (p.first[0] + (p.length > 1 ? p.last[0] : '')).toUpperCase();
}

String refCode(Map<String, dynamic> item) {
  final id = (item['id'] ?? '').toString();
  final tail = id.length > 5 ? id.substring(id.length - 5) : id;
  return isReportItem(item) ? 'RP-2026-$tail' : 'BC-CRT-2026-$tail';
}

void snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

// ───────────── widgets ─────────────
PreferredSizeWidget stdBar(String title, {bool dashed = false}) => AppBar(
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      bottom: dashed ? const PreferredSize(preferredSize: Size.fromHeight(2), child: DashedLine()) : null,
    );

class TealHeader extends StatelessWidget {
  final Widget child;
  final bool amberLine;
  const TealHeader({super.key, required this.child, this.amberLine = true});
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: double.infinity,
          color: appTeal,
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 18),
          child: child,
        ),
        if (amberLine) Container(height: 2, color: appYellow),
      ]);
}

class DashedLine extends StatelessWidget {
  final Color color;
  const DashedLine({super.key, this.color = appYellow});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, box) {
        final n = (box.maxWidth / 6).floor();
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(n, (_) => Container(width: 3, height: 1.5, color: color)));
      });
}

class _DashPainter extends CustomPainter {
  final Color color;
  final Color? fill;
  final double radius;
  _DashPainter(this.color, this.fill, this.radius);
  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    if (fill != null) canvas.drawRRect(rr, Paint()..color = fill!);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in (Path()..addRRect(rr)).computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color || old.fill != fill;
}

class DashedBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color? fill;
  final VoidCallback? onTap;
  final EdgeInsets pad;
  const DashedBox({super.key, required this.child, this.color = appTeal, this.fill, this.onTap, this.pad = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: CustomPaint(painter: _DashPainter(color, fill, 12), child: Container(width: double.infinity, padding: pad, child: child)),
      );
}

class Panel extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color border;
  final double borderWidth;
  final EdgeInsets pad;
  const Panel(
      {super.key,
      required this.child,
      this.onTap,
      this.color = Colors.white,
      this.border = appLine,
      this.borderWidth = 1,
      this.pad = const EdgeInsets.all(14)});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: pad,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: borderWidth)),
              child: child,
            ),
          ),
        ),
      );
}

class StatusPill extends StatelessWidget {
  final String text;
  const StatusPill(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = statusColor(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
    );
  }
}

// Card used in My requests and the staff lists
class ActivityCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const ActivityCard({super.key, required this.item, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final d = createdOf(item);
    return Panel(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(itemTitle(item), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          Text(d == null ? '' : fmtDate(d), style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
        ]),
        const SizedBox(height: 12),
        DashedLine(color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Row(children: [
          StatusPill(displayStatus(item)),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.blueGrey),
        ]),
      ]),
    );
  }
}

class TimelineStep {
  final String label;
  final String? sub;
  final int state; // 0 pending, 1 done, 2 current
  TimelineStep(this.label, this.sub, this.state);
}

class Timeline extends StatelessWidget {
  final List<TimelineStep> steps;
  const Timeline(this.steps, {super.key});

  Widget dot(int s) {
    if (s == 1) {
      return const CircleAvatar(radius: 10, backgroundColor: appOk, child: Icon(Icons.check, size: 13, color: Colors.white));
    }
    if (s == 2) return const CircleAvatar(radius: 10, backgroundColor: appYellow);
    return Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400, width: 2)));
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  width: 28,
                  child: Column(children: [
                    dot(steps[i].state),
                    if (i < steps.length - 1) Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
                  ])),
              const SizedBox(width: 8),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(steps[i].label, style: TextStyle(fontWeight: FontWeight.w600, color: steps[i].state == 0 ? Colors.grey : Colors.black)),
                  if (steps[i].sub != null) Text(steps[i].sub!, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ]),
              )),
            ]),
          ),
      ]);
}

Widget kvRow(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 100, child: Text(k, style: const TextStyle(color: Colors.blueGrey, fontSize: 13))),
        Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );

// Big outlined / filled button used across the new screens
class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outline;
  final Color color;
  const BigButton(this.label, this.onTap, {super.key, this.outline = false, this.color = appTeal});
  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    const txt = TextStyle(fontWeight: FontWeight.w600, fontSize: 14);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: outline
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color), shape: shape, backgroundColor: Colors.white),
              onPressed: onTap,
              child: Text(label, style: txt))
          : FilledButton(
              style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: shape),
              onPressed: onTap,
              child: Text(label, style: txt)),
    );
  }
}