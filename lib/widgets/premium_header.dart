import 'package:flutter/material.dart';

class PremiumHeader extends StatelessWidget {
  final Widget child;
  final double bottomPadding;

  const PremiumHeader({
    super.key,
    required this.child,
    this.bottomPadding = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E88E5), // Original Blue
            Color(0xFF4FC3F7), // Light Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x331E88E5), // 20% opacity shadow matching theme
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        child: Stack(
          children: [
            // Lingkaran dekoratif 1 (Besar di kanan atas)
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(25),
                ),
              ),
            ),
            // Lingkaran dekoratif 2 (Sedang di kiri bawah)
            Positioned(
              bottom: -50,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(15),
                ),
              ),
            ),
            // Lingkaran dekoratif 3 (Kecil di tengah agak atas)
            Positioned(
              top: 20,
              left: MediaQuery.of(context).size.width * 0.4,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(10),
                ),
              ),
            ),
            // Konten Utama
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 16,
                24,
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
