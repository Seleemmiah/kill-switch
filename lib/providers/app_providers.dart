import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/api_service.dart';
import '../models/subscription.dart';

// --- PROVIDERS ---

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Subscriptions State Provider
final subscriptionsProvider = FutureProvider<ScanResult>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.scanGmail();
});

// User Stats Provider
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final result = await apiService.scanGmail();

  return {
    'annual_leak': result.annualLeak,
    'total_saved': result.totalSaved,
    'active_count': result.subscriptions.length,
    'killed_count': result.killHistory.length,
  };
});

// Virtual Cards State Notifier
class VirtualCardsNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void addCard(Map<String, dynamic> card) {
    state = [...state, card];
  }

  void removeCard(String cardId) {
    state = state.where((card) => card['card_id'] != cardId).toList();
  }

  void updateCardStatus(String cardId, String status) {
    state = [
      for (final card in state)
        if (card['card_id'] == cardId) {...card, 'status': status} else card,
    ];
  }
}

final virtualCardsProvider =
    NotifierProvider<VirtualCardsNotifier, List<Map<String, dynamic>>>(() {
      return VirtualCardsNotifier();
    });

// Loading State Provider
final isLoadingProvider = StateProvider<bool>((ref) => false);

// Error State Provider
final errorProvider = StateProvider<String?>((ref) => null);

// Selected Subscription Provider (for detail view)
final selectedSubscriptionProvider = StateProvider<Subscription?>(
  (ref) => null,
);

// Theme Mode Provider
final themeModeProvider = StateProvider<bool>(
  (ref) => true,
); // true = dark mode

// Refresh Trigger Provider
final refreshTriggerProvider = StateProvider<int>((ref) => 0);
