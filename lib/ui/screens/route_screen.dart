import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/location.dart';
import '../../core/routing_service.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/geo.dart';
import '../widgets/point_picker_sheet.dart';

/// "Where do you want to go?" — pick a start and an end (current location,
/// saved card, DIGIPIN, coordinates, QR or place name) and see the road route
/// plus the straight-line distance.
class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final _map = MapController();

  GeoPlace? _from;
  GeoPlace? _to;
  RouteMode _mode = RouteMode.drive;

  RouteResult? _route;
  bool _loading = false;
  String? _error;
  int _requestId = 0; // ignore out-of-date responses

  @override
  void initState() {
    super.initState();
    _prefillCurrentLocation();
  }

  /// Start from where the user is, when that's available without fuss.
  Future<void> _prefillCurrentLocation() async {
    try {
      final p = await currentLocation();
      if (!mounted || _from != null) return;
      setState(() => _from = GeoPlace('Current location', p));
      _refresh();
    } catch (_) {/* user can pick a start manually */}
  }

  double? get _straightMeters => (_from != null && _to != null)
      ? haversineMeters(_from!.point, _to!.point)
      : null;

  Future<void> _pick({required bool isFrom}) async {
    final place = await showPointPicker(context,
        title: isFrom ? 'Start from' : 'Go to');
    if (place == null || !mounted) return;
    setState(() => isFrom ? _from = place : _to = place);
    _refresh();
  }

  void _swap() {
    HapticFeedback.selectionClick();
    setState(() {
      final t = _from;
      _from = _to;
      _to = t;
    });
    _refresh();
  }

  Future<void> _refresh() async {
    _route = null;
    _error = null;
    if (_from == null || _to == null) {
      setState(() {});
      return;
    }
    _fitCamera();

    if (!RoutingService.isConfigured) {
      setState(() => _error =
          'Road routes are not set up in this build — showing straight-line distance only.');
      return;
    }

    final id = ++_requestId;
    setState(() => _loading = true);
    try {
      final r = await RoutingService.route(_from!.point, _to!.point, _mode);
      if (!mounted || id != _requestId) return;
      setState(() => _route = r);
      _fitCamera();
    } on RoutingException catch (e) {
      if (mounted && id == _requestId) setState(() => _error = e.message);
    } on Exception catch (e) {
      // NetworkException (offline / timeout) lands here with a readable message.
      if (mounted && id == _requestId) setState(() => _error = e.toString());
    } finally {
      if (mounted && id == _requestId) setState(() => _loading = false);
    }
  }

  void _fitCamera() {
    if (_from == null || _to == null) return;
    final pts = _route?.points.map((p) => LatLng(p.lat, p.lon)).toList() ??
        [LatLng(_from!.point.lat, _from!.point.lon), LatLng(_to!.point.lat, _to!.point.lon)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _map.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(pts),
          padding: const EdgeInsets.fromLTRB(48, 48, 48, 48),
          maxZoom: 17,
        ));
      } catch (_) {/* map not laid out yet */}
    });
  }

  Future<void> _openInGoogleMaps() async {
    if (_from == null || _to == null) return;
    final travel = switch (_mode) {
      RouteMode.drive => 'driving',
      RouteMode.bike => 'bicycling',
      RouteMode.walk => 'walking',
    };
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': '${_from!.point.lat},${_from!.point.lon}',
      'destination': '${_to!.point.lat},${_to!.point.lon}',
      'travelmode': travel,
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasBoth = _from != null && _to != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: Text('Where to?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          _PointsCard(
            from: _from,
            to: _to,
            onFrom: () => _pick(isFrom: true),
            onTo: () => _pick(isFrom: false),
            onSwap: hasBoth ? _swap : null,
          ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.1),

          // Map
          Expanded(
            child: Stack(
              children: [
                _buildMap(),
                if (_loading)
                  const Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(child: _Pill(text: 'Finding the best route…', busy: true))),
              ],
            ),
          ),

          // Summary
          if (hasBoth)
            _SummaryCard(
              mode: _mode,
              onMode: (m) {
                setState(() => _mode = m);
                _refresh();
              },
              route: _route,
              loading: _loading,
              error: _error,
              straightMeters: _straightMeters!,
              onNavigate: _openInGoogleMaps,
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Text(
                'Pick a start and a destination to see the distance and route.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: AppTheme.textSecColor(context), height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final from = _from == null ? null : LatLng(_from!.point.lat, _from!.point.lon);
    final to = _to == null ? null : LatLng(_to!.point.lat, _to!.point.lon);

    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: from ?? to ?? const LatLng(22.5, 79.0), // India
        initialZoom: (from ?? to) == null ? 4.2 : 13,
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.digiroutes_app',
        ),
        if (from != null && to != null)
          PolylineLayer(
            polylines: [
              if (_route != null)
                Polyline(
                  points: _route!.points.map((p) => LatLng(p.lat, p.lon)).toList(),
                  strokeWidth: 6,
                  color: AppTheme.orange,
                  borderStrokeWidth: 2,
                  borderColor: Colors.white,
                )
              else
                Polyline(
                  points: [from, to],
                  strokeWidth: 3,
                  color: AppTheme.orange.withValues(alpha: 0.7),
                  pattern: StrokePattern.dashed(segments: const [10, 8]),
                ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (from != null)
              Marker(
                point: from,
                width: 26,
                height: 26,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.orange, width: 5),
                  ),
                ),
              ),
            if (to != null)
              Marker(
                point: to,
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: const Icon(Icons.location_on_rounded,
                    color: AppTheme.danger, size: 44),
              ),
          ],
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap contributors',
              onTap: () => launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                  mode: LaunchMode.externalApplication),
            ),
            TextSourceAttribution(
              'openrouteservice.org by HeiGIT',
              onTap: () => launchUrl(Uri.parse('https://openrouteservice.org'),
                  mode: LaunchMode.externalApplication),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _PointsCard extends StatelessWidget {
  final GeoPlace? from;
  final GeoPlace? to;
  final VoidCallback onFrom;
  final VoidCallback onTo;
  final VoidCallback? onSwap;
  const _PointsCard({
    required this.from,
    required this.to,
    required this.onFrom,
    required this.onTo,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, Color color, String hint, GeoPlace? p, VoidCallback onTap) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  p?.label ?? hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15.5,
                    fontWeight: p == null ? FontWeight.w400 : FontWeight.w600,
                    color: p == null
                        ? AppTheme.mutedColor(context)
                        : AppTheme.textColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                row(LucideIcons.circleDot, AppTheme.orange, 'Choose start point',
                    from, onFrom),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                row(Icons.location_on_rounded, AppTheme.danger,
                    'Choose destination', to, onTo),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Swap',
            onPressed: onSwap,
            icon: const Icon(LucideIcons.arrowUpDown, size: 20),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final RouteMode mode;
  final ValueChanged<RouteMode> onMode;
  final RouteResult? route;
  final bool loading;
  final String? error;
  final double straightMeters;
  final VoidCallback onNavigate;
  const _SummaryCard({
    required this.mode,
    required this.onMode,
    required this.route,
    required this.loading,
    required this.error,
    required this.straightMeters,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final icons = {
      RouteMode.drive: LucideIcons.car,
      RouteMode.bike: LucideIcons.bike,
      RouteMode.walk: LucideIcons.footprints,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final m in RouteMode.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(icons[m], size: 16,
                          color: m == mode ? AppTheme.orange : null),
                      label: Text(m.label),
                      selected: m == mode,
                      showCheckmark: false,
                      selectedColor: AppTheme.orangeSubtle,
                      onSelected: (_) => onMode(m),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (route != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatDuration(route!.durationSeconds),
                      style: GoogleFonts.outfit(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.orange,
                          height: 1)),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('· ${formatDistance(route!.distanceMeters)} by road',
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor(context))),
                  ),
                ],
              )
            else if (loading)
              Text('Finding the best route…',
                  style: GoogleFonts.outfit(
                      fontSize: 16, color: AppTheme.textSecColor(context)))
            else
              Text(formatDistance(straightMeters),
                  style: GoogleFonts.outfit(
                      fontSize: 30, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(LucideIcons.moveRight,
                    size: 14, color: AppTheme.mutedColor(context)),
                const SizedBox(width: 6),
                Text('${formatDistance(straightMeters)} in a straight line',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: AppTheme.textSecColor(context))),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!,
                  style: GoogleFonts.outfit(
                      fontSize: 12.5, color: AppTheme.danger, height: 1.35)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.navigation_rounded, size: 20),
                label: const Text('Navigate in Google Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool busy;
  const _Pill({required this.text, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange)),
          if (busy) const SizedBox(width: 10),
          Text(text, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
