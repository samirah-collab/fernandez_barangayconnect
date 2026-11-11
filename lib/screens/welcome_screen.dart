import 'dart:convert';
import 'package:flutter/material.dart';
import 'common_widgets.dart';
import 'logo_data.dart';
import 'sign_in_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Container(
        width: double.infinity, color: appTeal,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 15),
            Column(children: [
              // Barangay logo (embedded in logo_data.dart)
              Container(
                width: 130, height: 130,
                padding: const EdgeInsets.all(8), // pantay na puting gilid
                decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.memory(
                    base64Decode(logoBase64),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const Icon(
                      Icons.account_balance, color: appTeal, size: 65),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Text('BarangayConnect',
                style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
              const Text('ABONGAN', style: TextStyle(color: Colors.white70, letterSpacing: 2)),
              const SizedBox(height: 38),
              const Text('Report concerns.\nRequest certificates.\nTrack every update.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, height: 1.6, fontSize: 15)),
            ]),
            SizedBox(width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: appYellow,
                  foregroundColor: Colors.black, padding: const EdgeInsets.all(17)),
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignInScreen())),
                child: const Text('Get started', style: TextStyle(fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    ),
  );
}