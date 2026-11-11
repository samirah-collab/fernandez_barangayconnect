import 'package:flutter/material.dart';
import '../services/local_db.dart';
import 'common_widgets.dart';
import 'ui_helpers.dart';
import 'welcome_screen.dart';

// Profile tab (shown inside the resident and staff bottom navigation)
class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late bool notificationsOn = LocalDb.notificationsOn(widget.user['email']);
  String language = 'English';

  // Notifications row with an ON / OFF switch (not a menu arrow)
  Widget notificationsRow() => Panel(
        pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(children: [
          const Icon(Icons.notifications_none, color: appTeal),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(notificationsOn ? 'On' : 'Off', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ]),
          ),
          Switch(
            value: notificationsOn,
            activeThumbColor: Colors.white,
            activeTrackColor: appTeal,
            onChanged: (v) {
              setState(() => notificationsOn = v);
              LocalDb.setNotificationsOn(widget.user['email'], v);
            },
          ),
        ]),
      );

  Widget row(IconData icon, String title, String sub, VoidCallback onTap) => Panel(
        onTap: onTap,
        child: Row(children: [
          Icon(icon, color: appTeal),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(sub, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: Colors.blueGrey),
        ]),
      );

  void editProfile() {
    final u = widget.user;
    final name = TextEditingController(text: (u['name'] ?? '').toString());
    final phone = TextEditingController(text: (u['phone'] ?? '').toString());
    final address = TextEditingController(text: (u['address'] ?? '').toString());
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 8),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number')),
            const SizedBox(height: 8),
            TextField(controller: address, decoration: const InputDecoration(labelText: 'Home address')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final fields = <String, dynamic>{
                'name': name.text.trim().isNotEmpty ? name.text.trim() : (u['name'] ?? '').toString(),
                'phone': phone.text.trim(),
                'address': address.text.trim(),
              };
              u.addAll(fields);
              LocalDb.updateAccount((u['email'] ?? '').toString(), fields);
              Navigator.pop(d);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void pickLanguage() => showDialog(
        context: context,
        builder: (d) => SimpleDialog(title: const Text('Language'), children: [
          for (final l in ['English', 'Filipino'])
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(d);
                setState(() => language = l);
              },
              child: Text(l),
            ),
        ]),
      );

  void hotlines() => showDialog(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Emergency hotlines'),
          content: const Text('National emergency: 911\nBarangay hall: (add number)\nPolice: (add number)\nBFP: (add number)\nRescue: (add number)'),
          actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Close'))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final name = (u['name'] ?? '').toString();
    final role = (u['role'] ?? 'resident').toString();
    final roleLabel = role.isEmpty ? '' : role[0].toUpperCase() + role.substring(1);

    return Column(children: [
      TealHeader(
        child: Column(children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: appYellow,
            child: Text(initialsOf(name), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('$roleLabel · Brgy. ${u['barangay'] ?? 'Abongan'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (role == 'staff' && (u['staffIdNumber'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${u['position'] ?? 'Staff'} · ID ${u['staffIdNumber']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ]),
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          row(Icons.person_outline, 'Edit profile', 'Name, address, mobile', editProfile),
          row(Icons.language, 'Language', language, pickLanguage),
          notificationsRow(),
          row(Icons.phone_outlined, 'Emergency hotlines', 'Police, BFP, rescue', hotlines),
          row(Icons.help_outline, 'Help & about', 'Version 1.0.0',
              () => showAboutDialog(context: context, applicationName: 'BarangayConnect Abongan', applicationVersion: '1.0.0')),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: appDanger,
                backgroundColor: Colors.white,
                side: const BorderSide(color: appDanger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (r) => false,
              ),
              child: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text('Signing out keeps your requests safe on your account.', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ),
        ]),
      ),
    ]);
  }
}