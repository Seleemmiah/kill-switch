import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class VaultService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final LocalAuthentication _auth = LocalAuthentication();
  static const _cardKey = 'user_vault_cards';

  Future<bool> authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return true; // Fallback if no security

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access your vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCards() async {
    final String? data = await _storage.read(key: _cardKey);
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> saveCard(Map<String, dynamic> card) async {
    final List<Map<String, dynamic>> cards = await getCards();
    cards.add(card);
    await _storage.write(key: _cardKey, value: jsonEncode(cards));
  }

  Future<void> deleteCard(int index) async {
    final List<Map<String, dynamic>> cards = await getCards();
    if (index >= 0 && index < cards.length) {
      cards.removeAt(index);
      await _storage.write(key: _cardKey, value: jsonEncode(cards));
    }
  }
}
