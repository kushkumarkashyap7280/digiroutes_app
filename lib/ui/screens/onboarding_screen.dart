import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class _OnboardSlide {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardSlide(this.icon, this.title, this.subtitle);
}

const _slides = [
  _OnboardSlide(
    Icons.grid_on_rounded,
    'What is DIGIPIN?',
    'India Post\'s 10-character code that pinpoints any location within\n~4 metres — far more precise than a text address.',
  ),
  _OnboardSlide(
    Icons.add_photo_alternate_rounded,
    'Create Address Cards',
    'Capture your GPS, auto-generate your DIGIPIN, add entrance photos\nand a label. Your exact doorstep, saved forever.',
  ),
  _OnboardSlide(
    Icons.share_rounded,
    'Share & Navigate',
    'Send a link. Recipients see the map, photo, and a one-tap\nNavigate button — no more guessing the right gate.',
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text('Skip',
                      style: GoogleFonts.outfit(
                          color: AppTheme.darkTextSec, fontSize: 15)),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (ctx, i) => _SlidePage(slide: _slides[i]),
              ),
            ),

            // Dots + navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: _page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? AppTheme.orange
                              : AppTheme.darkSurface2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Get Started
                  FilledButton(
                    onPressed: () {
                      if (_page < _slides.length - 1) {
                        _controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut);
                      } else {
                        context.go('/login');
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _page < _slides.length - 1 ? 'Next' : 'Get Started',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _OnboardSlide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.orangeGlow, blurRadius: 48, spreadRadius: 4)
              ],
            ),
            child: Icon(slide.icon, color: Colors.white, size: 60),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(),

          const SizedBox(height: 40),

          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
              letterSpacing: -0.5,
            ),
          ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: AppTheme.darkTextSec,
              height: 1.6,
            ),
          ).animate(delay: 250.ms).fadeIn(),
        ],
      ),
    );
  }
}
