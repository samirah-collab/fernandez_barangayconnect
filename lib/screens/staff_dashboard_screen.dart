import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/local_db.dart';
import 'common_widgets.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'review_report_screen.dart';
import 'review_request_screen.dart';
import 'ui_helpers.dart';

// Current bottom-navigation tab of the staff app (0 Dashboard, 1 Reports, 2 Requests, 3 Profile)
final ValueNotifier<int> staffTab = ValueNotifier<int>(0);

void _openReview(BuildContext context, Map<String, dynamic> user, Map<String, dynamic> it, VoidCallback refresh) {
  final Widget page = isReportItem(it) ? ReviewReportScreen(item: it, user: user) : ReviewRequestScreen(item: it, user: user);
  Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => refresh());
}

class StaffDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const StaffDashboardScreen({super.key, required this.user});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  @override
  void initState() {
    super.initState();
    staffTab.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: staffTab,
      builder: (context, tab, _) {
        final pages = <Widget>[
          _DashboardTab(user: widget.user),
          _ListTab(reports: true, user: widget.user),
          _ListTab(reports: false, user: widget.user),
          ProfileScreen(user: widget.user),
        ];
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            body: pages[tab],
            bottomNavigationBar: NavigationBar(
              selectedIndex: tab,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFD5ECEC),
              onDestinationSelected: (i) => staffTab.value = i,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: appTeal), label: 'Dashboard'),
                NavigationDestination(icon: Icon(Icons.warning_amber_rounded), label: 'Reports'),
                NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description, color: appTeal), label: 'Requests'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: appTeal), label: 'Profile'),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────────── DASHBOARD TAB ─────────────────────────
class _DashboardTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const _DashboardTab({required this.user});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  void refresh() {
    if (mounted) setState(() {});
  }

  Widget stat(String number, String label, Color color) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(children: [
            Container(width: 5, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(number, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ]),
              ),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final reports = LocalDb.reports;
    final requests = LocalDb.requests;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    final newReports = reports.where((e) => displayStatus(e) == 'New').length;
    final toReview = requests.where((e) => displayStatus(e) == 'Submitted' || displayStatus(e) == 'Under review').length;
    final inProgress = reports.where((e) => displayStatus(e) == 'In progress').length;
    final resolved = reports.where((e) {
      if (displayStatus(e) != 'Resolved') return false;
      final d = updatedOf(e) ?? createdOf(e);
      return d != null && d.isAfter(weekAgo);
    }).length;

    // Needs action: new reports + requests waiting for review, newest first
    final needs = <Map<String, dynamic>>[
      ...reports.where((e) => displayStatus(e) == 'New' || displayStatus(e) == 'Under review'),
      ...requests.where((e) => displayStatus(e) == 'Submitted' || displayStatus(e) == 'Under review'),
    ]..sort((a, b) => (b['created'] ?? '').toString().compareTo((a['created'] ?? '').toString()));

    final unread = unreadCount(widget.user);

    return Column(children: [
      TealHeader(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Barangay staff', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Brgy. ${widget.user['barangay'] ?? 'Abongan'}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
          ),
          Stack(children: [
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(user: widget.user))).then((_) => refresh()),
              icon: const Icon(Icons.notifications_none, color: Colors.white),
            ),
            if (unread > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: appYellow, shape: BoxShape.circle)),
              ),
          ]),
        ]),
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.9,
            children: [
              stat('$newReports', 'New reports', appDanger),
              stat('$toReview', 'Certificates to review', appYellow),
              stat('$inProgress', 'In progress', const Color(0xFF2F6FDB)),
              stat('$resolved', 'Resolved this week', appOk),
            ],
          ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Needs action', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            TextButton(onPressed: () => staffTab.value = 1, child: const Text('See all')),
          ]),
          if (needs.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('All caught up. No new reports or requests.', style: TextStyle(color: Colors.blueGrey))),
          ...needs.take(6).map((it) {
            final isRep = isReportItem(it);
            final d = createdOf(it);
            final title = isRep
                ? '${itemTitle(it)} · ${it['location'] ?? ''}'
                : '${itemTitle(it)} · ${shortName(ownerName(it))}';
            final sub = '${d == null ? '' : ago(d)}'
                '${!isRep && it['idUploaded'] == true ? ' · ID uploaded' : ''}'
                '${isRep && it['wantsResponse'] == true ? ' · Wants response' : ''}';
            return Panel(
              onTap: () => _openReview(context, widget.user, it, refresh),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(sub, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  StatusPill(displayStatus(it)),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: Colors.blueGrey),
                ]),
              ]),
            );
          }),
        ]),
      ),
    ]);
  }
}

// ───────────────────────── REPORTS / CERTIFICATES TABS ─────────────────────────
class _ListTab extends StatefulWidget {
  final bool reports;
  final Map<String, dynamic> user;
  const _ListTab({required this.reports, required this.user});

  @override
  State<_ListTab> createState() => _ListTabState();
}

class _ListTabState extends State<_ListTab> {
  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = [...(widget.reports ? LocalDb.reports : LocalDb.requests)]
      ..sort((a, b) => (b['created'] ?? '').toString().compareTo((a['created'] ?? '').toString()));

    return Column(children: [
      TealHeader(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(widget.reports ? 'Reports' : 'Requests',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        ),
      ),
      Expanded(
        child: items.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inbox_outlined, size: 60, color: Colors.blueGrey.shade300),
                  const SizedBox(height: 10),
                  Text(widget.reports ? 'No resident reports yet.' : 'No resident requests yet.', style: const TextStyle(color: Colors.blueGrey)),
                ]),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: items.map((e) => ActivityCard(item: e, onTap: () => _openReview(context, widget.user, e, refresh))).toList(),
              ),
      ),
    ]);
  }
}