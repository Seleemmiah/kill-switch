import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class GhostWealthChart extends StatelessWidget {
  const GhostWealthChart({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                "EFFICIENCY TREND",
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                "+12% m/m",
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(0.4, "J", isDark),
                _buildBar(0.6, "F", isDark),
                _buildBar(0.3, "M", isDark),
                _buildBar(0.8, "A", isDark),
                _buildBar(0.5, "M", isDark),
                _buildBar(0.9, "J", isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, String label, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: 40 * heightFactor,
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(
              alpha: heightFactor > 0.7 ? 0.9 : (isDark ? 0.2 : 0.4),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ),
      ],
    );
  }
}
