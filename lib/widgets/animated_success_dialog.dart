import 'package:flutter/material.dart';

class AnimatedSuccessDialog extends StatefulWidget {
  final String message;
  final String? subMessage;
  final bool isLogout;
  final IconData? customIcon;

  const AnimatedSuccessDialog({
    super.key,
    required this.message,
    this.subMessage,
    this.isLogout = false,
    this.customIcon,
  });

  @override
  State<AnimatedSuccessDialog> createState() => _AnimatedSuccessDialogState();
}

class _AnimatedSuccessDialogState extends State<AnimatedSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _pulseRingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _cardScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.9, curve: Curves.elasticOut),
      ),
    );

    _pulseRingAnimation = Tween<double>(begin: 0.6, end: 1.25).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutQuad),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = widget.isLogout
        ? const Color(0xFFF97316)
        : const Color(0xFF10B981);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _cardScaleAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? primaryAccent.withValues(alpha: 0.35)
                      : primaryAccent.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryAccent.withValues(
                      alpha: isDark ? 0.25 : 0.15,
                    ),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Icon with Pulse Ring
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Pulsing Ring
                        AnimatedBuilder(
                          animation: _pulseRingAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseRingAnimation.value,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryAccent.withValues(
                                      alpha:
                                          (1.0 -
                                                  (_pulseRingAnimation.value -
                                                          0.6) /
                                                      0.65)
                                              .clamp(0.0, 0.45),
                                    ),
                                    width: 3,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Inner Animated Circle
                        ScaleTransition(
                          scale: _iconScaleAnimation,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.isLogout
                                    ? [
                                        const Color(0xFFFB923C),
                                        const Color(0xFFEA580C),
                                      ]
                                    : [
                                        const Color(0xFF34D399),
                                        const Color(0xFF059669),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryAccent.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.customIcon ??
                                  (widget.isLogout
                                      ? Icons.logout_rounded
                                      : Icons.check_rounded),
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Simplified Clean Title
                  Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Optional Short Sub-message
                  if (widget.subMessage != null &&
                      widget.subMessage!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
