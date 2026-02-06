import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../services/brand_service.dart';
import '../screens/subscription_detail_screen.dart';

class SubscriptionItem extends StatefulWidget {
  final Subscription subscription;
  const SubscriptionItem({super.key, required this.subscription});

  @override
  State<SubscriptionItem> createState() => _SubscriptionItemState();
}

class _SubscriptionItemState extends State<SubscriptionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.subscription.usageLevel < 0.2) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTrial = widget.subscription.isTrial;
    final brand = BrandService.resolveBrand(widget.subscription.name);
    final brandColor = brand['color'] as Color?;
    final brandIcon = brand['icon'] as IconData?;
    final logoUrl = brand['logo'] as String?;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.slate : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.subscription.usageLevel < 0.2
                  ? Colors.red.withOpacity(0.3 * _pulseAnimation.value)
                  : (isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.04)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.subscription.usageLevel < 0.2
                    ? Colors.red.withOpacity(0.1 * _pulseAnimation.value)
                    : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscriptionDetailScreen(
                      subscription: widget.subscription,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // HERO LOGO
                    Hero(
                      tag: 'sub_logo_${widget.subscription.id}',
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : AppTheme.coolGrey,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: logoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    logoUrl,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Icon(
                                  brandIcon ?? Icons.subscriptions_rounded,
                                  color: brandColor,
                                  size: 28,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.subscription.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.obsidian,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "${widget.subscription.currency}${widget.subscription.price.toInt()}",
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.obsidian,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isTrial
                                    ? Icons.access_time_filled_rounded
                                    : Icons.calendar_month_rounded,
                                size: 14,
                                color: isTrial
                                    ? const Color(0xFFF59E0B)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isTrial
                                    ? "Due in ${widget.subscription.renewalDate}"
                                    : "Renews on ${widget.subscription.renewalDate}",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: isTrial
                                      ? const Color(0xFFF59E0B)
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildPredictiveBar(
                            widget.subscription.daysRemaining,
                            widget.subscription.totalCycleDays,
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPredictiveBar(int days, int total, bool isDark) {
    double progress = 1 - (days / total).clamp(0.0, 1.0);
    Color color = days <= 3
        ? Colors.red
        : (days <= 7 ? Colors.orange : AppTheme.violet);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$days days left",
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              "${(progress * 100).toInt()}% through cycle",
              style: GoogleFonts.outfit(
                fontSize: 8,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
