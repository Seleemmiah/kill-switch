import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedFilterIndex = 0;
  int? _touchedIndex;

  final List<String> _filters = ["Weekly", "Monthly", "Annual"];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              title: Text(
                "Analytics",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.obsidian,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: false,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainSummary(isDark),
                  const SizedBox(height: 32),

                  // NEW: Interactive Filters
                  _buildFilterBar(isDark),
                  const SizedBox(height: 24),

                  _buildSectionHeader("Spending Trend", isDark),
                  const SizedBox(height: 16),
                  _buildChartContainer(isDark),
                  const SizedBox(height: 32),

                  _buildSectionHeader("Spending by Category", isDark),
                  const SizedBox(height: 16),
                  _buildCategoryList(isDark),
                  const SizedBox(height: 32),
                  _buildSavingInsights(isDark),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: _filters.asMap().entries.map((entry) {
          final isSelected = _selectedFilterIndex == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedFilterIndex = entry.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.violet : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.violet.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.value,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppTheme.obsidian,
      ),
    );
  }

  Widget _buildMainSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.violet.withOpacity(0.8), AppTheme.violet]
              : [AppTheme.violet, AppTheme.violet.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violet.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Monthly Burn",
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "-12% vs last month",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "₦42,500.00",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSummaryMiniItem("Saved", "₦12,000", Icons.shield_rounded),
              const SizedBox(width: 24),
              _buildSummaryMiniItem("Active", "14 Subs", Icons.sync_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMiniItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartContainer(bool isDark) {
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: LineChart(
        LineChartData(
          // NEW: Interactive Touch Response
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              // tooltipBgColor: AppTheme.violet,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    "₦${(spot.y * 10).toInt()}k",
                    GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
            touchCallback:
                (FlTouchEvent event, LineTouchResponse? touchResponse) {
                  if (!event.isInterestedForInteractions ||
                      touchResponse == null ||
                      touchResponse.lineBarSpots == null) {
                    setState(() => _touchedIndex = null);
                    return;
                  }
                  final index = touchResponse.lineBarSpots!.first.spotIndex;
                  if (index != _touchedIndex) {
                    HapticFeedback.selectionClick();
                    setState(() => _touchedIndex = index);
                  }
                },
          ),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        days[value.toInt()],
                        style: TextStyle(
                          color: isDark ? Colors.white30 : Colors.black26,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}k',
                    style: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black26,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3),
                FlSpot(1, 4),
                FlSpot(2, 3.5),
                FlSpot(3, 5),
                FlSpot(4, 4),
                FlSpot(5, 7),
                FlSpot(6, 6),
              ],
              isCurved: true,
              color: AppTheme.violet,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: _touchedIndex == index ? 6 : 0,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: AppTheme.violet,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.violet.withOpacity(0.2),
                    AppTheme.violet.withOpacity(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(bool isDark) {
    final categories = [
      {
        'name': 'Entertainment',
        'amount': '₦18,200',
        'color': Colors.red,
        'percent': 0.7,
      },
      {
        'name': 'Music',
        'amount': '₦4,500',
        'color': Colors.green,
        'percent': 0.3,
      },
      {
        'name': 'Work & AI',
        'amount': '₦12,900',
        'color': Colors.blue,
        'percent': 0.5,
      },
      {
        'name': 'Lifestyle',
        'amount': '₦6,900',
        'color': Colors.orange,
        'percent': 0.4,
      },
    ];

    return Column(
      children: categories
          .map((cat) => _buildCategoryItem(cat, isDark))
          .toList(),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> cat, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cat['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    cat['name'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.obsidian,
                    ),
                  ),
                ],
              ),
              Text(
                cat['amount'] as String,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.obsidian,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cat['percent'] as double,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(cat['color'] as Color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingInsights(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, color: AppTheme.gold),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Smart Insight",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.gold,
                  ),
                ),
                Text(
                  "You could save ₦3,500/mo by neutralizing unused 'Paramount+' subscription detected via banking feed.",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
