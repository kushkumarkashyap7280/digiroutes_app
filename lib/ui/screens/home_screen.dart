import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/digipin.dart';
import '../../logic/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  String? _currentDigipin;
  bool _locating = false;
  bool _showDigipinCard = false;
  Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text('DigiRoutes',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
          ],
        ),
        actions: [
          // Dashboard
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
            onPressed: () => context.go('/dashboard'),
            tooltip: 'My Cards',
          ),
          // Overflow menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: AppTheme.darkSurface,
            onSelected: (v) async {
              if (v == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(children: [
                  const Icon(Icons.person_outline,
                      size: 18, color: AppTheme.darkTextSec),
                  const SizedBox(width: 10),
                  Text(auth.user?.name ?? 'Profile',
                      style: GoogleFonts.outfit(color: AppTheme.darkText)),
                ]),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  const Icon(Icons.logout,
                      size: 18, color: AppTheme.danger),
                  const SizedBox(width: 10),
                  Text('Logout',
                      style: GoogleFonts.outfit(color: AppTheme.danger)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.5937, 78.9629), // India centre
              zoom: 5.0,
            ),
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _markers,
            style: _darkMapStyle,
          ),

          // DIGIPIN result card (bottom sheet style)
          if (_showDigipinCard && _currentDigipin != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _DiginpinCard(
                digipin: _currentDigipin!,
                onCopy: () => _copyDigipin(),
                onShare: () => _shareDigipin(),
                onSaveCard: () => context.go('/create'),
                onClose: () => setState(() => _showDigipinCard = false),
              ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic).fadeIn(),
            ),

          // FAB — Get My Location
          Positioned(
            bottom: 32,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Create card FAB
                FloatingActionButton.small(
                  heroTag: 'create',
                  onPressed: () => context.go('/create'),
                  backgroundColor: AppTheme.darkSurface,
                  child: const Icon(Icons.add, color: AppTheme.orange),
                ),
                const SizedBox(height: 12),
                // Location FAB
                FloatingActionButton.extended(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getLocation() async {
    setState(() { _locating = true; _showDigipinCard = false; });

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

      final latlng = LatLng(lat, lon);

      setState(() {
        _currentDigipin  = digipin;
        _showDigipinCard = true;
        _markers = {
          Marker(
            markerId: const MarkerId('current'),
            position: latlng,
            infoWindow: InfoWindow(title: digipin),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
          ),
        };
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latlng, 17));
    } finally {
      setState(() => _locating = false);
    }
  }

  void _copyDigipin() {
    if (_currentDigipin == null) return;
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

// ─── DIGIPIN Result Card ──────────────────────────────────────────────────────

class _DiginpinCard extends StatelessWidget {
  final String digipin;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onSaveCard;
  final VoidCallback onClose;

  const _DiginpinCard({
    required this.digipin,
    required this.onCopy,
    required this.onShare,
    required this.onSaveCard,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.orangeGlow, width: 1),
        boxShadow: [
          BoxShadow(color: AppTheme.orangeGlow, blurRadius: 32),
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Your DIGIPIN',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.darkTextSec,
                    fontWeight: FontWeight.w500,
                  )),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close,
                    color: AppTheme.darkMuted, size: 18),
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
              style: GoogleFonts.outfit(
                  fontSize: 12, color: AppTheme.darkMuted)),
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
        ],
      ),
    );
  }
}

// Dark Google Maps style (minimal/dark)
const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1a1a1a"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a1a1a"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#303030"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3d3d3d"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#111111"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]
''';
