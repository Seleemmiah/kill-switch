import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SavingsGoalCard extends StatelessWidget {
  final double currentSavings;
  final double targetSavings;

  const SavingsGoalCard({
    super.key,
    required this.currentSavings,
    required this.targetSavings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (currentSavings / targetSavings).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SAVINGS GOAL",
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gold,
                  letterSpacing: 1,
                ),
              ),
              const Icon(Icons.stars_rounded, color: AppTheme.gold, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${currentSavings.toStringAsFixed(0)}",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                " / \$${targetSavings.toStringAsFixed(0)}",
                style: TextStyle(
                  color: isDark
                      ? Colors.white24
                      : AppTheme.charcoal.withValues(alpha: 0.25),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${(progress * 100).toStringAsFixed(0)}% to yearly target.",
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? Colors.white38
                  : AppTheme.charcoal.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
