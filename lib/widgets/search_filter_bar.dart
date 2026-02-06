import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/subscription.dart';

class SearchFilterBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onCategoryFilter;
  final Function(String) onSortChanged;
  final List<String> categories;

  const SearchFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onCategoryFilter,
    required this.onSortChanged,
    required this.categories,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String _sortBy = 'date'; // date, price, name, renewal

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.slate : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: Colors.grey, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: widget.onSearchChanged,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: isDark ? Colors.white : AppTheme.obsidian,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search subscriptions...',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  color: Colors.grey,
                  onPressed: () {
                    _searchController.clear();
                    widget.onSearchChanged('');
                  },
                ),
            ],
          ),
        ),

        // Filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildFilterChip('All', null, isDark, icon: Icons.apps_rounded),
              const SizedBox(width: 8),
              ...widget.categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    category,
                    category,
                    isDark,
                    icon: _getCategoryIcon(category),
                  ),
                );
              }),
              const SizedBox(width: 8),
              _buildSortButton(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String? value,
    bool isDark, {
    IconData? icon,
  }) {
    final isSelected = _selectedCategory == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = value);
        widget.onCategoryFilter(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.violet
              : (isDark ? AppTheme.slate : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppTheme.violet.withOpacity(0.5), width: 2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton(bool isDark) {
    return GestureDetector(
      onTap: () => _showSortOptions(isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.slate : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort_rounded,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              'Sort',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.obsidian : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort by',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.obsidian,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption('Date Added', 'date', isDark),
            _buildSortOption('Price (High to Low)', 'price_desc', isDark),
            _buildSortOption('Price (Low to High)', 'price_asc', isDark),
            _buildSortOption('Name (A-Z)', 'name', isDark),
            _buildSortOption('Renewal Date', 'renewal', isDark),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value, bool isDark) {
    final isSelected = _sortBy == value;

    return ListTile(
      onTap: () {
        setState(() => _sortBy = value);
        widget.onSortChanged(value);
        Navigator.pop(context);
      },
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? AppTheme.violet : Colors.grey,
      ),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isDark ? Colors.white : AppTheme.obsidian,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'entertainment':
      case 'video':
        return Icons.movie_outlined;
      case 'music':
        return Icons.music_note_outlined;
      case 'work':
      case 'productivity':
        return Icons.work_outline_rounded;
      case 'ai':
        return Icons.psychology_outlined;
      case 'storage':
      case 'cloud':
        return Icons.cloud_outlined;
      case 'design':
        return Icons.palette_outlined;
      case 'fitness':
      case 'health':
        return Icons.fitness_center_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

class SubscriptionFilterHelper {
  static List<Subscription> filterSubscriptions(
    List<Subscription> subscriptions, {
    String? searchQuery,
    String? category,
    String sortBy = 'date',
  }) {
    var filtered = subscriptions;

    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((sub) {
        return sub.name.toLowerCase().contains(query) ||
            sub.category.toLowerCase().contains(query);
      }).toList();
    }

    // Apply category filter
    if (category != null) {
      filtered = filtered.where((sub) {
        return sub.category.toLowerCase() == category.toLowerCase();
      }).toList();
    }

    // Apply sorting
    switch (sortBy) {
      case 'price_desc':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'price_asc':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'renewal':
        // Sort by days remaining (trials and renewals)
        filtered.sort((a, b) {
          final aDays = _parseDaysRemaining(a.renewalDate ?? '');
          final bDays = _parseDaysRemaining(b.renewalDate ?? '');
          return aDays.compareTo(bDays);
        });
        break;
      case 'date':
      default:
        // Keep original order (most recent first)
        break;
    }

    return filtered;
  }

  static int _parseDaysRemaining(String renewalDate) {
    if (renewalDate.toLowerCase().contains('tomorrow')) return 1;
    if (renewalDate.toLowerCase().contains('today')) return 0;

    final match = RegExp(r'(\d+)\s+day').firstMatch(renewalDate.toLowerCase());
    if (match != null) {
      return int.tryParse(match.group(1) ?? '30') ?? 30;
    }

    return 30; // Default
  }

  static List<String> extractCategories(List<Subscription> subscriptions) {
    final categories = subscriptions.map((s) => s.category).toSet().toList();
    categories.sort();
    return categories;
  }
}
