#!/usr/bin/env python3
"""Remove duplicate methods from dashboard"""

file_path = '/Users/seleemaleshinloye/kill-switch/kill_switch/lib/screens/dashboard_screen.dart'

with open(file_path, 'r') as f:
    lines = f.readlines()

# Find all occurrences of the helper methods
show_notif_lines = []
update_filter_lines = []

for i, line in enumerate(lines):
    if 'void _showNotificationCenter(BuildContext context)' in line:
        show_notif_lines.append(i)
    if 'void _updateFilteredSubscriptions(List<Subscription> allSubscriptions)' in line:
        update_filter_lines.append(i)

print(f"Found _showNotificationCenter at lines: {[l+1 for l in show_notif_lines]}")
print(f"Found _updateFilteredSubscriptions at lines: {[l+1 for l in update_filter_lines]}")

# Keep only the first occurrence (around line 733) and remove others
# We need to remove from the end to preserve line numbers
if len(show_notif_lines) > 1:
    # Remove duplicates from the end
    for start_line in reversed(show_notif_lines[1:]):
        # Find the end of this method (next closing brace at same indentation)
        end_line = start_line
        for j in range(start_line + 1, len(lines)):
            if lines[j].strip() == '}' and not lines[j].startswith('    '):
                end_line = j
                break
        # Remove lines
        del lines[start_line:end_line+1]
        print(f"Removed duplicate _showNotificationCenter from line {start_line+1} to {end_line+1}")

# Reload to get fresh line numbers
with open(file_path, 'w') as f:
    f.writelines(lines)

# Re-read for second pass
with open(file_path, 'r') as f:
    lines = f.readlines()

update_filter_lines = []
for i, line in enumerate(lines):
    if 'void _updateFilteredSubscriptions(List<Subscription> allSubscriptions)' in line:
        update_filter_lines.append(i)

if len(update_filter_lines) > 1:
    for start_line in reversed(update_filter_lines[1:]):
        end_line = start_line
        for j in range(start_line + 1, len(lines)):
            if lines[j].strip() == '}' and not lines[j].startswith('    '):
                end_line = j
                break
        del lines[start_line:end_line+1]
        print(f"Removed duplicate _updateFilteredSubscriptions from line {start_line+1} to {end_line+1}")

with open(file_path, 'w') as f:
    f.writelines(lines)

print("✅ All duplicates removed!")
