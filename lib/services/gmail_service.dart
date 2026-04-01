import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';

class GmailService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      GmailApi.gmailReadonlyScope,
    ],
  );

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      return null;
    }
  }

  Future<List<Subscription>> scanForSubscriptions() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return [];

    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) return [];

    final gmailApi = GmailApi(authClient);
    final subscriptions = <Subscription>[];

    // Keywords to search for receipts and subscriptions
    const queries = [
      'subject:receipt',
      'subject:subscription',
      'subject:invoice',
      '"next billing date"',
      '"subscription confirmation"',
      'Netflix',
      'Spotify',
      'Amazon Prime',
      'iCloud',
      'ChatGPT',
      'YouTube Premium',
      'Adobe',
    ];

    try {
      for (var query in queries) {
        final results = await gmailApi.users.messages.list('me', q: query, maxResults: 10);
        if (results.messages == null) continue;

        for (var msg in results.messages!) {
          final detail = await gmailApi.users.messages.get('me', msg.id!);
          final sub = _parseEmail(detail);
          if (sub != null) {
            // Check if we already added this one
            if (!subscriptions.any((s) => s.name.toLowerCase() == sub.name.toLowerCase())) {
              subscriptions.add(sub);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Gmail Scan Error: $e");
    }

    return subscriptions;
  }

  Subscription? _parseEmail(Message message) {
    final headers = message.payload?.headers;
    if (headers == null) return null;

    final subject = headers.firstWhere((h) => h.name == 'Subject', orElse: () => MessagePartHeader(value: '')).value ?? '';
    // final from = headers.firstWhere((h) => h.name == 'From', orElse: () => MessagePartHeader(value: '')).value ?? '';
    final body = message.snippet ?? '';

    // Logic to extract name, price, and date
    String? name;
    double? price;
    String currency = '₦';

    final text = (subject + body).toLowerCase();

    if (text.contains('netflix')) { name = 'Netflix'; }
    else if (text.contains('spotify')) { name = 'Spotify'; }
    else if (text.contains('icloud')) { name = 'iCloud+'; }
    else if (text.contains('chatgpt') || text.contains('openai')) { name = 'ChatGPT'; }
    else if (text.contains('amazon prime')) { name = 'Amazon Prime'; }
    else if (text.contains('youtube')) { name = 'YouTube Premium'; }
    else if (text.contains('adobe')) { name = 'Adobe Creative Cloud'; }
    else if (text.contains('disney')) { name = 'Disney+'; }
    else if (text.contains('hulu')) { name = 'Hulu'; }
    else if (text.contains('hbo')) { name = 'HBO Max'; }
    else if (text.contains('canva')) { name = 'Canva'; }
    else if (text.contains('figma')) { name = 'Figma'; }
    else if (text.contains('zoom')) { name = 'Zoom'; }
    else if (text.contains('notion')) { name = 'Notion'; }

    if (name == null) return null;

    // Very basic price extraction (regex)
    final priceRegex = RegExp(r'(₦|\$|£|€)\s?(\d+(?:\.\d{2})?)');
    final match = priceRegex.firstMatch(body);
    if (match != null) {
      currency = match.group(1) ?? '₦';
      price = double.tryParse(match.group(2) ?? '');
    }

    // Default prices if extraction fails
    price ??= _getDefaultPrice(name);

    return Subscription(
      id: DateTime.now().millisecondsSinceEpoch.toString() + name,
      name: name,
      price: price,
      currency: currency,
      date: DateTime.now().toIso8601String(),
      category: 'Software',
      renewalDate: 'Monthly',
      isTrial: body.toLowerCase().contains('trial'),
    );
  }

  double _getDefaultPrice(String name) {
    switch (name) {
      case 'Netflix': return 2200.0;
      case 'Spotify': return 2000.0;
      case 'iCloud+': return 2900.0;
      case 'ChatGPT': return 6900.0;
      case 'Amazon Prime': return 1500.0;
      default: return 1000.0;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
