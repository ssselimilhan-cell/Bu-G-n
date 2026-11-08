import 'package:flutter/material.dart';

/// Resmi BUGÜN renkli yazı markası. Orijinal yıldız oranları ve renkleri korunur.
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
        height: fontSize * 1.25,
        child: ClipRect(
          child: Align(
            alignment: const Alignment(0, -0.5),
            heightFactor: 0.45,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Color(0xFFF7F7F5), BlendMode.multiply),
              child: Image.asset(
                'assets/images/bugun_brand_wordmark.png.png',
                width: fontSize * 3.6,
                height: fontSize * 3.6,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'BUGÜN',
                  style: TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
