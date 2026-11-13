import 'package:flutter/material.dart';

/// BUGÜN wordmark rendered as Flutter vector/text, so it has no opaque image
/// canvas and remains clean on every app surface.
class BugunBrandLogo extends StatelessWidget {
  final double fontSize;

  const BugunBrandLogo({
    super.key,
    this.fontSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BUGÜN',
      image: true,
      child: SizedBox(
        width: fontSize * 3.6,
        height: fontSize * 1.85,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'BUGÜN',
                  maxLines: 1,
                  style: TextStyle(
                    color: const Color(0xFF101010),
                    fontSize: fontSize * 1.02,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -fontSize * 0.045,
                  ),
                ),
              ),
            ),
            Positioned(
              right: fontSize * 0.28,
              top: 0,
              width: fontSize * 1.45,
              height: fontSize * 1.35,
              child: CustomPaint(
                painter: _BugunStarsPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BugunStarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.43, size.height * 0.57);

    void petal(List<Offset> points, Color color) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }

    // Four-color central sparkle, matching the original BUGÜN mark.
    petal([
      center,
      Offset(center.dx - 2, center.dy - size.height * 0.48),
      Offset(center.dx + size.width * 0.12, center.dy - size.height * 0.15),
    ], const Color(0xFFFFB51B));
    petal([
      center,
      Offset(center.dx + size.width * 0.48, center.dy - size.height * 0.04),
      Offset(center.dx + size.width * 0.16, center.dy + size.height * 0.12),
    ], const Color(0xFF20A8E8));
    petal([
      center,
      Offset(center.dx + size.width * 0.02, center.dy + size.height * 0.48),
      Offset(center.dx - size.width * 0.15, center.dy + size.height * 0.16),
    ], const Color(0xFF8654D7));
    petal([
      center,
      Offset(center.dx - size.width * 0.48, center.dy - size.height * 0.04),
      Offset(center.dx - size.width * 0.15, center.dy - size.height * 0.15),
    ], const Color(0xFFEF526C));

    void sparkle(Offset c, double radius, Color color) {
      final path = Path()
        ..moveTo(c.dx, c.dy - radius)
        ..quadraticBezierTo(c.dx + radius * 0.12, c.dy - radius * 0.12, c.dx + radius, c.dy)
        ..quadraticBezierTo(c.dx + radius * 0.12, c.dy + radius * 0.12, c.dx, c.dy + radius)
        ..quadraticBezierTo(c.dx - radius * 0.12, c.dy + radius * 0.12, c.dx - radius, c.dy)
        ..quadraticBezierTo(c.dx - radius * 0.12, c.dy - radius * 0.12, c.dx, c.dy - radius)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    sparkle(
      Offset(size.width * 0.88, size.height * 0.18),
      size.height * 0.19,
      const Color(0xFFFFB51B),
    );
    sparkle(
      Offset(size.width * 0.91, size.height * 0.83),
      size.height * 0.17,
      const Color(0xFF20A8E8),
    );
  }

  @override
  bool shouldRepaint(covariant _BugunStarsPainter oldDelegate) => false;
}
