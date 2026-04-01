import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../models/subscription.dart';

// --- PROVIDERS ---

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Subscriptions State Notifier
class SubscriptionsNotifier extends Notifier<AsyncValue<ScanResult>> {
  @override
  AsyncValue<ScanResult> build() {
    _loadData();
    return const AsyncValue.loading();
  }

  Future<void> _loadData() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.scanGmail();

      // Save to local storage
      await LocalStorageService.saveSubscriptions(result.subscriptions);

      state = AsyncValue.data(result);
    } catch (e) {
      // Try loading from local cache
      final cachedSubs = LocalStorageService.getSubscriptions();
      final cachedHistory = LocalStorageService.getKillHistory();
      final totalSaved = LocalStorageService.getTotalSaved();

      if (cachedSubs.isNotEmpty) {
        state = AsyncValue.data(ScanResult(
          annualLeak: cachedSubs.fold(0.0, (sum, s) => sum + s.price) * 12,
          subscriptions: cachedSubs,
          killHistory: cachedHistory,
          totalSaved: totalSaved,
          monthlyBurnRate: cachedSubs.fold(0.0, (sum, s) => sum + s.price),
        ));
      } else {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadData();
  }

  Future<void> addSubscription(Subscription sub) async {
    final current = state.value;
    if (current != null) {
      final updatedSubs = [...current.subscriptions, sub];
      await LocalStorageService.saveSubscriptions(updatedSubs);
      state = AsyncValue.data(ScanResult(
        annualLeak: updatedSubs.fold(0.0, (sum, s) => sum + s.price) * 12,
        subscriptions: updatedSubs,
        killHistory: current.killHistory,
        totalSaved: current.totalSaved,
        monthlyBurnRate: updatedSubs.fold(0.0, (sum, s) => sum + s.price),
      ));
    }
  }

  Future<void> killSubscription(Subscription sub) async {
    final current = state.value;
    if (current != null) {
      final updatedSubs =
          current.subscriptions.where((s) => s.id != sub.id).toList();
      final updatedHistory = [...current.killHistory, sub];
      final newTotalSaved = current.totalSaved + sub.price;

      // Persist
      await LocalStorageService.saveSubscriptions(updatedSubs);
      await LocalStorageService.addToKillHistory(sub);
      await LocalStorageService.saveTotalSaved(newTotalSaved);

      state = AsyncValue.data(ScanResult(
        annualLeak: updatedSubs.fold(0.0, (sum, s) => sum + s.price) * 12,
        subscriptions: updatedSubs,
        killHistory: updatedHistory,
        totalSaved: newTotalSaved,
        monthlyBurnRate: updatedSubs.fold(0.0, (sum, s) => sum + s.price),
      ));
    }
  }
}

final subscriptionsProvider =
    NotifierProvider<SubscriptionsNotifier, AsyncValue<ScanResult>>(() {
  return SubscriptionsNotifier();
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

// User Name Provider
final userNameProvider = Provider<String>((ref) {
  return LocalStorageService.getUserName();
});

// Notifications Enabled Provider
final notificationsEnabledProvider = StateProvider<bool>((ref) {
  return LocalStorageService.getNotificationsEnabled();
});

// Auto Kill Enabled Provider
final autoKillEnabledProvider = StateProvider<bool>((ref) {
  return LocalStorageService.getAutoKillEnabled();
});
