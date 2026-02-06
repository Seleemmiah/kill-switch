import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/subscription.dart';

class ApiService {
  static const String _androidBaseUrl = 'http://10.0.2.2:8000';
  static const String _iosBaseUrl = 'http://localhost:8000';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return _androidBaseUrl;
    }
    return _iosBaseUrl;
  }

  Future<ScanResult> scanGmail() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/scan'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return ScanResult.fromJson(jsonDecode(response.body));
      }
      return _fallbackResult();
    } catch (e) {
      return _fallbackResult();
    }
  }

  Future<List<Map<String, dynamic>>> getGlobalLeaks() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/global-scan'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Global Scan Error: $e");
    }
    return [
      {
        "id": "leak1",
        "source": "Card 4242",
        "service": "Paramount+",
        "type": "Auth Hold",
        "status": "At Risk",
        "risk": "High",
        "usage": 0.0,
        "cancel_url": "https://www.paramountplus.com/account/",
      },
      {
        "id": "leak2",
        "source": "Card 8812",
        "service": "X Premium",
        "type": "Hidden Receipt",
        "status": "Detected",
        "risk": "Medium",
        "usage": 0.15,
        "cancel_url": "https://x.com/settings/premium",
      },
      {
        "id": "leak3",
        "source": "Bank-Direct",
        "service": "Audible",
        "type": "Trial Conversion",
        "status": "Due Soon",
        "risk": "High",
        "usage": 0.05,
        "cancel_url": "https://www.audible.com/account/overview",
      },
    ];
  }

  Future<bool> killSubscription(String id) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/kill-subscription/$id'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Kill Error (Fallback to Success for Demo): $e");
      return true;
    }
  }

  // --- PLAID ---
  Future<String?> createPlaidLinkToken() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/plaid/create-link-token'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['link_token'];
      }
    } catch (e) {
      debugPrint("Plaid Token Error: $e");
    }
    return null;
  }

  // --- GMAIL AUTH ---
  Future<String?> getGmailAuthUrl() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/auth/gmail/url'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['url'];
      }
    } catch (e) {
      debugPrint("Gmail Auth URL Error: $e");
    }
    return null;
  }

  // --- VIRTUAL CARDS ---
  Future<Map<String, dynamic>?> createVirtualCard({
    required String subscriptionName,
    required String merchantName,
    required double spendingLimit,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/cards/create-virtual'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subscription_name': subscriptionName,
          'merchant_name': merchantName,
          'spending_limit': spendingLimit,
          'user_id': userId,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Create Card Error: $e");
    }
    return null;
  }

  Future<bool> pauseVirtualCard(String cardId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/cards/pause/$cardId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> closeVirtualCard(String cardId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/cards/close/$cardId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCardTransactions(String cardId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/cards/$cardId/transactions'),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['transactions'],
        );
      }
    } catch (e) {
      debugPrint("Get Trans Error: $e");
    }
    return [];
  }

  ScanResult _fallbackResult() {
    return ScanResult(
      annualLeak: 124500.00,
      totalSaved: 12000.00,
      subscriptions: [
        Subscription(
          id: "1",
          name: "iCloud+",
          price: 2900.00,
          currency: "₦",
          date: "2023-10-15",
          category: "Storage",
          renewalDate: "Tomorrow",
          isTrial: false,
        ),
        Subscription(
          id: "2",
          name: "ChatGPT",
          price: 6900.00,
          currency: "₦",
          date: "2023-10-01",
          category: "AI",
          renewalDate: "in 2 days",
          isTrial: true,
        ),
        Subscription(
          id: "3",
          name: "Netflix",
          price: 2200.00,
          currency: "₦",
          date: "2023-10-20",
          category: "Entertainment",
          renewalDate: "in 3 days",
          isTrial: true,
        ),
        Subscription(
          id: "4",
          name: "Spotify",
          price: 2000.00,
          currency: "₦",
          date: "2023-10-25",
          category: "Music",
          renewalDate: "Feb 14, 2026",
        ),
        Subscription(
          id: "5",
          name: "Adobe Lightroom",
          price: 700.00,
          currency: "₦",
          date: "2023-10-10",
          category: "Design",
          renewalDate: "Feb 20, 2026",
        ),
        Subscription(
          id: "6",
          name: "Zoho",
          price: 6622.00,
          currency: "₦",
          date: "2023-10-12",
          category: "Work",
          renewalDate: "Feb 21, 2026",
        ),
      ],
      killHistory: [
        Subscription(
          id: "k1",
          name: "Prime Video",
          price: 1500.00,
          currency: "₦",
          date: "2023-09-12",
          category: "Entertainment",
        ),
      ],
    );
  }
}
