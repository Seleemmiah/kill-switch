import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../services/brand_service.dart';

class KillConfirmationDialog extends StatefulWidget {
  final Subscription subscription;
  final VoidCallback onConfirm;

  const KillConfirmationDialog({
    super.key,
    required this.subscription,
    required this.onConfirm,
  });

  @override
  State<KillConfirmationDialog> createState() => _KillConfirmationDialogState();
}

class _KillConfirmationDialogState extends State<KillConfirmationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _shakeController;
  late ConfettiController _confettiController;
  bool _isKilling = false;
  bool _isKilled = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shakeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _executeKill() async {
    HapticFeedback.heavyImpact();
    setState(() => _isKilling = true);

    // Shake animation
    _shakeController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    HapticFeedback.heavyImpact();

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isKilling = false;
      _isKilled = true;
    });

    // Celebration
    HapticFeedback.mediumImpact();
    _confettiController.play();

    await Future.delayed(const Duration(seconds: 2));

    widget.onConfirm();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandService.resolveBrand(widget.subscription.name);
    final brandColor = brand['color'] as Color? ?? AppTheme.violet;
    final logoUrl = brand['logo'] as String?;
    final annualSavings = widget.subscription.price * 12;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _scaleController,
              curve: Curves.easeOutBack,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.deepSlate
                    : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final shake = _shakeController.value *
                          10 *
                          (1 - _shakeController.value);
                      return Transform.translate(
                        offset: Offset(
                          shake *
                              ((_shakeController.value * 20).toInt() % 2 == 0
                                  ? 1
                                  : -1),
                          0,
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: _isKilled ? 0.2 : 1.0,
                          child: AnimatedScale(
                            scale: _isKilled ? 0.5 : 1.0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInBack,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: brandColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _isKilled
                                      ? Colors.red.withValues(alpha: 0.3)
                                      : brandColor.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: logoUrl != null
                                    ? Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Image.asset(
                                          logoUrl,
                                          fit: BoxFit.contain,
                                          errorBuilder: (c, e, s) => Icon(
                                            Icons.subscriptions_rounded,
                                            color: brandColor,
                                            size: 36,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.subscriptions_rounded,
                                        color: brandColor,
                                        size: 36,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  if (_isKilled) ...[
                    // Success State
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF00D4AA),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "NEUTRALIZED",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF00D4AA),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${widget.subscription.name} has been killed",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "You'll save ${widget.subscription.currency}${annualSavings.toStringAsFixed(0)}/year",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00D4AA),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Confirmation State
                    Text(
                      "Kill ${widget.subscription.name}?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.obsidian,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "This will cancel your subscription.\nYou'll save ${widget.subscription.currency}${widget.subscription.price.toStringAsFixed(0)}/month.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Kill button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isKilling ? null : _executeKill,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isKilling
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.bolt_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "NEUTRALIZE",
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cancel button
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        "Keep Subscription",
                        style: GoogleFonts.outfit(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Confetti
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFF00D4AA),
              Color(0xFF8B5CF6),
              Color(0xFFFFB800),
              Color(0xFF00B4D8),
              Color(0xFFFF4D6A),
            ],
            numberOfParticles: 30,
            gravity: 0.3,
          ),
        ],
      ),
    );
  }
}
