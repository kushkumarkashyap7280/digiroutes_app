import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Soft page background: base colour plus two blurred orange glows.
/// Works in both light and dark themes.
class AppBackdrop extends StatelessWidget {
  final Widget child;
  const AppBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final glow = AppTheme.orange.withValues(alpha: dark ? 0.16 : 0.13);

    Widget blob(double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [glow, glow.withValues(alpha: 0)]),
          ),
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: AppTheme.bgColor(context)),
        Positioned(top: -140, right: -120, child: blob(380)),
        Positioned(bottom: -160, left: -140, child: blob(420)),
        child,
      ],
    );
  }
}
