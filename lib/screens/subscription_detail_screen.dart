import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../services/brand_service.dart';
import '../widgets/ghost_card_widget.dart';
import '../widgets/kill_confirmation_dialog.dart';
import '../providers/app_providers.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  final Subscription subscription;

  const SubscriptionDetailScreen({super.key, required this.subscription});

  @override
  ConsumerState<SubscriptionDetailScreen> createState() => _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends ConsumerState<SubscriptionDetailScreen> {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
  }

  Future<void> _syncToCalendar() async {
    final sub = widget.subscription;
    final permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      await _deviceCalendarPlugin.requestPermissions();
    }

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    if (calendarsResult.isSuccess && calendarsResult.data != null && calendarsResult.data!.isNotEmpty) {
      final calendarId = calendarsResult.data!.first.id;
      final TZDateTime start = TZDateTime.now(local).add(Duration(days: sub.daysRemaining));
      final TZDateTime end = start.add(const Duration(hours: 1));

      final event = Event(
        calendarId,
        title: 'Kill Switch: ${sub.name} Renewal',
        description: 'Your ${sub.name} subscription renews today (${sub.currency}${sub.price.toStringAsFixed(2)})',
        start: start,
        end: end,
      );

      final createResult = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      if (mounted) {
        if (createResult?.isSuccess ?? false) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully synced to your calendar!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to sync to calendar. Check permissions.')),
          );
        }
      }
    }
  }

  Widget _buildStatRow(String label, String value, Color valueColor, Color? subtitleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brand = BrandService.resolveBrand(sub.name);
    final logoUrl = brand['logo'] as String?;
    
    final textColor = isDark ? Colors.white : AppTheme.obsidian;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          "Details",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Hero(
                tag: 'sub_logo_${sub.id}',
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.coolGrey,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              logoUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Icon(
                            Icons.subscriptions_rounded,
                            size: 40,
                            color: textColor,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                sub.name,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub.category,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                "${sub.currency}${sub.price.toStringAsFixed(2)}",
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                "per month",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 48),

              // Simple Stats Table
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStatRow("Next Billing", sub.renewalDate ?? "Unknown", textColor, subtitleColor),
                    Divider(color: borderColor, height: 1),
                    _buildStatRow("Cycle", "Monthly", textColor, subtitleColor),
                    Divider(color: borderColor, height: 1),
                    _buildStatRow("Status", sub.autoKill ? "Auto-Pilot" : "Manual", AppTheme.violet, subtitleColor),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Calendar Sync Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _syncToCalendar();
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text(
                    "Sync to Calendar",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: borderColor),
                  ),
                ),
              ),

              if (sub.isGhostCard) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Virtual Card",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GhostCardWidget(cardHolder: sub.name),
              ],

              const SizedBox(height: 48),

              // Cancellation Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                   onPressed: () async {
                    HapticFeedback.heavyImpact();
                    
                    final cancelUrl = brand['cancel_url'] ?? sub.cancelUrl;
                    if (cancelUrl != null && cancelUrl.isNotEmpty) {
                      final uri = Uri.parse(cancelUrl);
                      if (await canLaunchUrl(uri)) {
                         await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }

                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => KillConfirmationDialog(
                        subscription: sub,
                        onConfirm: () {
                          ref.read(subscriptionsProvider.notifier).killSubscription(sub);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    foregroundColor: Colors.red[600],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                     (brand['cancel_url'] ?? sub.cancelUrl) != null ? "Open Cancellation Page" : "Cancel Subscription",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
