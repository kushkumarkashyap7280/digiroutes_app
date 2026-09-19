import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../core/map_widgets.dart';
import '../../core/maps_share.dart';
import '../../core/sound.dart';
import '../../core/theme/app_theme.dart';
import '../../core/update_checker.dart';
import '../../core/widgets/glass.dart';
import '../../logic/digipin.dart';
import '../../logic/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _currentDigipin;
  bool _locating = false;
  bool _showDigipinCard = false;
  double _lat = AppConstants.defaultLat;
  double _lon = AppConstants.defaultLng;
  double _zoom = AppConstants.defaultZoom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybePromptUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          Positioned.fill(
            child: AppMapEmbed(
              key: ValueKey(
                  '${_lat.toStringAsFixed(5)},${_lon.toStringAsFixed(5)}'),
              lat: _lat,
              lon: _lon,
              zoom: _zoom,
            ),
          ),

          // Floating glass top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _TopBar(
                  onMenu: () =>
                      ref.read(scaffoldKeyProvider).currentState?.openDrawer(),
                  onAdd: () => context.push('/create'),
                ),
              ),
            ),
          ),

          // DIGIPIN result card (bottom sheet style)
          if (_showDigipinCard && _currentDigipin != null)
            Positioned(
              bottom: 170,
              left: 16,
              right: 16,
              child: _DiginpinCard(
                digipin: _currentDigipin!,
                lat: _lat,
                lon: _lon,
                onCopy: () => _copyDigipin(),
                onShare: () => _shareDigipin(),
                onShareMaps: () => shareLocationLink(
                    lat: _lat,
                    lon: _lon,
                    label: 'My DIGIPIN: $_currentDigipin'),
                onSaveCard: () => context.push('/create'),
                onClose: () => setState(() => _showDigipinCard = false),
              )
                  .animate()
                  .slideY(
                      begin: 1,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic)
                  .fadeIn(),
            ),

          // FAB — Get My Location
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'locate',
              onPressed: _locating ? null : _getLocation,
              backgroundColor: AppTheme.orange,
              icon: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.my_location_rounded,
                      color: Colors.white, size: 20),
              label: Text(
                _locating ? 'Locating...' : 'Get My DIGIPIN',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getLocation() async {
    setState(() {
      _locating = true;
      _showDigipinCard = false;
    });

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permission denied.',
                  style: GoogleFonts.outfit()),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final lat = pos.latitude;
      final lon = pos.longitude;
      String digipin;

      try {
        digipin = getDigiPin(lat, lon);
      } catch (_) {
        digipin = 'Out of range';
      }

      setState(() {
        _currentDigipin = digipin;
        _showDigipinCard = true;
        _lat = lat;
        _lon = lon;
        _zoom = AppConstants.detailZoom;
      });
    } finally {
      setState(() => _locating = false);
    }
  }

  void _copyDigipin() {
    if (_currentDigipin == null) return;
    AppSound.tap(ref);
    Clipboard.setData(ClipboardData(text: _currentDigipin!));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('DIGIPIN copied!', style: GoogleFonts.outfit()),
      backgroundColor: AppTheme.success,
      duration: const Duration(seconds: 2),
    ));
  }

  void _shareDigipin() {
    if (_currentDigipin == null) return;
    Share.share(
      'My location DIGIPIN: $_currentDigipin\n'
      'View on DigiRoutes: https://digiroutes.vercel.app/card/$_currentDigipin',
      subject: 'My DigiPin Location',
    );
  }
}

// ─── Floating glass top bar ────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onMenu;
  final VoidCallback onAdd;
  const _TopBar({required this.onMenu, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      radius: 20,
      frosted: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _GlassIconButton(icon: Icons.menu_rounded, onPressed: onMenu),
          const SizedBox(width: 10),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('DigiRoutes',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                )),
          ),
          _GlassIconButton(
            icon: Icons.add_rounded,
            onPressed: onAdd,
            tooltip: 'New Address Card',
            accent: true,
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool accent;
  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: accent ? AppTheme.orange : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(
              icon,
              size: 20,
              color: accent ? Colors.white : theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── DIGIPIN Result Card ──────────────────────────────────────────────────────

class _DiginpinCard extends StatelessWidget {
  final String digipin;
  final double lat;
  final double lon;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onShareMaps;
  final VoidCallback onSaveCard;
  final VoidCallback onClose;

  const _DiginpinCard({
    required this.digipin,
    required this.lat,
    required this.lon,
    required this.onCopy,
    required this.onShare,
    required this.onShareMaps,
    required this.onSaveCard,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      radius: 20,
      frosted: false,
      border: Border.all(color: AppTheme.orangeGlow, width: 1),
      boxShadow: [
        BoxShadow(color: AppTheme.orangeGlow, blurRadius: 32),
        BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8)),
      ],
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Your DIGIPIN',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: theme.hintColor,
                    fontWeight: FontWeight.w500,
                  )),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: theme.hintColor, size: 18),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            digipin,
            style: GoogleFonts.outfit(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppTheme.orange,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text('~4m precision · India Post DIGIPIN',
              style: GoogleFonts.outfit(fontSize: 12, color: theme.hintColor)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSaveCard,
                  icon: const Icon(Icons.bookmark_add, size: 16),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onShareMaps,
              icon: const Icon(Icons.map_outlined, size: 16),
              label: Text('Share Google Maps Link',
                  style: GoogleFonts.outfit(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                foregroundColor: AppTheme.orange,
                side: const BorderSide(color: AppTheme.orange),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
