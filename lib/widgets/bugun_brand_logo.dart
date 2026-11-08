import 'package:flutter/material.dart';

/// BUGÜN yazı markasını yıldızlı Ü harf detayıyla gösterir.
class BugunBrandLogo extends StatelessWidget {
  final double fontSize;

  const BugunBrandLogo({
    super.key,
    this.fontSize = 34,
  });

  TextStyle get _style => TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
        height: 1,
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BUGÜN',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('BUG', style: _style),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Text('U', style: _style),
              Positioned(
                left: fontSize * 0.16,
                top: -fontSize * 0.04,
                child: Icon(Icons.auto_awesome, size: fontSize * 0.22, color: Colors.black),
              ),
              Positioned(
                right: fontSize * 0.16,
                top: -fontSize * 0.04,
                child: Icon(Icons.auto_awesome, size: fontSize * 0.22, color: Colors.black),
              ),
            ],
          ),
          Text('N', style: _style),
        ],
      ),
    );
  }
}
