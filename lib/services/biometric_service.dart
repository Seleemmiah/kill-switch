import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate({
    String reason = "Accessing Secure Vault",
  }) async {
    try {
      final bool canCheck = await canCheckBiometrics();
      if (!canCheck) return true; // Fallback if biometrics aren't available

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}
