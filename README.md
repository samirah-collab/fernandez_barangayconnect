# BarangayConnect Abongan - separate Flutter screens

## Folder structure
lib/
  main.dart
  services/local_db.dart
  screens/
    common_widgets.dart
    welcome_screen.dart
    sign_in_screen.dart
    register_screen.dart
    resident_home_screen.dart
    incident_report_screen.dart
    certificate_request_screen.dart
    my_requests_screen.dart
    notifications_screen.dart
    profile_screen.dart
    staff_dashboard_screen.dart
    staff_review_screen.dart

## Run
1. Open this folder in VS Code.
2. Connect Android phone with USB debugging enabled.
3. Run `flutter pub get`
4. Run `flutter run`

If you are creating a new Flutter folder rather than using this folder, first run `flutter create .`.

Demo staff account:
email: staff@abongan.local
password: staff1234

Data is stored locally on the device using shared_preferences. This is a functional classroom prototype, not yet synchronized across multiple devices. For real barangay use, add Firebase or another secure backend, proper authentication, access rules, and backups.
