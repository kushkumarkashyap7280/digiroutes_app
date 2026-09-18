import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Frosted-glass surface: blurred backdrop + translucent tint + hairline
/// border + soft shadow. Used for chrome that floats over the map (top bar,
/// bottom nav, result cards) to give the app a premium, layered feel.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry? alignment;

  /// Real backdrop blur uses [BackdropFilter], which does not compose
  /// correctly over an Android platform view (our Google Maps WebView) —
  /// the native surface renders outside Flutter's layer tree and visually
  /// punches through/above any blur above it. Pass `frosted: false` for
  /// glass that sits over [AppMapEmbed] to fall back to a plain translucent
  /// tint (no blur sampling) so stacking order stays correct.
  final bool frosted;

  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding,
    this.margin,
    this.blur = 18,
    this.border,
    this.boxShadow,
    this.alignment,
    this.frosted = true,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final decoration = BoxDecoration(
      color: (dark ? AppTheme.darkSurface : Colors.white)
          .withOpacity(frosted ? (dark ? 0.60 : 0.72) : (dark ? 0.88 : 0.94)),
      borderRadius: BorderRadius.circular(radius),
      border: border ??
          Border.all(
            color: dark
                ? Colors.white.withOpacity(0.12)
                : Colors.white.withOpacity(0.85),
            width: 1,
          ),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.45 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
    );

    if (!frosted) {
      // No BackdropFilter, no extra clip layer — a plain decorated Container,
      // same shape as the (known-good) floating nav bar. Anything fancier
      // here (Clip.antiAlias wrapper, BackdropFilter) has been observed to
      // break Android's platform-view stacking order above AppMapEmbed.
      return Container(margin: margin, padding: padding, alignment: alignment, decoration: decoration, child: child);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        margin: margin,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            alignment: alignment,
            padding: padding,
            decoration: decoration,
            child: child,
          ),
        ),
      ),
    );
  }
}
