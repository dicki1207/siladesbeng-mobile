import 'package:flutter/material.dart';

class PremiumHeader extends StatelessWidget {
  final Widget child;
  final double bottomPadding;

  const PremiumHeader({
    super.key,
    required this.child,
    this.bottomPadding = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2563EB); // Royal Blue
    const Color darkBlue = Color(0xFF1D4ED8);    // Deep Blue

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryBlue,
            darkBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x332563EB), // Soft blue glow
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Stack(
          children: [
            // Subtle glowing circle 1 (Top Right)
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(20),
                ),
              ),
            ),
            // Subtle glowing circle 2 (Bottom Left)
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(12),
                ),
              ),
            ),
            // Konten Utama
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 10,
                16,
                bottomPadding,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
