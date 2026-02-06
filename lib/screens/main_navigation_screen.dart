import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'dashboard_screen.dart';
import 'scanner_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/add_card_sheet.dart';
import '../widgets/add_subscription_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    const DashboardScreen(),
    const ScannerScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddSubscription,
              backgroundColor: AppTheme.violet,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            24,
            0,
            24,
            0,
          ), // Moved flush to lower edge
          decoration: BoxDecoration(
            color: isDark ? AppTheme.slate : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                blurRadius: 30,
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 5,
              activeColor: Colors.white,
              iconSize: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: const Color.fromARGB(255, 5, 2, 12),
              color: isDark
                  ? Colors.white38
                  : AppTheme.charcoal.withValues(alpha: 0.5),
              tabs: const [
                GButton(icon: Icons.home_rounded, text: 'Home'),
                GButton(icon: Icons.search_rounded, text: 'Radar'),
                GButton(icon: Icons.analytics_rounded, text: 'Insights'),
                GButton(icon: Icons.tune_rounded, text: 'Vault'),
              ],
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                HapticFeedback.lightImpact();
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSubscription() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.slate
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "What would you like to do?",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _buildActionItem(
              icon: Icons.add_rounded,
              title: "Add Subscription",
              subtitle: "Manually track any custom service.",
              color: AppTheme.violet,
              onTap: () {
                Navigator.pop(context);
                _openSheet(const AddSubscriptionSheet());
              },
            ),
            const SizedBox(height: 16),
            _buildActionItem(
              icon: Icons.add_card_rounded,
              title: "Add Payment Card",
              subtitle: "Resolve and secure your banking cards.",
              color: AppTheme.gold,
              onTap: () {
                Navigator.pop(context);
                _openSheet(AddCardSheet(onCardAdded: (_) {}));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            if (sheet is AddCardSheet) {
              return AddCardSheet(
                onCardAdded: (_) {},
                scrollController: controller,
              );
            }
            if (sheet is AddSubscriptionSheet) {
              return AddSubscriptionSheet(scrollController: controller);
            }
            return sheet;
          },
        ),
      ),
    );
  }
}
