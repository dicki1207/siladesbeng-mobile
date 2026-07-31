import 'package:flutter/material.dart';

class AnimatedSuccessDialog extends StatefulWidget {
  final String message;
  final bool isLogout;

  const AnimatedSuccessDialog({
    super.key,
    required this.message,
    this.isLogout = false,
  });

  @override
  State<AnimatedSuccessDialog> createState() => _AnimatedSuccessDialogState();
}

class _AnimatedSuccessDialogState extends State<AnimatedSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26), // 0.1 opacity ~ 26/255
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // We'll use a built-in animated icon if Lottie assets aren't present.
                // A TweenAnimationBuilder can create a beautiful checkmark or logout icon effect.
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.bounceOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: widget.isLogout
                              ? Colors.orange.withAlpha(26)
                              : Colors.green.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isLogout
                              ? Icons.logout_rounded
                              : Icons.check_circle_rounded,
                          size: 60,
                          color: widget.isLogout ? Colors.orange : Colors.green,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.isLogout
                      ? 'Terima kasih telah menggunakan layanan kami.'
                      : 'Selamat datang kembali di Sila-DesBeng!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
