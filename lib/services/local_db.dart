import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDb {
  static late SharedPreferences _prefs;
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.getString('accounts') == null) {
      await saveList('accounts', [
        {'name':'Barangay Staff','email':'staff@abongan.local',
         'password':'staff1234','role':'staff','barangay':'Abongan'}
      ]);
    }
  }

  static List<Map<String,dynamic>> getList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Map<String,dynamic>.from(e)).toList();
  }

  static Future<void> saveList(String key, List<Map<String,dynamic>> data) =>
      _prefs.setString(key, jsonEncode(data));

  static List<Map<String,dynamic>> get accounts => getList('accounts');
  static List<Map<String,dynamic>> get reports => getList('reports');
  static List<Map<String,dynamic>> get requests => getList('requests');

  static Future<void> addAccount(Map<String,dynamic> account) async {
    final data = accounts..add(account);
    await saveList('accounts', data);
  }
  static Future<void> addReport(Map<String,dynamic> report) async {
    final data = reports..insert(0, report);
    await saveList('reports', data);
  }
  static Future<void> addRequest(Map<String,dynamic> request) async {
    final data = requests..insert(0, request);
    await saveList('requests', data);
  }

  // NEW: update any fields of one report/request and save them
  // (status, note, crew, feePaid, ...). When the status changes, the time
  // is also saved in 'history' so the Request status timeline can show it.
  static Future<void> updateItem(
    String id,
    bool isReport,
    Map<String, dynamic> fields, {
    bool touch = true,
  }) async {
    final key = isReport ? 'reports' : 'requests';
    final data = getList(key);
    final index = data.indexWhere((e) => e['id'] == id);
    if (index < 0) return;

    final item = data[index];
    final now = DateTime.now().toIso8601String();
    final newStatus = fields['status'];

    if (newStatus != null && newStatus != item['status']) {
      final history = Map<String, dynamic>.from((item['history'] as Map?) ?? {});
      history[newStatus.toString()] = now;
      item['history'] = history;
    }

    item.addAll(fields);
    if (touch) item['updated'] = now;
    await saveList(key, data);
  }

  static Future<void> updateStatus(String id, bool isReport, String status) =>
      updateItem(id, isReport, {'status': status});

  // NEW: save changes to an account (used by Edit profile)
  static Future<void> updateAccount(String email, Map<String, dynamic> fields) async {
    final data = accounts;
    final index = data.indexWhere((e) => e['email'] == email);
    if (index < 0) return;
    data[index].addAll(fields);
    await saveList('accounts', data);
  }

  // ── Notifications on/off (saved per account, default ON) ──
  static bool notificationsOn(dynamic email) =>
      _prefs.getBool('notif_${email ?? ''}') ?? true;

  static Future<void> setNotificationsOn(dynamic email, bool value) =>
      _prefs.setBool('notif_${email ?? ''}', value);

  // ── Messages between resident and staff (one thread per report/request) ──
  // {id, itemId, from: 'resident' | 'staff', sender, text, time}
  static List<Map<String, dynamic>> get messages => getList('messages');

  static List<Map<String, dynamic>> messagesFor(String itemId) =>
      messages.where((m) => m['itemId'] == itemId).toList();

  static Future<void> addMessage(Map<String, dynamic> message) async {
    final data = messages..add(message);
    await saveList('messages', data);
  }
}
