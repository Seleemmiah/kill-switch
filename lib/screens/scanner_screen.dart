import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/brand_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ApiService _apiService = ApiService();
  bool _isScanning = false;
  String _scanStatus = "SYSTEM READY";
  List<Map<String, dynamic>> _detectedLeaks = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startGlobalScan() async {
    setState(() {
      _isScanning = true;
      _scanStatus = "INITIALIZING AI...";
      _detectedLeaks = [];
    });
    _controller.forward(from: 0.0);

    // Dynamic status updates
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _scanStatus = "SCANNING SMS...");
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _scanStatus = "SCRAPING GMAIL...");
    });
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() => _scanStatus = "ANALYZING BIN...");
    });

    // Actual Backend Call
    final leaks = await _apiService.getGlobalLeaks();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _detectedLeaks = leaks;
            _scanStatus = "${leaks.length} LEAKS FOUND";
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildRadarUI(isDark),
                    const SizedBox(height: 48),
                    _buildCoreModules(isDark),
                    const SizedBox(height: 40),
                    if (_detectedLeaks.isNotEmpty) _buildResultsSection(isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "GLOBAL SCANNER",
          style: GoogleFonts.outfit(
            color: AppTheme.violet,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Leak Radar",
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppTheme.obsidian,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Tracking unauthorized trial conversions.",
          style: GoogleFonts.outfit(color: Colors.black38, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildRadarUI(bool isDark) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing circles
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: List.generate(3, (index) {
                        double progress =
                            (_controller.value + (index / 3)) % 1.0;
                        return Container(
                          width: 250 * progress,
                          height: 250 * progress,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.violet.withValues(
                                alpha: 0.15 * (1 - progress),
                              ),
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),

              // Inner Core
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppTheme.slate : const Color(0xFFF8FAFC),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.violet.withValues(alpha: 0.1),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  _isScanning ? Icons.radar : Icons.shield_rounded,
                  color: AppTheme.violet,
                  size: 40,
                ),
              ),

              // Scanning Beam
              if (_isScanning)
                RotationTransition(
                  turns: _controller,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          AppTheme.violet.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.1, 0.4],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            _scanStatus,
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white60 : Colors.black45,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            height: 54,
            child: ElevatedButton(
              onPressed: _isScanning ? null : _startGlobalScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.violet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _isScanning ? "SCRUBBING..." : "SCAN WORLD",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreModules(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildModuleItem(
            Icons.bolt_rounded,
            "Authentication Holds",
            "Detecting \$0.00 verification links.",
          ),
          const Divider(height: 32, thickness: 1),
          _buildModuleItem(
            Icons.mail_lock_rounded,
            "Receipt Parsing",
            "Mapping trials from email metadata.",
          ),
        ],
      ),
    );
  }

  Widget _buildModuleItem(IconData icon, String title, String desc) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.violet.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.violet, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.black38),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ACTIVE CONNECTIONS",
                  style: GoogleFonts.outfit(
                    color: AppTheme.violet,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "${_detectedLeaks.length} leaks neutralized",
                  style: TextStyle(color: Colors.black38, fontSize: 13),
                ),
              ],
            ),
            const Icon(Icons.tune_rounded, size: 20, color: Colors.black26),
          ],
        ),
        const SizedBox(height: 20),
        ..._detectedLeaks.map((l) => _buildLeakItem(l, isDark)),
      ],
    );
  }

  Widget _buildLeakItem(Map<String, dynamic> leak, bool isDark) {
    final double usage = (leak['usage'] as num?)?.toDouble() ?? 1.0;
    final bool isLowUsage = usage < 0.2; // Feature 4: Waste
    final brand = BrandService.resolveBrand(leak['service'] ?? "");
    final logoUrl = brand['logo'] as String?;
    final brandColor = brand['color'] as Color?;
    final brandIcon = brand['icon'] as IconData?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      (brandColor ??
                              (leak['risk'] == 'High'
                                  ? Colors.red
                                  : AppTheme.violet))
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: logoUrl != null
                      ? Image.asset(
                          logoUrl,
                          width: 24,
                          height: 24,
                          errorBuilder: (c, e, s) => Icon(
                            brandIcon ?? Icons.radar_rounded,
                            color: brandColor ?? AppTheme.violet,
                            size: 24,
                          ),
                        )
                      : Icon(
                          brandIcon ??
                              (leak['risk'] == 'High'
                                  ? Icons.warning_amber_rounded
                                  : Icons.radar_rounded),
                          color:
                              brandColor ??
                              (leak['risk'] == 'High'
                                  ? Colors.red
                                  : AppTheme.violet),
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leak['service'] ?? "Unknown",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${leak['source']} • ${leak['type']}",
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    leak['status'] ?? "Detected",
                    style: GoogleFonts.outfit(
                      color: leak['risk'] == 'High'
                          ? Colors.red
                          : AppTheme.violet,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "${(usage * 100).toInt()}% Usage",
                    style: TextStyle(
                      color: isLowUsage ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isLowUsage) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_graph_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Feature 4: High waste detected. Suggesting neutralization.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLeakAction(
                  "SECURE CARD",
                  Icons.vpn_key_rounded,
                  Colors.blue,
                  () {}, // Feature 2 Placeholder
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLeakAction(
                  "DEEP KILL",
                  Icons.link_rounded,
                  Colors.red,
                  () async {
                    final url = leak['cancel_url'];
                    if (url != null) {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeakAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
