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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
              : const [Color(0xFF2FA2F1), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(50)
                : const Color(0x332FA2F1),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
