import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/subscription.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/subscription_item.dart';
import '../widgets/savings_goal_card.dart';
import '../widgets/notification_center.dart';
import '../widgets/search_filter_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<ScanResult> _scanFuture;

  // Search and filter state
  String _searchQuery = '';
  String? _selectedCategory;
  String _sortBy = 'date';
  List<Subscription> _filteredSubscriptions = [];

  // Mock notifications (will be fetched from API in production)
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: 'notif_1',
      type: 'trial_ending_soon',
      title: '⚠️ Netflix Trial Ending Soon',
      message:
          'Your Netflix free trial ends in 3 days. Cancel now to avoid charges.',
      subscriptionId: '3',
      subscriptionName: 'Netflix',
      priority: 'high',
      actionUrl: 'https://netflix.com/cancel',
      actionLabel: 'Cancel Now',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: 'notif_2',
      type: 'trial_ending_today',
      title: '🚨 Disney+ Trial Ends Tomorrow!',
      message:
          'Your Disney+ trial ends tomorrow. You\'ll be charged if you don\'t cancel.',
      subscriptionId: '4',
      subscriptionName: 'Disney+',
      priority: 'urgent',
      actionUrl: 'https://disneyplus.com/account',
      actionLabel: 'Cancel Immediately',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scanFuture = _apiService.scanGmail();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _scanFuture = _apiService.scanGmail();
            });
            await _scanFuture;
          },
          color: AppTheme.gold,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 24),
                FutureBuilder<ScanResult>(
                  future: _scanFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.gold,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasData) {
                      return _buildMainContent(snapshot.data!, isDark);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ScanResult result, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWealthCard(result, isDark),
        _buildWasteAlert(result.subscriptions, isDark),
        const SizedBox(height: 20),
        // Search and Filter Bar
        SearchFilterBar(
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query;
              _updateFilteredSubscriptions(result.subscriptions);
            });
          },
          onCategoryFilter: (category) {
            setState(() {
              _selectedCategory = category;
              _updateFilteredSubscriptions(result.subscriptions);
            });
          },
          onSortChanged: (sortBy) {
            setState(() {
              _sortBy = sortBy;
              _updateFilteredSubscriptions(result.subscriptions);
            });
          },
          categories: SubscriptionFilterHelper.extractCategories(
            result.subscriptions,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Active Subscriptions",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.obsidian,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 10,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "SECURE BANK FEED ACTIVE",
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(60, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "History",
                style: GoogleFonts.outfit(
                  color: AppTheme.violet,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...(_filteredSubscriptions.isEmpty
                ? result.subscriptions
                : _filteredSubscriptions)
            .take(5)
            .toList()
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final sub = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 100)),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SubscriptionItem(subscription: sub),
                      ),
                    ),
                  );
                },
              );
            }),
        if (result.subscriptions.length > 5)
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                "View All (${result.subscriptions.length})",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        const SizedBox(height: 32),
        SavingsGoalCard(
          currentSavings: result.totalSaved,
          targetSavings: 5000.0,
        ),
        const SizedBox(height: 24),
        _buildHallOfFame(result.killHistory, isDark),
        const SizedBox(height: 40),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  Widget _buildWealthCard(ScanResult result, bool isDark) {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.obsidian, // Darker base
            AppTheme.deepSlate.withValues(alpha: 0.9),
            AppTheme.slate.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              // Glassy overlay circle
              Positioned(
                right: -30,
                top: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),

              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row (Shield Badge)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Kill Switch Ready",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  // Financial Metrics Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "MONTHLY BURN",
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            "${result.subscriptions.isNotEmpty ? result.subscriptions.first.currency : '₦'}${result.monthlyBurnRate.toStringAsFixed(2)}",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "+12.5% SAVED",
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF00FF94),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${result.subscriptions.isNotEmpty ? result.subscriptions.first.currency : '₦'}${result.totalSaved.toStringAsFixed(2)}",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // System Status Footer (Pulse Dot)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const _PulseDot(),
                            const SizedBox(width: 8),
                            Text(
                              "SYSTEM ONLINE",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${result.subscriptions.length} active monitors",
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHallOfFame(List<Subscription> killed, bool isDark) {
    if (killed.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("HALL OF FAME", "Neutralized Threats"),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: killed.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final sub = killed[index];
              return Container(
                width: 124,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.slate : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.03),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      sub.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isDark ? Colors.white : AppTheme.obsidian,
                      ),
                    ),
                    Text(
                      "${sub.currency}${sub.price.toStringAsFixed(2)}",
                      style: GoogleFonts.outfit(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: AppTheme.gold,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (onTap != null)
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.white24,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(
                'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_getGreeting()},",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "Seleem",
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.obsidian,
                  ),
                ),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: () => _showNotificationCenter(context),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: isDark ? Colors.white70 : AppTheme.obsidian,
                  size: 22,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppTheme.obsidian : Colors.white,
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWasteAlert(List<Subscription> subs, bool isDark) {
    final wastedSubs = subs.where((s) => s.usageLevel < 0.25).toList();
    if (wastedSubs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Financial Leak Identified",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.orange[900],
                  ),
                ),
                Text(
                  "You've barely used ${wastedSubs.first.name} this month. Neutralize?",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              "SHUT DOWN",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
    );

  void _showNotificationCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => NotificationCenterSheet(
          notifications: _notifications,
          onNotificationTap: (id) {
            setState(() {
              final notif = _notifications.firstWhere((n) => n.id == id);
              notif.isRead = true;
            });
          },
          onActionTap: (id) {
            final notif = _notifications.firstWhere((n) => n.id == id);
            if (notif.actionUrl != null) {
              debugPrint('Opening: \${notif.actionUrl}');
            }
            Navigator.pop(context);
          },
          onDismiss: (id) {
            setState(() {
              _notifications.removeWhere((n) => n.id == id);
            });
          },
        ),
      ),
    );
  }

  void _updateFilteredSubscriptions(List<Subscription> allSubscriptions) {
    _filteredSubscriptions = SubscriptionFilterHelper.filterSubscriptions(
      allSubscriptions,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      category: _selectedCategory,
      sortBy: _sortBy,
    );
  }
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF00FF94),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF00FF94,
                ).withValues(alpha: 0.6 * (1 - _controller.value)),
                blurRadius: 10 * _controller.value,
                spreadRadius: 4 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

            Navigator.pop(context);
          },
          onDismiss: (id) {
            setState(() {
              _notifications.removeWhere((n) => n.id == id);
            });
          },
        ),
      ),
    );
  }
  
  void _updateFilteredSubscriptions(List<Subscription> allSubscriptions) {
    _filteredSubscriptions = SubscriptionFilterHelper.filterSubscriptions(
      allSubscriptions,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      category: _selectedCategory,
      sortBy: _sortBy,
    );

            Navigator.pop(context);
          },
          onDismiss: (id) {
            setState(() {
              _notifications.removeWhere((n) => n.id == id);
            });
          },
        ),
      ),
    );
  }
  
  void _updateFilteredSubscriptions(List<Subscription> allSubscriptions) {
    _filteredSubscriptions = SubscriptionFilterHelper.filterSubscriptions(
      allSubscriptions,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      category: _selectedCategory,
      sortBy: _sortBy,
    );
  }
  }
