import 'package:flutter/material.dart';

/// The official BUGÜN logo used in the Play Store listing.
class BugunBrandLogo extends StatelessWidget {
  const BugunBrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/bugun_play_store_icon_512.png',
      width: 48,
      height: 48,
      fit: BoxFit.contain,
      semanticLabel: 'BUGÜN',
      errorBuilder: (context, error, stackTrace) => const Text(
        'BUGÜN',
        style: TextStyle(
          color: Color(0xFF123F70),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.7,
        ),
      ),
    );
  }
}
