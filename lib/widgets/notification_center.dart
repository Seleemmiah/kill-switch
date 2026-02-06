import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final String subscriptionId;
  final String subscriptionName;
  final String priority;
  final String? actionUrl;
  final String? actionLabel;
  final DateTime createdAt;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.subscriptionId,
    required this.subscriptionName,
    required this.priority,
    this.actionUrl,
    this.actionLabel,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      subscriptionId: json['subscription_id'],
      subscriptionName: json['subscription_name'],
      priority: json['priority'],
      actionUrl: json['action_url'],
      actionLabel: json['action_label'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }

  Color get priorityColor {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'trial_ending_soon':
      case 'trial_ending_today':
        return Icons.timer_outlined;
      case 'renewal_reminder':
        return Icons.event_repeat_rounded;
      case 'low_usage_warning':
        return Icons.trending_down_rounded;
      case 'price_increase':
        return Icons.trending_up_rounded;
      case 'forgotten_subscription':
        return Icons.help_outline_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }
}

class NotificationCenterSheet extends StatefulWidget {
  final List<NotificationModel> notifications;
  final Function(String)? onNotificationTap;
  final Function(String)? onActionTap;
  final Function(String)? onDismiss;

  const NotificationCenterSheet({
    super.key,
    required this.notifications,
    this.onNotificationTap,
    this.onActionTap,
    this.onDismiss,
  });

  @override
  State<NotificationCenterSheet> createState() =>
      _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends State<NotificationCenterSheet> {
  String _filter = 'all'; // all, unread, urgent

  List<NotificationModel> get _filteredNotifications {
    switch (_filter) {
      case 'unread':
        return widget.notifications.where((n) => !n.isRead).toList();
      case 'urgent':
        return widget.notifications
            .where((n) => n.priority == 'urgent' || n.priority == 'high')
            .toList();
      default:
        return widget.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = widget.notifications.where((n) => !n.isRead).length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.obsidian : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Notifications",
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.obsidian,
                      ),
                    ),
                    if (unreadCount > 0)
                      Text(
                        "$unreadCount unread",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.violet,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          // Filter tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Unread', 'unread', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Urgent', 'urgent', isDark),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Notifications list
          Expanded(
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notif = _filteredNotifications[index];
                      return _buildNotificationCard(notif, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.violet
              : (isDark ? AppTheme.slate : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif, bool isDark) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDismiss?.call(notif.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.slate : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notif.isRead
                ? Colors.transparent
                : notif.priorityColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: notif.priorityColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notif.typeIcon,
                    color: notif.priorityColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.obsidian,
                        ),
                      ),
                      Text(
                        _formatTime(notif.createdAt),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notif.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.violet,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notif.message,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
            if (notif.actionLabel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onActionTap?.call(notif.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: notif.priorityColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    notif.actionLabel!,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "All caught up!",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No notifications to show",
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.month}/${time.day}';
  }
}
