import 'package:flutter/material.dart';

/// Orijinal BUGÜN marka görselini kullanır; yalnızca beyaz kaynak zemini
/// alfa kanalında saydamlaştırılır. Logonun RGB renk kanalları korunur.
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
        child: ColorFiltered(
          // Flutter renk matrisi kanalları 0-255 aralığında işler.
          // Bu katsayılarla saf beyazın alfa değeri 0, renk kanalları ise değişmez.
          colorFilter: const ColorFilter.matrix(<double>[
            1, 0, 0, 0, 0,
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            -0.0039215686, -0.0039215686, -0.0039215686, 0, 3,
          ]),
          child: Image.asset(
            'assets/images/bugun_brand_wordmark.png.png',
            width: fontSize * 3.6,
            height: fontSize * 1.85,
            fit: BoxFit.contain,
            alignment: Alignment.center,
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
    );
  }
}

/// Tüm ana ekranlarda aynı ölçüde şehir/profil ikonları.
class BugunHeaderActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const BugunHeaderActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        iconSize: 24,
        visualDensity: VisualDensity.standard,
        icon: Icon(icon),
      ),
    );
  }
}
