
import 'package:flutter/material.dart';

import '../services/local_db.dart';
import 'register_screen.dart';
import 'resident_home_screen.dart';
import 'staff_dashboard_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  String role = 'resident';
  bool hidePassword = true;

  static const Color appTeal = Color(0xFF00897B);

  void showLoginMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void signIn() {
    final enteredEmail = email.text.trim().toLowerCase();
    final enteredPassword = password.text;

    if (enteredEmail.isEmpty || enteredPassword.isEmpty) {
      showLoginMessage('Please enter your email and password.');
      return;
    }

    final matches = LocalDb.accounts.where((account) {
      return account['email']?.toString().toLowerCase() == enteredEmail &&
          account['password']?.toString() == enteredPassword &&
          account['role']?.toString() == role;
    }).toList();

    if (matches.isEmpty) {
      showLoginMessage('Invalid email, password, or account role.');
      return;
    }

    final user = matches.first;

    final Widget destination = role == 'staff'
        ? StaffDashboardScreen(user: user)
        : ResidentHomeScreen(user: user);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Widget formLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const SizedBox(height: 20),

          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Text(
            'Sign in to report issues and request certificates.',
            style: TextStyle(color: Colors.blueGrey),
          ),

          const SizedBox(height: 25),

          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'resident',
                label: Text('Resident'),
              ),
              ButtonSegment(
                value: 'staff',
                label: Text('Barangay staff'),
              ),
            ],
            selected: {role},
            onSelectionChanged: (selection) {
              setState(() {
                role = selection.first;
              });
            },
          ),

          formLabel('Mobile number or email'),

          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Email address',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          formLabel('Password'),

          TextField(
            controller: password,
            obscureText: hidePassword,
            decoration: InputDecoration(
              hintText: 'Enter password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  hidePassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    hidePassword = !hidePassword;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: appTeal,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: signIn,
              child: const Text('Sign in'),
            ),
          ),

          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text('Create an Account'),
            ),
          ),

          if (role == 'staff')
            const Center(
              child: Text(
                'Demo: staff@abongan.local / staff1234',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blueGrey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
