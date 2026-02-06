import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/vault_service.dart';

class VaultScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const VaultScreen({super.key, required this.onUnlocked});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with SingleTickerProviderStateMixin {
  final VaultService _vaultService = VaultService();
  late AnimationController _controller;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_isAuthenticating) _authenticate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _authenticate() async {
    setState(() => _isAuthenticating = true);
    try {
      final success = await _vaultService.authenticate();
      if (mounted) {
        if (success) {
          widget.onUnlocked();
        } else {
          setState(() => _isAuthenticating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication failed')),
          );
        }
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
      if (mounted) {
        setState(() => _isAuthenticating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Security Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, color: AppTheme.gold, size: 32),
              const SizedBox(height: 16),
              Text(
                "KILL SWITCH VAULT",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 2,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                "Biometric Protection Active",
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
              const SizedBox(height: 60),
              GestureDetector(
                onTap: _authenticate,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.gold.withValues(
                          alpha: 0.2 + 0.3 * _controller.value,
                        ),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gold.withValues(
                            alpha: 0.1 * _controller.value,
                          ),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isAuthenticating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.gold,
                              ),
                            )
                          : Icon(
                              Icons.fingerprint_rounded,
                              color: AppTheme.gold,
                              size: 48,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                _isAuthenticating ? "VERIFYING..." : "SCAN FINGERPRINT",
                style: GoogleFonts.outfit(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 60),
              TextButton(
                onPressed: widget.onUnlocked,
                child: Text(
                  "Bypass Secure Mode",
                  style: TextStyle(
                    color: Colors.white12,
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
