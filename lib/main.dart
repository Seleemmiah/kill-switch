import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/local_storage_service.dart';
import 'services/notification_helper.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage (Hive)
  await LocalStorageService.init();

  // Initialize notifications
  await NotificationHelper.init();
  await NotificationHelper.requestPermissions();

  // Initialize Firebase
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 3));
    debugPrint("✅ Firebase Initialized Successfully");
  } catch (e) {
    debugPrint("--------------------------------------------------");
    debugPrint("ℹ️ INFO: Firebase configuration not found.");
    debugPrint("Running in DEMO MODE (Local Auth & Mock Data).");
    debugPrint("To enable Firebase, add your GoogleService files.");
    debugPrint("--------------------------------------------------");
  }

  // Check onboarding status
  final onboardingComplete = await LocalStorageService.isOnboardingComplete();

  runApp(
    ProviderScope(
      child: KillSwitchApp(showOnboarding: !onboardingComplete),
    ),
  );
}

class KillSwitchApp extends StatelessWidget {
  final bool showOnboarding;
  const KillSwitchApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kill Switch',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: showOnboarding ? const OnboardingScreen() : const AuthScreen(),
    );
  }
}
