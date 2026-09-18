import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/map_widgets.dart';
import '../../core/sound.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/digipin.dart';
import '../../logic/providers.dart';

enum _CompassMode { gps, decode, encode }

class _CompassResult {
  final String digipin;
  final double lat;
  final double lon;
  final String source;
  const _CompassResult({
    required this.digipin,
    required this.lat,
    required this.lon,
    required this.source,
  });
}

/// Port of the DigiRoute website's "Compass" tool: convert & reverse
/// between GPS coordinates and DIGIPIN codes. Computed entirely on-device
/// (no network call needed) via the same digipin.dart port the rest of the
/// app uses.
class CompassScreen extends ConsumerStatefulWidget {
  const CompassScreen({super.key});

  @override
  ConsumerState<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends ConsumerState<CompassScreen> {
  _CompassMode _mode = _CompassMode.gps;
  final _pinCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  _CompassResult? _result;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () =>
              ref.read(scaffoldKeyProvider).currentState?.openDrawer(),
        ),
        title: Text('Compass',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Encode coordinates to DIGIPIN, decode a DIGIPIN back to '
                'lat/lon, or capture your live location — all offline.',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppTheme.textSecColor(context), height: 1.5)),
            const SizedBox(height: 16),

            // ── Mode selector ─────────────────────────────────────────
            _ModeSelector(
              mode: _mode,
              onChanged: (m) => setState(() {
                _mode = m;
                _error = null;
              }),
            ),
            const SizedBox(height: 16),

            // ── Input panel ───────────────────────────────────────────
            Container(
              decoration: AppTheme.cardDecoration(context),
              padding: const EdgeInsets.all(16),
              child: _buildModePanel(),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
                  ),
                  child: Text(_error!,
                      style: GoogleFonts.outfit(
                          color: AppTheme.danger, fontSize: 13)),
                ),
              ),

            if (_result != null) ...[
              const SizedBox(height: 20),
              _ResultCard(result: _result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModePanel() {
    switch (_mode) {
      case _CompassMode.gps:
        return _GpsPanel(loading: _loading, onCapture: _captureGps);
      case _CompassMode.decode:
        return _DecodePanel(
            controller: _pinCtrl, loading: _loading, onSubmit: _decodePin);
      case _CompassMode.encode:
        return _EncodePanel(
          latController: _latCtrl,
          lonController: _lonCtrl,
          loading: _loading,
          onSubmit: _encodeCoords,
          onPastePair: _pastePair,
        );
    }
  }

  Future<void> _captureGps() async {
    setState(() { _loading = true; _error = null; });
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission denied.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final pin = getDigiPin(pos.latitude, pos.longitude);
      AppSound.tap(ref);
      setState(() {
        _result = _CompassResult(
          digipin: pin,
          lat: pos.latitude,
          lon: pos.longitude,
          source: 'Live GPS Geolocation',
        );
      });
    } catch (e) {
      setState(() => _error = 'Failed to capture location.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _decodePin() {
    final pin = _pinCtrl.text.trim().toUpperCase();
    if (pin.length != 10) {
      setState(() => _error = 'Please enter a valid 10-character DIGIPIN code.');
      return;
    }
    try {
      final coords = getLatLngFromDigiPin(pin);
      AppSound.tap(ref);
      setState(() {
        _error = null;
        _result = _CompassResult(
          digipin: pin,
          lat: coords.latitude,
          lon: coords.longitude,
          source: 'Decoded from DIGIPIN',
        );
      });
    } catch (_) {
      setState(() => _error = 'Invalid DIGIPIN code.');
    }
  }

  void _encodeCoords() {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    if (lat == null || lon == null) {
      setState(() => _error = 'Please enter valid numeric latitude and longitude.');
      return;
    }
    try {
      final pin = getDigiPin(lat, lon);
      AppSound.tap(ref);
      setState(() {
        _error = null;
        _result = _CompassResult(
          digipin: pin,
          lat: lat,
          lon: lon,
          source: 'Encoded from Coordinates',
        );
      });
    } catch (_) {
      setState(() => _error = 'Coordinates are out of DIGIPIN range.');
    }
  }

  Future<void> _pastePair() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    final parts = text.split(RegExp(r'[,\s/]+')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      setState(() {
        _latCtrl.text = parts[0];
        _lonCtrl.text = parts[1];
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Clipboard does not contain a valid coordinate pair.',
            style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.danger,
      ));
    }
  }
}

// ─── Mode selector ────────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  final _CompassMode mode;
  final ValueChanged<_CompassMode> onChanged;
  const _ModeSelector({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_CompassMode>(
      segments: const [
        ButtonSegment(
            value: _CompassMode.gps,
            icon: Icon(Icons.my_location_rounded, size: 16),
            label: Text('Live GPS')),
        ButtonSegment(
            value: _CompassMode.decode,
            icon: Icon(Icons.explore_outlined, size: 16),
            label: Text('Decode PIN')),
        ButtonSegment(
            value: _CompassMode.encode,
            icon: Icon(Icons.public, size: 16),
            label: Text('Coordinates')),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        textStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Mode 1: Live GPS ─────────────────────────────────────────────────────────

class _GpsPanel extends StatelessWidget {
  final bool loading;
  final VoidCallback onCapture;
  const _GpsPanel({required this.loading, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
              color: AppTheme.orangeSubtle, shape: BoxShape.circle),
          child: const Icon(Icons.location_on_rounded,
              color: AppTheme.orange, size: 24),
        ),
        const SizedBox(height: 12),
        Text('Capture My Location',
            style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor(context))),
        const SizedBox(height: 6),
        Text(
          'Get your exact GPS coordinates and compute your India Post DIGIPIN (~4m accuracy).',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.mutedColor(context), height: 1.5),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onCapture,
            icon: loading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.my_location_rounded, size: 16),
            label: Text(loading ? 'Capturing GPS...' : 'Get My DIGIPIN Now',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ─── Mode 2: Decode PIN ───────────────────────────────────────────────────────

class _DecodePanel extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;
  const _DecodePanel({required this.controller, required this.loading, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter 10-Character DIGIPIN Code',
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textColor(context))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: 10,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.robotoMono(
              color: AppTheme.orange, fontWeight: FontWeight.w700, letterSpacing: 2),
          decoration: const InputDecoration(
              hintText: 'e.g. 4T396F42L7', counterText: ''),
        ),
        const SizedBox(height: 4),
        Text('Allowed characters: 2-9, C, F, J, K, L, M, P, T (case-insensitive).',
            style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.mutedColor(context))),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onSubmit,
            icon: const Icon(Icons.navigation_rounded, size: 16),
            label: Text('Decode & View Map',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ─── Mode 3: Encode Coordinates ───────────────────────────────────────────────

class _EncodePanel extends StatelessWidget {
  final TextEditingController latController;
  final TextEditingController lonController;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onPastePair;

  const _EncodePanel({
    required this.latController,
    required this.lonController,
    required this.loading,
    required this.onSubmit,
    required this.onPastePair,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: latController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                style: GoogleFonts.robotoMono(color: AppTheme.textColor(context)),
                decoration: const InputDecoration(
                    labelText: 'Latitude', hintText: '28.613939'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: lonController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                style: GoogleFonts.robotoMono(color: AppTheme.textColor(context)),
                decoration: const InputDecoration(
                    labelText: 'Longitude', hintText: '77.209021'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text('Or paste a coordinate pair, e.g. "28.6139, 77.2090".',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.mutedColor(context))),
            ),
            TextButton(
              onPressed: onPastePair,
              child: Text('Paste Pair', style: GoogleFonts.outfit(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onSubmit,
            icon: const Icon(Icons.public, size: 16),
            label: Text('Generate DIGIPIN',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ─── Result card ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final _CompassResult result;
  const _ResultCard({required this.result});

  String get _mapLink => 'https://www.google.com/maps?q=${result.lat},${result.lon}';
  String get _shareLink => '${AppConstants.cardShareBase}/${result.digipin}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.orangeGlow),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppTheme.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(result.source,
                    style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.mutedColor(context), fontWeight: FontWeight.w600)),
              ),
              Text('~4m Precision',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.orange, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'DIGIPIN CODE',
                  value: result.digipin,
                  onCopy: () => _copy(context, result.digipin, 'DIGIPIN'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'COORDINATES',
                  value: '${result.lat.toStringAsFixed(6)}, ${result.lon.toStringAsFixed(6)}',
                  onCopy: () => _copy(context,
                      '${result.lat.toStringAsFixed(6)}, ${result.lon.toStringAsFixed(6)}', 'Coordinates'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: AppMapEmbed(lat: result.lat, lon: result.lon),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse(_mapLink), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: Text('Navigate with Google Maps',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showQr(context),
                  icon: const Icon(Icons.qr_code_rounded, size: 16),
                  label: const Text('QR Code'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Share.share(
                      'DIGIPIN: ${result.digipin}\n$_shareLink',
                      subject: 'DigiRoute Location'),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label copied!', style: GoogleFonts.outfit()),
      backgroundColor: AppTheme.success,
      duration: const Duration(seconds: 2),
    ));
  }

  void _showQr(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: QrImageView(data: _shareLink, size: 200),
              ),
              const SizedBox(height: 16),
              Text(result.digipin,
                  style: GoogleFonts.outfit(
                      color: AppTheme.orange, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close', style: GoogleFonts.outfit()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  const _InfoTile({required this.label, required this.value, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface2Color(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.mutedColor(context), fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.robotoMono(
                        fontSize: 12, color: AppTheme.textColor(context), fontWeight: FontWeight.w700)),
              ),
              GestureDetector(
                onTap: onCopy,
                child: const Icon(Icons.copy, size: 14, color: AppTheme.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
