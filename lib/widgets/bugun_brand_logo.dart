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
      child: Image.asset(
        'assets/images/bugun_brand_wordmark.png.png',
        fit: BoxFit.contain,
        height: fontSize * 1.15,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => const Text(
          'BUGÜN',
          style: TextStyle(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
