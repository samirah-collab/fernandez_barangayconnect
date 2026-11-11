import 'package:flutter/material.dart';
import 'services/local_db.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.init();
  runApp(const BarangayConnectApp());
}

class BarangayConnectApp extends StatelessWidget {
  const BarangayConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF117477);
    return MaterialApp(
      title: 'BarangayConnect Abongan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: teal),
        scaffoldBackgroundColor: const Color(0xFFF1F6F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: teal, foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7E3E2)),
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
