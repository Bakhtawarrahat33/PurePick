import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PurePickApp());
}

class PurePickApp extends StatelessWidget {
  const PurePickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PurePick AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF9DC183), // Soft Sage Green
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WelcomeScreen(),
    );
  }
}
