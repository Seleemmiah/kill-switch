import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import '../widgets/credit_card_widget.dart';
import '../widgets/add_card_sheet.dart';
import '../services/vault_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final VaultService _vaultService = VaultService();
  List<Map<String, dynamic>> _userCards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await _vaultService.getCards();
      if (mounted) {
        setState(() => _userCards = cards);
      }
    } catch (e) {
      debugPrint("Error loading cards: $e");
    }
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("Logout error: $e");
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  void _showAddCardSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) => AddCardSheet(
          onCardAdded: (newCard) => _loadCards(),
          scrollController: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    User? user;
    if (Firebase.apps.isNotEmpty) user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "SECURITY VAULT",
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppTheme.gold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildProfileSection(user, isDark),
          const SizedBox(height: 32),

          _buildSectionHeader("SECURE ASSETS"),
          const SizedBox(height: 12),
          _buildVaultSection(isDark, user),
          const SizedBox(height: 24),

          _buildSectionHeader("PROTECTION PROTOCOLS"),
          const SizedBox(height: 12),
          _buildFintechGroup(isDark, [
            _buildTile(
              icon: Icons.verified_user_rounded,
              title: "Kill Switch Sensitivity",
              subtitle: "Automatic neutralization at 24h",
              onTap: () {},
            ),
            _buildTile(
              icon: Icons.security_rounded,
              title: "Ghost Card Encryption",
              subtitle: "Protect physical card digits",
              trailing: Switch.adaptive(
                value: false,
                activeColor: AppTheme.violet,
                onChanged: (_) {},
              ),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader("TRANSFERS & ALERTS"),
          const SizedBox(height: 12),
          _buildFintechGroup(isDark, [
            _buildTile(
              icon: Icons.notifications_active_rounded,
              title: "Push Notifications",
              subtitle: "Alerts before conversion",
              trailing: Switch.adaptive(
                value: true,
                activeColor: AppTheme.violet,
                onChanged: (_) {},
              ),
            ),
            _buildTile(
              icon: Icons.email_outlined,
              title: "Bank Feed Sync",
              subtitle: "Active monitoring enabled",
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 32),

          _buildLogoutButton(isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildProfileSection(User? user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.violet.withOpacity(0.1),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppTheme.violet,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? "Seleem Aleshinloye",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.obsidian,
                  ),
                ),
                Text(
                  user?.email ?? "pioneer@studio.io",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "ELITE",
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultSection(bool isDark, User? user) {
    if (_userCards.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.02)
              : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12, style: BorderStyle.none),
        ),
        child: InkWell(
          onTap: _showAddCardSheet,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_card_rounded, color: Colors.grey, size: 24),
              const SizedBox(height: 8),
              Text(
                "Add Secure Funding Source",
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _userCards.length,
            itemBuilder: (context, index) {
              final card = _userCards[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: CreditCardWidget(
                  color: Color(card['color'] as int),
                  last4: card['last4'] as String,
                  brand: card['brand'] as String,
                  expiry: card['expiry'] as String,
                  cardHolder: user?.displayName ?? "Member",
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildTile(
          icon: Icons.add_rounded,
          title: "Link New Guardian Card",
          subtitle: "Expand your protection vault",
          onTap: _showAddCardSheet,
        ),
      ],
    );
  }

  Widget _buildFintechGroup(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
        ),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60,
                  endIndent: 16,
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.violet.withOpacity(0.1)
                    : AppTheme.violet.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.violet, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.obsidian,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: OutlinedButton(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        child: Text(
          "SECURE LOGOUT",
          style: GoogleFonts.outfit(
            color: Colors.redAccent,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
