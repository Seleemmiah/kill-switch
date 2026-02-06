import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'credit_card_widget.dart';
import 'add_subscription_sheet.dart';
import '../services/vault_service.dart';
import '../services/brand_service.dart';

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue newVal,
  ) {
    if (newVal.selection.baseOffset == 0) return newVal;
    String entered = newVal.text.replaceAll(' ', '');
    StringBuffer buf = StringBuffer();
    for (int i = 0; i < entered.length; i++) {
      buf.write(entered[i]);
      int idx = i + 1;
      if (idx % 4 == 0 && idx != entered.length) buf.write(' ');
    }
    return newVal.copyWith(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: buf.toString().length),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue newVal,
  ) {
    String txt = newVal.text.replaceAll('/', '');
    if (txt.length > 4) return old;
    StringBuffer buf = StringBuffer();
    for (int i = 0; i < txt.length; i++) {
      buf.write(txt[i]);
      if (i == 1 && txt.length > 2) buf.write('/');
    }
    return newVal.copyWith(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: buf.toString().length),
    );
  }
}

class AddCardSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onCardAdded;
  final ScrollController? scrollController;
  const AddCardSheet({
    super.key,
    required this.onCardAdded,
    this.scrollController,
  });
  @override
  State<AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<AddCardSheet> {
  final VaultService _vaultService = VaultService();
  final _numC = TextEditingController();
  final _expC = TextEditingController();
  final _nameC = TextEditingController();
  final _cvvC = TextEditingController();
  String _brand = "Unknown";
  String _expiry = "MM/YY";
  String _holder = "SECURE CARD";
  String _bank = "";
  bool _loading = false;

  String get _url {
    return "${ApiService.baseUrl}/api/v1/resolve-card";
  }

  void _resolve() async {
    String num = _numC.text.replaceAll(' ', '');
    if (num.length == 16 &&
        _expC.text.length == 5 &&
        _cvvC.text.length == 3 &&
        !_loading) {
      setState(() {
        _loading = true;
        _holder = "VERIFYING...";
      });
      try {
        final res = await http.post(
          Uri.parse(_url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"bin_number": num}),
        );
        if (res.statusCode == 200 && mounted) {
          final d = jsonDecode(res.body);
          setState(() {
            _loading = false;
            _holder = d['account_name'];
            _bank = d['bank_name'];
            _nameC.text = _holder;
            if (d['brand'] != "Unknown") _brand = d['brand'];
          });
        }
      } catch (e) {
        if (mounted) setState(() => _holder = "NAME NOT FOUND");
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Link Card & Track",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // IMPORT OPTIONS
            Row(
              children: [
                _buildImportCard(
                  null,
                  "Import from\nGmail",
                  assetPath: "assets/gmail.png",
                ),
                const SizedBox(width: 12),
                _buildImportCard(
                  null,
                  "Import from\nfile",
                  assetPath: "assets/folder.png",
                ),
                const SizedBox(width: 12),
                _buildImportCard(
                  null,
                  "Import from\nPhotos",
                  assetPath:
                      "assets/logo.png", // Use logo.png or another suitable asset
                ),
              ],
            ),
            const SizedBox(height: 32),

            // POPULAR SERVICES
            Text(
              "Popular Services",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5, // Taller cards for services
              children: [
                _buildServiceCard("Netflix"),
                _buildServiceCard("YouTube Premium"),
                _buildServiceCard("Amazon Prime"),
                _buildServiceCard("ChatGPT"),
                _buildServiceCard("Lightroom"),
                _buildServiceCard("Spotify"),
                _buildServiceCard("Apple Music"),
                _buildServiceCard("Paramount+"),
                _buildServiceCard("Audible"),
                _buildServiceCard("iCloud+"),
                _buildCustomServiceTile(),
              ],
            ),

            const SizedBox(height: 32),
            Text(
              "Manual Entry",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),

            CreditCardWidget(
              color: _getColor(_brand),
              last4: l4(_numC.text),
              brand: _brand == "Unknown" ? "Secured" : _brand,
              expiry: _expiry,
              cardHolder: _holder,
            ),
            if (_bank.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Bank: $_bank",
                  style: const TextStyle(fontSize: 10, color: Colors.white24),
                ),
              ),
            const SizedBox(height: 24),
            _buildInput(
              _numC,
              "Card Number",
              "0000 0000 0000 0000 000",
              Icons.credit_card,
              [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
                CardNumberFormatter(),
              ],
              (v) {
                setState(() => _brand = _getBrand(v));
                _resolve();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInput(
                    _expC,
                    "Expiry",
                    "MM/YY",
                    null,
                    [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      ExpiryDateFormatter(),
                    ],
                    (v) {
                      setState(() => _expiry = v.isEmpty ? "MM/YY" : v);
                      _resolve();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInput(
                    _cvvC,
                    "CVV",
                    "•••",
                    null,
                    [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    (_) => _resolve(),
                    hide: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInput(
              _nameC,
              "Card Holder",
              _holder,
              Icons.person_outline,
              null,
              null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (_numC.text.isEmpty) return;
                  try {
                    final newCard = {
                      "last4": l4(_numC.text),
                      "brand": _brand,
                      "color": _getColor(_brand).value,
                      "expiry": _expC.text,
                      "isDefault": false,
                      "bank": _bank,
                    };
                    await _vaultService.saveCard(newCard);
                    widget.onCardAdded(newCard);
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    debugPrint("Save Card Error: $e");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save card: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "LINK CARD",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImportCard(IconData? icon, String label, {String? assetPath}) {
    // Assuming context is available or pass it
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        height: 100, // Large square feel
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (assetPath != null)
              Image.asset(
                assetPath,
                width: 24,
                height: 24,
                errorBuilder: (c, e, s) => Icon(
                  icon ?? Icons.import_export_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 24,
                ),
              )
            else
              Icon(
                icon ?? Icons.import_export_rounded,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 24,
              ),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = BrandService.resolveBrand(name);
    final logoUrl = brand['logo'] as String?;

    return GestureDetector(
      onTap: () {
        // Mock Subscription Data
        final subData = {
          'name': name,
          'price': 2200.00,
          'currency': '₦',
          'date': DateTime.now().toIso8601String(),
          'renewal_date': 'Next Month',
          'category': 'Entertainment',
          'logo': logoUrl,
        };
        widget.onCardAdded(subData);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added successfully!'),
            backgroundColor: AppTheme.violet,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (logoUrl != null)
              Image.asset(
                logoUrl,
                width: 32,
                height: 32,
                errorBuilder: (c, e, s) => Icon(
                  brand['icon'] as IconData? ?? Icons.subscriptions_rounded,
                  size: 32,
                  color: Colors.grey,
                ),
              )
            else
              Icon(
                brand['icon'] as IconData? ?? Icons.subscriptions_rounded,
                size: 32,
                color: Colors.grey,
              ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomServiceTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close current sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, controller) =>
                AddSubscriptionSheet(scrollController: controller),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              size: 32,
              color: AppTheme.violet,
            ),
            const SizedBox(height: 8),
            Text(
              "Custom...",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController c,
    String label,
    String hint,
    IconData? icon,
    List<TextInputFormatter>? fmt,
    Function(String)? onC, {
    bool hide = false,
  }) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      obscureText: hide,
      inputFormatters: fmt,
      onChanged: onC,
      style: GoogleFonts.outfit(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 16) : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: const TextStyle(fontSize: 11, color: Colors.white38),
        hintStyle: const TextStyle(fontSize: 11, color: Colors.white10),
      ),
    );
  }

  String _getBrand(String n) {
    final c = n.replaceAll(' ', '');
    if (c.startsWith('4')) return "VISA";
    if (RegExp(r'^5[1-5]').hasMatch(c)) return "MasterCard";
    if (RegExp(r'^(506[01]|507[89]|6500|5060)').hasMatch(c)) return "Verve";
    return "Unknown";
  }

  Color _getColor(String b) {
    switch (b) {
      case "VISA":
        return const Color(0xFF1E1E1E);
      case "MasterCard":
        return const Color(0xFF2A4B7C);
      case "Verve":
        return const Color(0xFF125633);
      default:
        return const Color(0xFF333333);
    }
  }

  String l4(String s) => s.replaceAll(' ', '').length >= 4
      ? s.replaceAll(' ', '').substring(s.replaceAll(' ', '').length - 4)
      : "••••";
}
