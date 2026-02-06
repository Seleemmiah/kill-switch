import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../services/brand_service.dart';
import '../widgets/ghost_card_widget.dart';

class SubscriptionDetailScreen extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionDetailScreen({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brand = BrandService.resolveBrand(subscription.name);
    final brandColor = brand['color'] as Color?;
    final logoUrl = brand['logo'] as String?;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: brandColor?.withOpacity(0.8) ?? AppTheme.violet,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Brand Background Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          brandColor ?? AppTheme.violet,
                          theme.scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                  // Hero Logo
                  Center(
                    child: Hero(
                      tag: 'sub_logo_${subscription.id}',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: logoUrl != null
                              ? Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Image.asset(
                                    logoUrl,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Icon(
                                  Icons.subscriptions_rounded,
                                  size: 60,
                                  color: brandColor,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.name,
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.obsidian,
                            ),
                          ),
                          Text(
                            subscription.category,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${subscription.currency}${subscription.price}",
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: brandColor ?? AppTheme.violet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle("COMMAND CENTER"),
                  const SizedBox(height: 16),
                  _buildProtocolCard(
                    context,
                    "Neutralization Status",
                    subscription.autoKill
                        ? "AUTO-PILOT ACTIVE"
                        : "MANUAL INTERVENTION",
                    subscription.autoKill
                        ? Icons.bolt_rounded
                        : Icons.touch_app_rounded,
                    subscription.autoKill ? AppTheme.violet : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  _buildProtocolCard(
                    context,
                    "Account Security",
                    subscription.isGhostCard
                        ? "GHOST CARD ENCRYPTED"
                        : "STANDARD LINK",
                    Icons.security_rounded,
                    subscription.isGhostCard ? Colors.blue : Colors.orange,
                  ),
                  if (subscription.isGhostCard) ...[
                    _buildSectionTitle("SECURED VIRTUAL CARD"),
                    const SizedBox(height: 16),
                    GhostCardWidget(cardHolder: subscription.name),
                    const SizedBox(height: 40),
                  ],

                  _buildSectionTitle("PAYMENT TIMELINE"),
                  const SizedBox(height: 16),
                  _buildTimelineItem(
                    "Next Charge",
                    subscription.renewalDate ?? subscription.date,
                    Icons.event_repeat_rounded,
                    brandColor ?? AppTheme.violet,
                  ),

                  const SizedBox(height: 40),

                  // Danger Zone
                  _buildDangerZone(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildProtocolCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.obsidian,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String label,
    String date,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
            ),
            Text(
              date,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            "NUCLEAR OPTION",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: Colors.redAccent,
              letterSpacing: 1.0,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              "PERMANENT NEUTRALIZATION",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
