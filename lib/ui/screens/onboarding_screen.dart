import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/backdrop.dart';

class _Slide {
  final String tag;
  final String title;
  final String subtitle;
  final Widget Function() illustration;
  const _Slide(this.tag, this.title, this.subtitle, this.illustration);
}

final _slides = <_Slide>[
  _Slide(
    'DIGIPIN',
    'Every doorstep,\none precise code',
    "India Post's 10-character DIGIPIN pinpoints any spot within ~4 metres — far sharper than a text address.",
    () => const _GridIllustration(),
  ),
  _Slide(
    'ADDRESS CARDS',
    'Save your exact\nentrance',
    'Capture GPS, add entrance photos and a label. Your gate, your door — saved and ready to share.',
    () => const _CardsIllustration(),
  ),
  _Slide(
    'SHARE & NAVIGATE',
    'Send a link,\nskip the guesswork',
    'Anyone gets the map, the photo and a one-tap Navigate button. No more "which gate?" calls.',
    () => const _RouteIllustration(),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  double get _pageValue =>
      _controller.hasClients && _controller.position.haveDimensions
          ? _controller.page ?? 0.0
          : 0.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_isLast) {
      context.go('/login');
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppTheme.textColor(context);

    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('DigiRoutes',
                        style: GoogleFonts.outfit(
                            color: text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _isLast ? 0 : 1,
                      child: TextButton(
                        onPressed: _isLast ? null : () => context.go('/login'),
                        child: Text('Skip',
                            style: GoogleFonts.outfit(
                                color: AppTheme.textSecColor(context),
                                fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3),

              // ── Slides ───────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _page = i);
                  },
                  itemBuilder: (context, i) => AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) =>
                        _SlideView(slide: _slides[i], offset: _pageValue - i),
                  ),
                ),
              ),

              // ── Dots + CTA ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final p = _pageValue;
                        return Row(
                          children: List.generate(_slides.length, (i) {
                            final t = (1 - (p - i).abs()).clamp(0.0, 1.0);
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 8 + 22 * t,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                    AppTheme.mutedColor(context)
                                        .withValues(alpha: 0.3),
                                    AppTheme.orange,
                                    t),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const Spacer(),
                    _CtaButton(isLast: _isLast, onTap: _next),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.4),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  final double offset;
  const _SlideView({required this.slide, required this.offset});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final t = offset.abs().clamp(0.0, 1.0);
    double dx(double f) => -offset * w * f;

    return Opacity(
      opacity: (1 - t * 1.3).clamp(0.0, 1.0),
      child: Column(
        children: [
          // Illustration drifts + shrinks as it leaves.
          Expanded(
            child: Transform.translate(
              offset: Offset(dx(0.3), 0),
              child: Transform.scale(
                scale: 1 - 0.12 * t,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                        width: 320, height: 320, child: slide.illustration()),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: Offset(dx(0.35), 0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.orangeSubtle,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(slide.tag,
                        style: GoogleFonts.outfit(
                            color: AppTheme.orange,
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 14),
                Transform.translate(
                  offset: Offset(dx(0.2), 0),
                  child: Text(
                    slide.title,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor(context),
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Transform.translate(
                  offset: Offset(dx(0.1), 0),
                  child: Text(
                    slide.subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      height: 1.5,
                      color: AppTheme.textSecColor(context),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final bool isLast;
  final VoidCallback onTap;
  const _CtaButton({required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: isLast ? 26 : 18),
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
                color: AppTheme.orangeGlow,
                blurRadius: 24,
                offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: isLast
                  ? Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text('Get Started',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    )
                  : const SizedBox.shrink(),
            ),
            const Icon(LucideIcons.arrowRight,
                    color: Colors.white, size: 22)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(
                    begin: 0,
                    end: 4,
                    duration: 700.ms,
                    curve: Curves.easeInOut),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Illustration 1 — DIGIPIN grid with a pin dropping into one cell
// ═════════════════════════════════════════════════════════════════════════

class _GridIllustration extends StatelessWidget {
  const _GridIllustration();

  static const _n = 5;
  static const _target = 12; // centre cell

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceColor(context);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Board
        Container(
          width: 280,
          height: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.orange.withValues(alpha: 0.14),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: GridView.count(
            crossAxisCount: _n,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(_n * _n, (i) {
              final isTarget = i == _target;
              final row = i ~/ _n, col = i % _n;
              final d = (row - 2).abs() + (col - 2).abs();
              return Container(
                decoration: BoxDecoration(
                  color: isTarget
                      ? null
                      : AppTheme.orange.withValues(alpha: d <= 1 ? 0.14 : 0.07),
                  gradient: isTarget ? AppTheme.accentGradient : null,
                  borderRadius: BorderRadius.circular(12),
                ),
              )
                  .animate(delay: Duration(milliseconds: 40 * d + 150))
                  .fadeIn(duration: 350.ms)
                  .scale(
                      begin: const Offset(0.4, 0.4),
                      duration: 400.ms,
                      curve: Curves.easeOutBack);
            }),
          ),
        ).animate().fadeIn(duration: 300.ms),

        // Ripples under the pin
        for (var i = 0; i < 2; i++)
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.orange.withValues(alpha: 0.5), width: 2),
            ),
          )
              .animate(
                delay: Duration(milliseconds: 1100 + 700 * i),
                onPlay: (c) => c.repeat(),
              )
              .scale(
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(2.3, 2.3),
                  duration: 1800.ms,
                  curve: Curves.easeOut)
              .fadeOut(duration: 1800.ms),

        // Pin drops in
        Transform.translate(
          offset: const Offset(0, -22),
          child: const Icon(Icons.location_on_rounded,
                  size: 76,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        color: Color(0x55000000),
                        blurRadius: 14,
                        offset: Offset(0, 6)),
                  ])
              .animate(delay: 700.ms)
              .moveY(
                  begin: -180,
                  end: 0,
                  duration: 700.ms,
                  curve: Curves.bounceOut)
              .fadeIn(duration: 200.ms),
        ),

        // Floating chips
        Positioned(
          right: -6,
          bottom: 8,
          child: const _Chip(
            icon: LucideIcons.hash,
            text: '4FK-5L2-C9M8',
          )
              .animate(delay: 1300.ms)
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.4, curve: Curves.easeOutCubic),
        ),
        Positioned(
          left: -4,
          top: 6,
          child: const _Chip(icon: LucideIcons.crosshair, text: '~4 m')
              .animate(delay: 1500.ms)
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.4, curve: Curves.easeOutCubic),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Illustration 2 — stack of address cards with favourite + photo badge
// ═════════════════════════════════════════════════════════════════════════

class _CardsIllustration extends StatelessWidget {
  const _CardsIllustration();

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceColor(context);

    Widget back(double angle, double dy, double alpha, int ms) =>
        Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            child: Container(
              width: 230,
              height: 270,
              decoration: BoxDecoration(
                color: surface.withValues(alpha: alpha),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.borderColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: ms))
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.25, curve: Curves.easeOutCubic);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        back(-0.14, 6, 0.6, 100),
        back(0.10, 2, 0.8, 250),

        // Front card
        Container(
          width: 232,
          height: 272,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.orange.withValues(alpha: 0.18),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Photo" area
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(27)),
                child: SizedBox(
                  height: 138,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                          decoration:
                              BoxDecoration(gradient: AppTheme.accentGradient)),
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -20,
                        bottom: -40,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(Icons.home_rounded,
                            size: 62, color: Colors.white),
                      ),
                      // favourite star — pops every few seconds
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded,
                                  size: 18, color: Colors.white)
                              .animate(
                                delay: 1600.ms,
                                onPlay: (c) => c.repeat(period: 3200.ms),
                              )
                              .scale(
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.5, 1.5),
                                  duration: 250.ms,
                                  curve: Curves.easeOut)
                              .then()
                              .scale(
                                  begin: const Offset(1.5, 1.5),
                                  end: const Offset(1, 1),
                                  duration: 400.ms,
                                  curve: Curves.elasticOut),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Home · Main gate',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor(context),
                        )),
                    const SizedBox(height: 4),
                    Text('Near the blue letterbox',
                        style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            color: AppTheme.textSecColor(context))),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.orangeSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('4FK-5L2-C9M8',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.orange,
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate(delay: 400.ms)
            .fadeIn(duration: 450.ms)
            .slideY(begin: 0.3, curve: Curves.easeOutCubic),

        // Photo badge
        Positioned(
          right: -6,
          bottom: 22,
          child: const _Chip(
                  icon: LucideIcons.camera, text: 'Entrance photo')
              .animate(delay: 1100.ms)
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.4, curve: Curves.easeOutCubic),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Illustration 3 — animated route with a navigating arrow, share chip
// ═════════════════════════════════════════════════════════════════════════

class _RouteIllustration extends StatefulWidget {
  const _RouteIllustration();

  @override
  State<_RouteIllustration> createState() => _RouteIllustrationState();
}

class _RouteIllustrationState extends State<_RouteIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceColor(context);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Map-ish tile
        Container(
          width: 290,
          height: 290,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.orange.withValues(alpha: 0.14),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),

        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: SizedBox(
            width: 290,
            height: 290,
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => CustomPaint(
                painter: _RoutePainter(
                  t: _c.value,
                  grid: AppTheme.mutedColor(context).withValues(alpha: 0.15),
                  base: AppTheme.mutedColor(context).withValues(alpha: 0.45),
                  surface: surface,
                ),
              ),
            ),
          ),
        ).animate(delay: 150.ms).fadeIn(duration: 500.ms),

        Positioned(
          left: -8,
          top: 18,
          child: const _Chip(
                  icon: LucideIcons.share2,
                  text: 'digiroutes/card/4FK…')
              .animate(delay: 900.ms)
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.4, curve: Curves.easeOutCubic),
        ),
        Positioned(
          right: -6,
          bottom: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                    color: AppTheme.orangeGlow,
                    blurRadius: 18,
                    offset: Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.navigation_rounded,
                    size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text('Navigate',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          )
              .animate(delay: 1200.ms)
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.4, curve: Curves.easeOutCubic),
        ),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  final double t; // 0..1 loop
  final Color grid;
  final Color base;
  final Color surface;
  _RoutePainter({
    required this.t,
    required this.grid,
    required this.base,
    required this.surface,
  });

  Path _route(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(w * 0.17, h * 0.80)
      ..cubicTo(w * 0.17, h * 0.45, w * 0.55, h * 0.78, w * 0.58, h * 0.50)
      ..cubicTo(w * 0.60, h * 0.30, w * 0.84, h * 0.46, w * 0.80, h * 0.20);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // faint street grid
    final gp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6, y = size.height * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gp);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
    }

    final metric = _route(size).computeMetrics().first;
    final len = metric.length;

    // dashed base route
    final dash = Paint()
      ..color = base
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (double d = 0; d < len; d += 14) {
      canvas.drawPath(metric.extractPath(d, math.min(d + 7, len)), dash);
    }

    // progress: 0→1 over first 75% of the loop, hold, then fade out
    final prog = Curves.easeInOut.transform((t / 0.75).clamp(0.0, 1.0));
    final fade = t < 0.9 ? 1.0 : (1 - (t - 0.9) / 0.1);
    final reached = len * prog;

    final glow = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height),
        Offset(size.width, 0),
        [AppTheme.orange, AppTheme.orangeLight],
      )
      ..color = Colors.white.withValues(alpha: fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(metric.extractPath(0, reached), glow);

    // start dot
    final start = metric.getTangentForOffset(0)!.position;
    canvas.drawCircle(start, 9, Paint()..color = surface);
    canvas.drawCircle(
        start,
        9,
        Paint()
          ..color = AppTheme.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5);

    // destination pin + pulse
    final end = metric.getTangentForOffset(len)!.position;
    final pulse = (t * 2) % 1;
    canvas.drawCircle(
      end,
      10 + 26 * pulse,
      Paint()..color = AppTheme.orange.withValues(alpha: 0.28 * (1 - pulse)),
    );
    canvas.drawCircle(end, 11, Paint()..color = AppTheme.orange);
    canvas.drawCircle(end, 4.5, Paint()..color = Colors.white);

    // nav arrow riding the route
    final tan = metric.getTangentForOffset(reached);
    if (tan != null && prog < 1) {
      final heading = math.atan2(tan.vector.dy, tan.vector.dx);
      canvas.save();
      canvas.translate(tan.position.dx, tan.position.dy);
      canvas.rotate(heading + math.pi / 2); // arrow art points "up"
      canvas.drawCircle(
          Offset.zero,
          15,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(Offset.zero, 14, Paint()..color = Colors.white);
      final arrow = Path()
        ..moveTo(0, -8)
        ..lineTo(7, 8)
        ..lineTo(0, 4)
        ..lineTo(-7, 8)
        ..close();
      canvas.drawPath(arrow, Paint()..color = AppTheme.orange);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.t != t || old.grid != grid;
}

// ═════════════════════════════════════════════════════════════════════════

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.orange),
          const SizedBox(width: 7),
          Text(text,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              )),
        ],
      ),
    );
  }
}
