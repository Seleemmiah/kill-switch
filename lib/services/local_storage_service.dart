import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';

class LocalStorageService {
  static const String _subscriptionsBox = 'subscriptions_box';
  static const String _killHistoryBox = 'kill_history_box';
  static const String _settingsBox = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_subscriptionsBox);
    await Hive.openBox(_killHistoryBox);
    await Hive.openBox(_settingsBox);
  }

  // --- Subscriptions ---
  static Box get _subBox => Hive.box(_subscriptionsBox);
  static Box get _killBox => Hive.box(_killHistoryBox);
  static Box get _settings => Hive.box(_settingsBox);

  static Future<void> saveSubscriptions(List<Subscription> subs) async {
    final data = subs.map((s) => _subscriptionToMap(s)).toList();
    await _subBox.put('active_subs', data);
  }

  static List<Subscription> getSubscriptions() {
    final data = _subBox.get('active_subs');
    if (data == null) return [];
    return (data as List)
        .map((item) => Subscription.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> addSubscription(Subscription sub) async {
    final subs = getSubscriptions();
    subs.add(sub);
    await saveSubscriptions(subs);
  }

  static Future<void> removeSubscription(String id) async {
    final subs = getSubscriptions();
    subs.removeWhere((s) => s.id == id);
    await saveSubscriptions(subs);
  }

  // --- Kill History ---
  static Future<void> addToKillHistory(Subscription sub) async {
    final history = getKillHistory();
    history.add(sub);
    final data = history.map((s) => _subscriptionToMap(s)).toList();
    await _killBox.put('kill_history', data);
  }

  static List<Subscription> getKillHistory() {
    final data = _killBox.get('kill_history');
    if (data == null) return [];
    return (data as List)
        .map((item) => Subscription.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // --- Stats ---
  static Future<void> saveTotalSaved(double amount) async {
    await _settings.put('total_saved', amount);
  }

  static double getTotalSaved() {
    return _settings.get('total_saved', defaultValue: 0.0);
  }

  static Future<void> addSavedAmount(double amount) async {
    final current = getTotalSaved();
    await saveTotalSaved(current + amount);
  }

  // --- Settings ---
  static Future<void> setOnboardingComplete(bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', complete);
  }

  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  static Future<void> setUserName(String name) async {
    await _settings.put('user_name', name);
  }

  static String getUserName() {
    return _settings.get('user_name', defaultValue: 'User');
  }

  static Future<void> setUserEmail(String email) async {
    await _settings.put('user_email', email);
  }

  static String getUserEmail() {
    return _settings.get('user_email', defaultValue: '');
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _settings.put('notifications_enabled', enabled);
  }

  static bool getNotificationsEnabled() {
    return _settings.get('notifications_enabled', defaultValue: true);
  }

  static Future<void> setAutoKillEnabled(bool enabled) async {
    await _settings.put('auto_kill_enabled', enabled);
  }

  static bool getAutoKillEnabled() {
    return _settings.get('auto_kill_enabled', defaultValue: false);
  }

  // --- Helpers ---
  static Map<String, dynamic> _subscriptionToMap(Subscription s) {
    return {
      'id': s.id,
      'name': s.name,
      'price': s.price,
      'currency': s.currency,
      'date': s.date,
      'category': s.category,
      'renewal_date': s.renewalDate,
      'cancel_url': s.cancelUrl,
      'is_trial': s.isTrial,
      'status': s.status,
      'optimization_tip': s.optimizationTip,
      'savings_potential': s.savingsPotential,
      'payment_method': s.paymentMethod,
      'auto_kill': s.autoKill,
      'is_ghost_card': s.isGhostCard,
      'usage_level': s.usageLevel,
      'days_remaining': s.daysRemaining,
      'total_cycle_days': s.totalCycleDays,
      'is_bank_connected': s.isBankConnected,
      'bank_name': s.bankName,
    };
  }
}
