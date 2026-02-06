#!/usr/bin/env python3
"""Fix the dashboard_screen.dart file"""

file_path = '/Users/seleemaleshinloye/kill-switch/kill_switch/lib/screens/dashboard_screen.dart'

with open(file_path, 'r') as f:
    lines = f.readlines()

# Fix line 732 - add closing brace
if lines[731].strip() == ');':
    lines[731] = '    );\n  }\n\n'

# Fix line 753 - remove backslash from string interpolation  
for i, line in enumerate(lines):
    if '\\${notif.actionUrl}' in line:
        lines[i] = line.replace('\\${notif.actionUrl}', '${notif.actionUrl}')
        print(f"Fixed line {i+1}: Removed backslash from string interpolation")

# Remove duplicate closing brace at line 775
if lines[774].strip() == '}' and lines[773].strip() == '}':
    del lines[774]
    print("Removed duplicate closing brace")

with open(file_path, 'w') as f:
    f.writelines(lines)

print("✅ Dashboard file fixed!")
