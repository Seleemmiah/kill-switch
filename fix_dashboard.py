#!/usr/bin/env python3
"""
Script to add helper methods to dashboard_screen.dart
"""

def add_helper_methods():
    file_path = '/Users/seleemaleshinloye/kill-switch/kill_switch/lib/screens/dashboard_screen.dart'
    
    # Read the file
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    # Find the line with "  }\n}\n" that closes _DashboardScreenState
    # We need to insert before the second-to-last }
    insert_index = None
    for i in range(len(lines) - 1, -1, -1):
        if lines[i].strip() == '}' and i > 0:
            # Check if previous line ends with }
            if lines[i-1].strip().endswith(');'):
                insert_index = i
                break
    
    if insert_index is None:
        print("Could not find insertion point")
        return False
    
    # Helper methods to insert
    helper_methods = '''
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
              debugPrint('Opening: ${notif.actionUrl}');
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
'''
    
    # Insert the methods
    lines.insert(insert_index, helper_methods)
    
    # Write back
    with open(file_path, 'w') as f:
        f.writelines(lines)
    
    print(f"✅ Helper methods added at line {insert_index}")
    return True

if __name__ == '__main__':
    add_helper_methods()
