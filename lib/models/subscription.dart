class Subscription {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String date;
  final String category;
  final String? renewalDate;
  final String? cancelUrl;
  final bool isTrial;
  final String status; // 'active', 'cancelling', 'killed'

  final String? optimizationTip;
  final double? savingsPotential;
  final String? paymentMethod;
  final bool autoKill;
  final bool isGhostCard;
  final double usageLevel;
  final int daysRemaining;
  final int totalCycleDays;
  final bool isBankConnected;
  final String? bankName;

  Subscription({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.date,
    required this.category,
    this.renewalDate,
    this.cancelUrl,
    this.isTrial = false,
    this.status = 'active',
    this.optimizationTip,
    this.savingsPotential,
    this.paymentMethod,
    this.autoKill = false,
    this.isGhostCard = false,
    this.usageLevel = 1.0,
    this.daysRemaining = 30,
    this.totalCycleDays = 30,
    this.isBankConnected = false,
    this.bankName,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Service',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? '\$',
      date: json['date']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Other',
      renewalDate: json['renewal_date']?.toString(),
      cancelUrl: json['cancel_url']?.toString(),
      isTrial: json['is_trial'] == true,
      status: json['status']?.toString() ?? 'active',
      optimizationTip: json['optimization_tip']?.toString(),
      savingsPotential: (json['savings_potential'] as num?)?.toDouble(),
      paymentMethod: json['payment_method']?.toString(),
      autoKill: json['auto_kill'] == true,
      isGhostCard: json['is_ghost_card'] == true,
      usageLevel: (json['usage_level'] as num?)?.toDouble() ?? 1.0,
      daysRemaining: (json['days_remaining'] as num?)?.toInt() ?? 30,
      totalCycleDays: (json['total_cycle_days'] as num?)?.toInt() ?? 30,
      isBankConnected: json['is_bank_connected'] == true,
      bankName: json['bank_name']?.toString(),
    );
  }
}

class ScanResult {
  final double annualLeak;
  final List<Subscription> subscriptions;
  final List<Subscription> killHistory;
  final double totalSaved;
  final double monthlyBurnRate;

  ScanResult({
    required this.annualLeak,
    required this.subscriptions,
    this.killHistory = const [],
    this.totalSaved = 0.0,
    this.monthlyBurnRate = 0.0,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      annualLeak: (json['annual_leak'] as num?)?.toDouble() ?? 0.0,
      subscriptions:
          (json['subscriptions'] as List?)
              ?.map((i) => Subscription.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      killHistory:
          (json['kill_history'] as List?)
              ?.map((i) => Subscription.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      totalSaved: (json['total_saved'] as num?)?.toDouble() ?? 0.0,
      monthlyBurnRate: (json['monthly_burn_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
