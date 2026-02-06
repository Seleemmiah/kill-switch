import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/brand_service.dart';

class AddSubscriptionSheet extends StatefulWidget {
  final ScrollController? scrollController;
  const AddSubscriptionSheet({super.key, this.scrollController});

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final _nameC = TextEditingController();
  final _priceC = TextEditingController();
  bool _isTrial = true;
  DateTime _renewalDate = DateTime.now().add(const Duration(days: 7));
  String _selectedCategory = "Entertainment";
  bool _autoKill = true;
  bool _useGhostCard = false;

  final List<String> _categories = [
    "Entertainment",
    "Music",
    "Work/AI",
    "Lifestyle",
    "Storage",
    "Health",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _nameC.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameC.dispose();
    _priceC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isTrial ? "Track New Trial" : "Add Subscription",
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.obsidian,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter details to monitor and neutralize charges.",
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            "Service Name",
            _nameC,
            Icons.branding_watermark_rounded,
            isDark,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  "Price (After trial)",
                  _priceC,
                  Icons.payments_rounded,
                  isDark,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              _buildCategoryDropdown(isDark),
            ],
          ),
          const SizedBox(height: 24),
          _buildTrialToggle(isDark),
          const SizedBox(height: 12),
          _buildFeatureToggle(
            "Auto-Pilot Kill Switch",
            "Automatically cancel 24h before expiry.",
            Icons.auto_fix_high_rounded,
            _autoKill,
            (v) => setState(() => _autoKill = v),
            AppTheme.violet,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildFeatureToggle(
            "Ghost Card Protection",
            "Secure with a one-time virtual card.",
            Icons.security_rounded,
            _useGhostCard,
            (v) => setState(() => _useGhostCard = v),
            Colors.blue,
            isDark,
          ),
          const SizedBox(height: 24),
          _buildDatePicker(isDark),
          const SizedBox(height: 32),
          _buildSubmitButton(isDark),
          const SizedBox(height: 12),
          if (_isTrial) _buildAutoKillHint(isDark),
        ],
      ),
    );
  }

  Widget _buildFeatureToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    Color activeColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value ? activeColor.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? activeColor : Colors.black26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDark, {
    TextInputType? keyboardType,
  }) {
    // Automatic Brand Detection for the name field
    Widget? prefix;
    if (controller == _nameC && _nameC.text.isNotEmpty) {
      final brand = BrandService.resolveBrand(_nameC.text);
      if (brand['logo'] != null) {
        prefix = Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image.asset(brand['logo'], width: 20, height: 20),
        );
      } else {
        prefix = Icon(
          brand['icon'] as IconData? ?? icon,
          size: 20,
          color: AppTheme.violet,
        );
      }
    } else {
      prefix = Icon(icon, size: 20, color: AppTheme.violet);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.black45,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : AppTheme.obsidian,
          ),
          decoration: InputDecoration(
            prefixIcon: prefix,
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Category",
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.black45,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              dropdownColor: isDark ? AppTheme.slate : Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    style: GoogleFonts.outfit(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() => _selectedCategory = newValue!);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrialToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isTrial ? AppTheme.violet.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isTrial
              ? AppTheme.violet.withOpacity(0.3)
              : (isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_rounded,
            color: _isTrial
                ? AppTheme.violet
                : (isDark ? Colors.white38 : Colors.black26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Is this a Free Trial?",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppTheme.obsidian,
                  ),
                ),
                Text(
                  "We'll alert you before it converts to paid.",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isTrial,
            activeColor: AppTheme.violet,
            onChanged: (v) => setState(() => _isTrial = v),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _renewalDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) setState(() => _renewalDate = date);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isTrial ? "Trial Expiry Date" : "Renewal Date",
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppTheme.violet,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  "${_renewalDate.day}/${_renewalDate.month}/${_renewalDate.year}",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.edit_rounded, size: 16, color: Colors.black26),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // In a real app, this would call ApiService to save
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${_nameC.text} tracking active."),
              backgroundColor: AppTheme.violet,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.violet,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          _isTrial ? "Start Trial Watch" : "Save Subscription",
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoKillHint(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_fix_high_rounded,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Protocol: 'One-Time Use' enabled. Auto-kill active.",
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.orange[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
