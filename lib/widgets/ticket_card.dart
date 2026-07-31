import 'package:flutter/material.dart';

class TicketCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double cutoutRadius;

  const TicketCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.cutoutRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TicketClipper(cutoutRadius: cutoutRadius),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  final double cutoutRadius;

  _TicketClipper({this.cutoutRadius = 12.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();

    // Calculate position for the cutouts (e.g., at 35% of height)
    final cutoutY = size.height * 0.35;

    // Add cutouts on left and right
    path.addOval(
      Rect.fromCircle(center: Offset(0, cutoutY), radius: cutoutRadius),
    );

    path.addOval(
      Rect.fromCircle(
        center: Offset(size.width, cutoutY),
        radius: cutoutRadius,
      ),
    );

    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class DashedLineSeparator extends StatelessWidget {
  final double height;
  final Color color;

  const DashedLineSeparator({
    super.key,
    this.height = 1,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}
