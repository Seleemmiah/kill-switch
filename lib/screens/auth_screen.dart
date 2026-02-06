import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;

  final _formKey = GlobalKey<FormState>();

  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmPassC = TextEditingController();
  final _nameC = TextEditingController();

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _fadeController,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    super.initState();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailC.dispose();
    _passC.dispose();
    _confirmPassC.dispose();
    _nameC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    // Check if passwords match for signup
    if (!_isLogin && _passC.text != _confirmPassC.text) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Safety Protocol Error: Access keys do not match."),
          backgroundColor: AppTheme.alert,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      if (Firebase.apps.isNotEmpty) {
        if (_isLogin) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailC.text.trim(),
            password: _passC.text.trim(),
          );
        } else {
          UserCredential userCred = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: _emailC.text.trim(),
                password: _passC.text.trim(),
              );
          // Try updating profile name
          if (_nameC.text.isNotEmpty) {
            await userCred.user?.updateDisplayName(_nameC.text.trim());
          }
        }
      } else {
        // Fallback for demo if Firebase not configured
        await Future.delayed(const Duration(seconds: 1));
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, a1, a2) => const MainNavigationScreen(),
            transitionsBuilder: (context, a1, a2, child) =>
                FadeTransition(opacity: a1, child: child),
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Auth Protocol Failed: ${e.message}"),
            backgroundColor: AppTheme.alert,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("System Error: $e"),
            backgroundColor: AppTheme.alert,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleAuth() {
    HapticFeedback.selectionClick();
    _formKey.currentState?.reset();
    _emailC.clear();
    _passC.clear();
    _confirmPassC.clear();
    _nameC.clear();
    setState(() => _isLogin = !_isLogin);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.obsidian : AppTheme.studioGrey,
      body: Stack(
        children: [
          // Background Glow (App Aesthetic)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.violet.withValues(alpha: isDark ? 0.05 : 0.03),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      // Core Brand Logo
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.violet.withValues(
                            alpha: isDark ? 0.15 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: AppTheme.violet,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isLogin ? "Welcome Back!" : "Access Protocol",
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.obsidian,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin
                            ? "Unlock your secure wealth vault"
                            : "Initialize your security credentials",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : AppTheme.textSecond,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Input Section
                      if (!_isLogin) ...[
                        _buildLabel("Full Name", isDark),
                        _buildUnifiedInput(
                          controller: _nameC,
                          hint: "John Doe",
                          isDark: isDark,
                          validator: (v) =>
                              v!.isEmpty ? "Identity required" : null,
                        ),
                        const SizedBox(height: 20),
                      ],

                      _buildLabel("Email", isDark),
                      _buildUnifiedInput(
                        controller: _emailC,
                        hint: "helloworld@gmail.com",
                        isDark: isDark,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (!v!.contains('@')) ? "Invalid email" : null,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel("Password", isDark),
                      _buildUnifiedInput(
                        controller: _passC,
                        hint: "••••••••",
                        isDark: isDark,
                        isPassword: _obscurePass,
                        validator: (v) =>
                            v!.length < 6 ? "password must be 6 chars" : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          color: isDark ? Colors.white24 : Colors.black26,
                          iconSize: 20,
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),

                      if (!_isLogin) ...[
                        const SizedBox(height: 20),
                        _buildLabel("Confirm Password", isDark),
                        _buildUnifiedInput(
                          controller: _confirmPassC,
                          hint: "••••••••",
                          isDark: isDark,
                          isPassword: _obscureConfirmPass,
                          validator: (v) => v != _passC.text
                              ? "passwords do not match"
                              : null,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            color: isDark ? Colors.white24 : Colors.black26,
                            iconSize: 20,
                            onPressed: () => setState(
                              () => _obscureConfirmPass = !_obscureConfirmPass,
                            ),
                          ),
                        ),
                      ],

                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              "Forgot password?",
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppTheme.violet,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),

                      // Elite Action Button (App Palette)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.violet,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isLogin ? "Sign In" : "Create Account",
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Unified Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Continue with",
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white24 : Colors.black26,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Social Cluster
                      Row(
                        children: [
                          Expanded(
                            child: _buildStudioSocial(
                              assetPath: 'assets/apple-logo.png',
                              label: "",
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStudioSocial(
                              assetPath: 'assets/google.png',
                              label: "",
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Transition Trigger
                      Center(
                        child: TextButton(
                          onPressed: _toggleAuth,
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white54
                                    : AppTheme.textSecond,
                              ),
                              children: [
                                TextSpan(
                                  text: _isLogin
                                      ? "Don't have an account? "
                                      : "Already verified? ",
                                ),
                                TextSpan(
                                  text: _isLogin ? "Register here" : "Sign in",
                                  style: const TextStyle(
                                    color: AppTheme.violet,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppTheme.obsidian,
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedInput({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    bool isPassword = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.deepSlate : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        validator: validator,
        cursorColor: AppTheme.violet,
        style: GoogleFonts.outfit(
          fontSize: 15,
          color: isDark ? Colors.white : AppTheme.obsidian,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white10 : Colors.black26,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildStudioSocial({
    String? assetPath,
    required String label,
    required bool isDark,
  }) {
    return Container(
      height: 50,
      // width: 50,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.deepSlate : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (assetPath != null)
              Image.asset(assetPath, width: 22, height: 22)
            else
              Icon(
                Icons.login_rounded,
                color: isDark ? Colors.white : AppTheme.obsidian,
                size: 22,
              ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.obsidian,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
