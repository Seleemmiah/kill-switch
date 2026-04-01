import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/local_storage_service.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.shield_rounded,
      iconColor: AppTheme.violet,
      title: "Take Control",
      subtitle:
          "Stop leaking money to forgotten subscriptions.\nKill Switch puts you in charge.",
      gradient: [
        const Color(0xFF1a1035),
        const Color(0xFF0d0b1a),
      ],
    ),
    _OnboardingPage(
      icon: Icons.radar_rounded,
      iconColor: const Color(0xFF00D4AA),
      title: "We Scan, You Save",
      subtitle:
          "We detect hidden subscriptions from your email\nand bank feeds automatically.",
      gradient: [
        const Color(0xFF0a1628),
        const Color(0xFF0d0b1a),
      ],
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_rounded,
      iconColor: const Color(0xFFFFB800),
      title: "Smart Alerts",
      subtitle:
          "Get warned before trials convert.\nNever pay for something you forgot about.",
      gradient: [
        const Color(0xFF1a1a0a),
        const Color(0xFF0d0b1a),
      ],
    ),
    _OnboardingPage(
      icon: Icons.bolt_rounded,
      iconColor: const Color(0xFFFF4D6A),
      title: "One-Tap Kill",
      subtitle:
          "Cancel subscriptions instantly.\nTrack your savings grow over time.",
      gradient: [
        const Color(0xFF1a0a0f),
        const Color(0xFF0d0b1a),
      ],
    ),
  ];

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _complete() async {
    HapticFeedback.mediumImpact();
    await LocalStorageService.setOnboardingComplete(true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, a1, a2) => const AuthScreen(),
          transitionsBuilder: (context, a1, a2, child) =>
              FadeTransition(opacity: a1, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0b1a),
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: TextButton(
              onPressed: _complete,
              child: Text(
                "Skip",
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 40,
            child: Column(
              children: [
                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? _pages[_currentPage].iconColor
                            : Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Action button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].iconColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? "Get Started"
                            : "Continue",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: page.gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated icon with glow
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: page.iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: page.iconColor.withValues(alpha: 0.2),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: Icon(
                        page.icon,
                        color: page.iconColor,
                        size: 52,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),

              // Title
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.white54,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
