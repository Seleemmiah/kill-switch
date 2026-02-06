import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class GhostCardWidget extends StatefulWidget {
  final String cardHolder;
  final String? brandLogo;

  const GhostCardWidget({super.key, required this.cardHolder, this.brandLogo});

  @override
  State<GhostCardWidget> createState() => _GhostCardWidgetState();
}

class _GhostCardWidgetState extends State<GhostCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  void _toggleCard() {
    if (_showBack) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: angle < pi / 2 ? _buildFront() : _buildBack(angle),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F172A),
            const Color(0xFF1E293B),
            const Color(0xFF334155),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "GHOST CARD",
                style: GoogleFonts.outfit(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  fontSize: 12,
                ),
              ),
              const Icon(
                Icons.security_rounded,
                color: Colors.blueAccent,
                size: 24,
              ),
            ],
          ),
          const Spacer(),
          Text(
            "**** **** **** 8291",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 4.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CARD HOLDER",
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 8,
                    ),
                  ),
                  Text(
                    widget.cardHolder.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "EXPIRES",
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 8,
                    ),
                  ),
                  Text(
                    "08/29",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack(double angle) {
    return Transform(
      transform: Matrix4.identity()..rotateY(pi),
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(height: 40, color: Colors.black),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 160,
                    height: 30,
                    color: Colors.white.withOpacity(0.8),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      "412",
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Spacer(),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "This card is virtual and encrypted for single-merchant use. Protocol enforced by Kill Switch.",
                style: GoogleFonts.outfit(color: Colors.white24, fontSize: 8),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
