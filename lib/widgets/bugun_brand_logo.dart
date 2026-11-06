import 'package:flutter/material.dart';

/// Compact BUGÜN brand mark used beside the app name in the main app bar.
class BugunBrandLogo extends StatelessWidget {
  const BugunBrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 36,
          height: 36,
          child: CustomPaint(painter: _BugunMarkPainter()),
        ),
        const SizedBox(width: 9),
        const Text(
          'BUGÜN',
          style: TextStyle(
            color: Color(0xFF123F70),
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
      ],
    );
  }
}

class _BugunMarkPainter extends CustomPainter {
  const _BugunMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0874D1), Color(0xFF073B78)],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.24)),
      background,
    );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.39),
      size.width * 0.16,
      Paint()..color = const Color(0xFFFF9A35),
    );

    final pin = Path()
      ..moveTo(size.width * 0.5, size.height * 0.12)
      ..cubicTo(size.width * 0.25, size.height * 0.12,
          size.width * 0.19, size.height * 0.35,
          size.width * 0.29, size.height * 0.51)
      ..cubicTo(size.width * 0.35, size.height * 0.61,
          size.width * 0.46, size.height * 0.75,
          size.width * 0.5, size.height * 0.81)
      ..cubicTo(size.width * 0.54, size.height * 0.75,
          size.width * 0.65, size.height * 0.61,
          size.width * 0.71, size.height * 0.51)
      ..cubicTo(size.width * 0.81, size.height * 0.35,
          size.width * 0.75, size.height * 0.12,
          size.width * 0.5, size.height * 0.12);
    final whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.105
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pin, whiteStroke);

    final wavePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round;
    final waveOne = Path()
      ..moveTo(size.width * 0.34, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.49,
          size.width * 0.66, size.height * 0.55);
    final waveTwo = Path()
      ..moveTo(size.width * 0.39, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.61,
          size.width * 0.61, size.height * 0.65);
    canvas.drawPath(waveOne, wavePaint);
    canvas.drawPath(waveTwo, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _BugunMarkPainter oldDelegate) => false;
}
