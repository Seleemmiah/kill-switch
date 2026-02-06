import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Attempt initialization. If files are missing, this will catch.
    await Firebase.initializeApp().timeout(const Duration(seconds: 3));
    debugPrint("✅ Firebase Initialized Successfully");
  } catch (e) {
    debugPrint("--------------------------------------------------");
    debugPrint("ℹ️ INFO: Firebase configuration not found.");
    debugPrint("Running in DEMO MODE (Local Auth & Mock Data).");
    debugPrint("To enable Firebase, add your GoogleService files.");
    debugPrint("--------------------------------------------------");
  }
  runApp(const KillSwitchApp());
}

class KillSwitchApp extends StatelessWidget {
  const KillSwitchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthScreen(),
    );
  }
}
