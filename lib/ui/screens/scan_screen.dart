import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/qr_link.dart';

/// Scan tab. Three ways to open a card from a code:
///  1. point the camera at a QR,
///  2. pick a screenshot / saved QR image from the gallery,
///  3. type or paste a DIGIPIN or DigiRoutes link.
class ScanScreen extends StatefulWidget {
  /// When true the screen is pushed as a picker: it returns the scanned
  /// DIGIPIN to the caller (`context.pop(pin)`) instead of opening the card.
  final bool pickMode;
  const ScanScreen({super.key, this.pickMode = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: false,
  );
  final _picker = ImagePicker();

  bool _tabActive = false;
  bool _opening = false;
  DateTime _lastWarning = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The shell keeps every tab alive, so only run the camera while this tab
    // is the visible one.
    final active = TickerMode.valuesOf(context).enabled;
    if (active != _tabActive) {
      _tabActive = active;
      _syncCamera();
    }
  }

  Future<void> _syncCamera() async {
    try {
      if (_tabActive) {
        await _controller.start();
      } else {
        await _controller.stop();
      }
    } catch (_) {
      // Permission / camera errors are rendered by MobileScanner.errorBuilder.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _warn(String message) {
    // Avoid spamming while the camera keeps seeing the same wrong code.
    if (DateTime.now().difference(_lastWarning) < const Duration(seconds: 3)) {
      return;
    }
    _lastWarning = DateTime.now();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
      ));
  }

  Future<void> _open(String pin) async {
    if (_opening) return;
    _opening = true;
    HapticFeedback.mediumImpact();
    if (widget.pickMode) {
      if (mounted) context.pop(pin);
      return;
    }
    await context.push('/card/$pin');
    _opening = false;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_opening) return;
    var sawCode = false;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      sawCode = true;
      final pin = digipinFromScan(raw);
      if (pin != null) {
        _open(pin);
        return;
      }
    }
    if (sawCode) _warn("That QR code isn't a DigiRoutes location.");
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    try {
      final capture = await _controller.analyzeImage(
        file.path,
        formats: const [BarcodeFormat.qrCode],
      );
      final codes = capture?.barcodes ?? const <Barcode>[];
      if (codes.isEmpty) {
        _warn('No QR code found in that image.');
        return;
      }
      for (final b in codes) {
        final pin = b.rawValue == null ? null : digipinFromScan(b.rawValue!);
        if (pin != null) {
          await _open(pin);
          return;
        }
      }
      _warn("That QR code isn't a DigiRoutes location.");
    } catch (_) {
      _warn('Could not read that image. Try another one.');
    }
  }

  Future<void> _enterCode() async {
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _EnterCodeSheet(),
    );
    if (pin != null) await _open(pin);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_tabActive)
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              fit: BoxFit.cover,
              errorBuilder: (context, error, _) => _CameraError(error: error),
              placeholderBuilder: (_, __) => const ColoredBox(color: Colors.black),
            )
          else
            const ColoredBox(color: Colors.black),

          // Dim everything except the scan window.
          const IgnorePointer(child: _ScanOverlay()),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  Text(widget.pickMode ? 'Scan a point' : 'Scan a DigiRoutes QR',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'Point the camera at the code, or pick a saved QR image.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13.5),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
            ),
          ),

          if (widget.pickMode)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
            ),

          // Actions (kept above the floating nav bar)
          Positioned(
            left: 0,
            right: 0,
            bottom: (widget.pickMode ? 36 : 112) + bottomInset,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder<MobileScannerState>(
                  valueListenable: _controller,
                  builder: (_, state, __) {
                    final on = state.torchState == TorchState.on;
                    return _RoundAction(
                      icon: on ? LucideIcons.zapOff : LucideIcons.zap,
                      label: on ? 'Light off' : 'Light',
                      highlighted: on,
                      onTap: state.torchState == TorchState.unavailable
                          ? null
                          : () => _controller.toggleTorch(),
                    );
                  },
                ),
                const SizedBox(width: 22),
                _RoundAction(
                  icon: LucideIcons.image,
                  label: 'From gallery',
                  onTap: _pickFromGallery,
                  primary: true,
                ),
                const SizedBox(width: 22),
                _RoundAction(
                  icon: LucideIcons.keyboard,
                  label: 'Type code',
                  onTap: _enterCode,
                ),
              ],
            ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.3),
          ),
        ],
      ),
    );
  }
}

