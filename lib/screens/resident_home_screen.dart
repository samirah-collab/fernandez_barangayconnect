import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/local_db.dart';
import 'common_widgets.dart';
import 'incident_report_screen.dart';
import 'certificate_request_screen.dart';
import 'my_requests_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'request_status_screen.dart';
import 'ui_helpers.dart';

// Current bottom-navigation tab of the resident app (0 Home, 1 My requests/reports, 2 Profile).
// Other screens set this to jump to a tab.
final ValueNotifier<int> residentTab = ValueNotifier<int>(0);

class ResidentHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ResidentHomeScreen({super.key, required this.user});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  @override
  void initState() {
    super.initState();
    residentTab.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: residentTab,
      builder: (context, tab, _) {
        final pages = <Widget>[
          _HomeTab(user: widget.user),
          MyRequestsScreen(user: widget.user),
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
              onDestinationSelected: (i) => residentTab.value = i,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: appTeal), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description, color: appTeal), label: 'My requests'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: appTeal), label: 'Profile'),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────────── HOME TAB ─────────────────────────
class _HomeTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const _HomeTab({required this.user});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  void open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget actionCard(Color accent, IconData icon, Color iconColor, String title, String sub, String foot, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(children: [
                Container(width: 5, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Icon(icon, color: iconColor, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 3),
                          Text(sub, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          const SizedBox(height: 6),
                          Text(foot, style: const TextStyle(fontSize: 12, color: appTeal, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );

  void openItem(Map<String, dynamic> it) {
    open(RequestStatusScreen(item: it, user: widget.user));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final first = (user['name'] ?? 'Resident').toString().split(' ').first;
    final email = user['email'];

    final recent = <Map<String, dynamic>>[
      ...LocalDb.reports.where((e) => isMine(e, email)),
      ...LocalDb.requests.where((e) => isMine(e, email)),
    ]..sort((a, b) => (b['created'] ?? '').toString().compareTo((a['created'] ?? '').toString()));

    final unread = unreadCount(user);

    return Column(children: [
      TealHeader(
        amberLine: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('Magandang umaga, $first!',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            Stack(children: [
              IconButton(
                onPressed: () => open(NotificationsScreen(user: user)),
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(30)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.location_on, color: appYellow, size: 16),
              const SizedBox(width: 4),
              Text('Brgy. ${user['barangay'] ?? 'Abongan'}, Taytay', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          actionCard(appYellow, Icons.warning_amber_rounded, appDanger, 'Report an incident', 'Flooding, garbage, noise, broken lights', 'Takes about 2 minutes',
              () => open(IncidentReportScreen(user: user))),
          actionCard(appTeal, Icons.description_outlined, appTeal, 'Request a certificate', 'Clearance, residency, indigency', 'Pick up at the barangay hall',
              () => open(CertificateRequestScreen(user: user))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Recent activity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            TextButton(onPressed: () => residentTab.value = 1, child: const Text('See all')),
          ]),
          if (recent.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No activity yet.', style: TextStyle(color: Colors.blueGrey))),
          ...recent.take(2).map((e) => ActivityCard(item: e, onTap: () => openItem(e))),
        ]),
      ),
    ]);
  }
}