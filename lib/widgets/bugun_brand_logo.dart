import 'package:flutter/material.dart';

/// Uses the original BUGÜN wordmark asset without color filters.
class BugunBrandLogo extends StatelessWidget {
  final double width;
  final double height;

  const BugunBrandLogo({
    super.key,
    this.width = 176,
    this.height = 82,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BUGÜN',
      image: true,
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          'assets/images/bugun_brand_wordmark.png.png',
          width: width,
          height: height,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
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
    );
  }
}

/// Shared, fixed-size city/profile action used by all main app bars.
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
        alignment: Alignment.center,
        splashRadius: 22,
        visualDensity: VisualDensity.standard,
        icon: Icon(icon),
      ),
    );
  }
}

/// One shared app-bar layout for all four primary sections.
class BugunMainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Color backgroundColor;

  const BugunMainAppBar({
    super.key,
    required this.title,
    required this.actions,
    this.bottom,
    this.backgroundColor = const Color(0xFFFFF0DF),
  });

  static const double toolbarHeight = 90;

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      primary: true,
      toolbarHeight: toolbarHeight,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 16,
      actionsPadding: const EdgeInsets.only(right: 8),
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: title,
      actions: actions,
      bottom: bottom,
    );
  }
}
