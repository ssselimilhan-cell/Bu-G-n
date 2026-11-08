import 'package:flutter/material.dart';

/// BUGÜN markasını ana sayfada belirgin ve kompakt biçimde gösterir.
class BugunBrandLogo extends StatelessWidget {
  const BugunBrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1268B3),
                Color(0xFFFF8A3D),
              ],
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/bugun_play_store_icon_512.png',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              semanticLabel: 'BUGÜN logosu',
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Color(0xFF174F80),
                child: Center(
                  child: Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'BUGÜN',
          style: TextStyle(
            color: Color(0xFF174F80),
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
      ],
    );
  }
}
