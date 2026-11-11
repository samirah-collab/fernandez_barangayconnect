import 'package:flutter/material.dart';
import '../services/local_db.dart';
import 'common_widgets.dart';
import 'id_picker.dart';
import 'resident_home_screen.dart';
import 'sign_in_screen.dart';
import 'staff_dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final password = TextEditingController();
  final position = TextEditingController();
  final staffIdNumber = TextEditingController();

  String role = 'resident'; // 'resident' or 'staff'
  String? staffIdImage; // photo of the barangay staff ID (base64)

  bool get isStaff => role == 'staff';

  bool agree = true;
  bool busy = false;
  bool hidePassword = true;

  String barangay = 'Abongan';

  // Display message
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Create resident account
  Future<void> createAccount() async {

    final fullName = name.text.trim();
    final userEmail = email.text.trim().toLowerCase();

    if (fullName.isEmpty ||
        userEmail.isEmpty ||
        password.text.length < 8 ||
        !agree) {
      showMessage(
        'Complete the form. Password must be at least 8 characters.',
      );
      return;
    }

    if (isStaff) {
      if (position.text.trim().isEmpty || staffIdNumber.text.trim().isEmpty) {
        showMessage('Barangay staff: enter your position and staff ID number.');
        return;
      }
      if (staffIdImage == null) {
        showMessage('Please upload a photo of your barangay staff ID.');
        return;
      }
    }

    if (!userEmail.contains('@') ||
        !userEmail.contains('.')) {
      showMessage('Please enter a valid email address.');
      return;
    }

    if (LocalDb.accounts.any(
      (a) => (a['email'] ?? '').toString().toLowerCase() == userEmail,
    )) {
      showMessage('Email is already registered.');
      return;
    }

    setState(() => busy = true);

    try {
      final account = {
        'name': fullName,
        'email': userEmail,
        'phone': phone.text.trim(),
        'address': address.text.trim(),
        'password': password.text,
        'role': role,
        'barangay': barangay,
        if (isStaff) ...{
          'position': position.text.trim(),
          'staffIdNumber': staffIdNumber.text.trim(),
          'staffIdImage': staffIdImage,
          'idVerified': false, // an admin can verify the ID later
        },
      };

      await LocalDb.addAccount(account);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => isStaff ? StaffDashboardScreen(user: account) : ResidentHomeScreen(user: account),
        ),
        (route) => false,
      );

    } catch (e) {
      if (!mounted) return;
      showMessage('Account creation failed: $e');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
    password.dispose();
    position.dispose();
    staffIdNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'resident', label: Text('Resident'), icon: Icon(Icons.person_outline)),
              ButtonSegment(value: 'staff', label: Text('Barangay staff'), icon: Icon(Icons.badge_outlined)),
            ],
            selected: {role},
            onSelectionChanged: busy ? null : (v) => setState(() => role = v.first),
          ),
          const SizedBox(height: 16),

          pageTitle('Personal information'),

          formLabel('Full name'),

          TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Enter your full name',
              border: OutlineInputBorder(),
            ),
          ),

          formLabel('Barangay'),

          // Barangay is fixed (Abongan) – plain box, no dropdown arrow
          InputDecorator(
            decoration: const InputDecoration(border: OutlineInputBorder()),
            child: Text(barangay, style: const TextStyle(fontSize: 16)),
          ),

          formLabel('Mobile number'),

          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '09XXXXXXXXX',
              border: OutlineInputBorder(),
            ),
          ),

          formLabel('Email address'),

          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'example@email.com',
              border: OutlineInputBorder(),
            ),
          ),

          formLabel('Home address'),

          TextField(
            controller: address,
            decoration: const InputDecoration(
              hintText: 'Enter your home address',
              border: OutlineInputBorder(),
            ),
          ),

          formLabel('Password'),

          TextField(
            controller: password,
            obscureText: hidePassword,
            decoration: InputDecoration(
              hintText: 'At least 8 characters',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  hidePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    hidePassword = !hidePassword;
                  });
                },
              ),
            ),
          ),

          // Barangay staff must confirm who they are with an ID
          if (isStaff) ...[
            const SizedBox(height: 8),
            pageTitle('Barangay staff verification'),
            formLabel('Position'),
            TextField(
              controller: position,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'e.g. Barangay Secretary', border: OutlineInputBorder()),
            ),
            formLabel('Barangay staff ID number'),
            TextField(
              controller: staffIdNumber,
              decoration: const InputDecoration(hintText: 'ID number', border: OutlineInputBorder()),
            ),
            formLabel('Photo of your barangay staff ID'),
            IdUploadBox(
              label: 'Upload your barangay staff ID',
              imageBase64: staffIdImage,
              enabled: !busy,
              onChanged: (v) => setState(() => staffIdImage = v),
            ),
          ],

          const SizedBox(height: 12),

          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: agree,
            activeColor: appTeal,
            onChanged: busy
                ? null
                : (v) {
                    setState(() => agree = v ?? false);
                  },
            title: const Text(
              'I agree to the Terms and Data Privacy Notice',
              style: TextStyle(fontSize: 12),
            ),
          ),

          const SizedBox(height: 12),

          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: appTeal,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: busy ? null : createAccount,
            child: busy
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : Text(isStaff ? 'Create staff account' : 'Create account'),
          ),

          Center(
            child: TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignInScreen(),
                        ),
                      ),
              child: const Text('I already have an account'),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                isStaff
                    ? 'Your staff ID is kept to confirm that you work for the barangay.'
                    : 'Barangay staff: choose "Barangay staff" above.',
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}