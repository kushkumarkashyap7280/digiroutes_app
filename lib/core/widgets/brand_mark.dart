import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The DigiRoutes logo — the same artwork as the launcher icon
/// (`assets/icons/app_icon.png`), clipped to a rounded tile.
class BrandMark extends StatelessWidget {
  final double size;
  final double? radius;
  final bool glow;
  const BrandMark({super.key, required this.size, this.radius, this.glow = false});

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.26;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: glow
            ? const [
                BoxShadow(
                    color: AppTheme.orangeGlow, blurRadius: 40, spreadRadius: 4)
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Image.asset('assets/icons/app_icon.png',
            width: size, height: size, fit: BoxFit.cover),
      ),
    );
  }
}
