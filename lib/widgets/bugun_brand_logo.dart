import 'package:flutter/material.dart';

/// Resmi BUGÜN renkli yazı markası; açık renkli kaynak zemini saydamlaştırılır.
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
        child: ClipRect(
          child: Align(
            alignment: const Alignment(0, -0.25),
            child: ColorFiltered(
              // Açık/beyaz kaynak zemininin alfa kanalını düşürür;
              // RGB renkleri değiştirmeden marka renklerini korur.
              colorFilter: const ColorFilter.matrix(<double>[
                1, 0, 0, 0, 0,
                0, 1, 0, 0, 0,
                0, 0, 1, 0, 0,
                -1.15, -1.15, -1.15, 0, 3.35,
              ]),
              child: Image.asset(
                'assets/images/bugun_brand_wordmark.png.png',
                width: fontSize * 3.6,
                height: fontSize * 3.6,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'BUGÜN',
                  style: TextStyle(
                    color: Color(0xFF263B50),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