// ─── Scan window overlay ──────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const side = 260.0;
      final rect = Rect.fromCenter(
        center: Offset(c.maxWidth / 2, c.maxHeight * 0.42),
        width: side,
        height: side,
      );
      return Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _OverlayPainter(rect)),
          Positioned.fromRect(
            rect: rect,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // sweeping scan line
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Colors.transparent,
                          AppTheme.orange,
                          Colors.transparent,
                        ]),
                        boxShadow: const [
                          BoxShadow(color: AppTheme.orangeGlow, blurRadius: 12),
                        ],
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                            begin: 8,
                            end: side - 12,
                            duration: 1800.ms,
                            curve: Curves.easeInOut),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect window;
  _OverlayPainter(this.window);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(window, const Radius.circular(24));

    final dim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.55));

    // corner brackets
    final p = Paint()
      ..color = AppTheme.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const len = 34.0, r = 24.0;
    for (final corner in [
      [window.topLeft, 1.0, 1.0],
      [window.topRight, -1.0, 1.0],
      [window.bottomLeft, 1.0, -1.0],
      [window.bottomRight, -1.0, -1.0],
    ]) {
      final o = corner[0] as Offset;
      final dx = corner[1] as double, dy = corner[2] as double;
      final path = Path()
        ..moveTo(o.dx + dx * len, o.dy)
        ..lineTo(o.dx + dx * r, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + dy * r)
        ..lineTo(o.dx, o.dy + dy * len);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.window != window;
}

// ─── Bits ─────────────────────────────────────────────────────────────────────

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool highlighted;
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = primary ? 68.0 : 54.0;
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: primary || highlighted
                    ? AppTheme.accentGradient
                    : null,
                color: primary || highlighted
                    ? null
                    : Colors.white.withValues(alpha: 0.16),
                border: primary
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.3)),
                boxShadow: primary
                    ? const [
                        BoxShadow(
                            color: AppTheme.orangeGlow,
                            blurRadius: 20,
                            offset: Offset(0, 6))
                      ]
                    : null,
              ),
              child: Icon(icon,
                  color: Colors.white, size: primary ? 28 : 22),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final MobileScannerException error;
  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.cameraOff, color: Colors.white70, size: 40),
              const SizedBox(height: 14),
              Text(
                denied
                    ? 'Camera access is off'
                    : "Couldn't start the camera",
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                denied
                    ? 'Allow camera access to scan — or use "From gallery" / "Type code" below.'
                    : 'You can still use "From gallery" or "Type code" below.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white70, height: 1.4),
              ),
              if (denied) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: Geolocator.openAppSettings,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54)),
                  child: const Text('Open settings'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EnterCodeSheet extends StatefulWidget {
  const _EnterCodeSheet();

  @override
  State<_EnterCodeSheet> createState() => _EnterCodeSheetState();
}

class _EnterCodeSheetState extends State<_EnterCodeSheet> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = digipinFromScan(_ctrl.text);
    if (pin == null) {
      setState(() => _error = 'Enter a valid DIGIPIN or DigiRoutes link.');
      return;
    }
    Navigator.pop(context, pin);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _ctrl.text = data!.text!.trim();
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Open a location',
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Type a DIGIPIN (like 39J-49L-L8T4) or paste a DigiRoutes link.',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppTheme.textSecColor(context))),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              labelText: 'DIGIPIN or link',
              errorText: _error,
              prefixIcon: const Icon(LucideIcons.hash, size: 20),
              suffixIcon: IconButton(
                tooltip: 'Paste',
                icon: const Icon(LucideIcons.clipboardPaste, size: 20),
                onPressed: _paste,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Open'),
            ),
          ),
        ],
      ),
    );
  }
}
