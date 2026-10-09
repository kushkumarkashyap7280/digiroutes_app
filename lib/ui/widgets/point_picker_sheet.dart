import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/location.dart';
import '../../core/routing_service.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/digipin.dart';
import '../../logic/geo.dart';
import '../../logic/providers.dart';
import '../../logic/qr_link.dart';

/// Lets the user choose a start/end point. Returns a [GeoPlace] or null.
///
/// One search box understands a DIGIPIN, a DigiRoutes link, "lat, lon"
/// coordinates or a place name; below it: current location, QR scan (camera /
/// gallery) and the user's saved cards.
Future<GeoPlace?> showPointPicker(BuildContext context, {required String title}) {
  return showModalBottomSheet<GeoPlace>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
    builder: (_) => _PickerSheet(title: title),
  );
}

class _PickerSheet extends ConsumerStatefulWidget {
  final String title;
  const _PickerSheet({required this.title});

  @override
  ConsumerState<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends ConsumerState<_PickerSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  GeoPlace? _direct; // a DIGIPIN / coordinates the text resolves to
  List<GeoPlace> _results = const [];
  bool _searching = false;
  bool _locating = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final s = ref.read(cardsProvider);
    if (s.cards.isEmpty && !s.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(cardsProvider.notifier).loadCards());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  GeoPlace? _placeFromPin(String pin, {String? label}) {
    try {
      final c = getLatLngFromDigiPin(pin);
      return GeoPlace(label ?? 'DIGIPIN $pin', GeoPoint(c.latitude, c.longitude));
    } catch (_) {
      return null;
    }
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    setState(() {
      _direct = null;
      _results = const [];
      _message = null;
    });
    final t = text.trim();
    if (t.isEmpty) return;

    final pin = digipinFromScan(t);
    final ll = parseLatLon(t);
    if (pin != null) {
      setState(() => _direct = _placeFromPin(pin));
      return;
    }
    if (ll != null) {
      setState(() => _direct = GeoPlace('Coordinates ${ll.toString()}', ll));
      return;
    }
    if (t.length < 3) return;
    if (!RoutingService.isConfigured) {
      setState(() => _message =
          'Place-name search needs the routing key. You can still use a DIGIPIN, coordinates, a QR or a saved card.');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _searching = true);
      try {
        final r = await RoutingService.search(t);
        if (!mounted) return;
        setState(() {
          _results = r;
          _message = r.isEmpty ? 'No places found. Try a more specific name.' : null;
        });
      } on RoutingException catch (e) {
        if (mounted) setState(() => _message = e.message);
      } catch (e) {
        if (mounted) setState(() => _message = e.toString());
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Future<void> _useCurrent() async {
    setState(() {
      _locating = true;
      _message = null;
    });
    try {
      final p = await currentLocation();
      if (mounted) Navigator.pop(context, GeoPlace('Current location', p));
    } on LocationException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _scan() async {
    final pin = await context.push<String>('/scan-pick');
    if (pin == null || !mounted) return;
    final place = _placeFromPin(pin);
    if (place != null) Navigator.pop(context, place);
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardsProvider).cards;
    final inset = MediaQuery.of(context).viewInsets.bottom;

    Widget tile(IconData icon, String title, String sub, VoidCallback? onTap,
        {Widget? trailing}) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: AppTheme.orangeSubtle, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppTheme.orange, size: 20),
        ),
        title: Text(title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
                fontSize: 12.5, color: AppTheme.textSecColor(context))),
        trailing: trailing,
        onTap: onTap,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + inset),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(widget.title,
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Place, DIGIPIN, coordinates or link',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : null,
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_message!,
                  style: GoogleFonts.outfit(fontSize: 12.5, color: AppTheme.danger)),
            ),
          if (_direct != null)
            tile(LucideIcons.mapPin, _direct!.label, 'Use this point',
                () => Navigator.pop(context, _direct)),
          for (final p in _results)
            tile(LucideIcons.mapPin, p.label, p.point.toString(),
                () => Navigator.pop(context, p)),
          const SizedBox(height: 6),
          tile(
            LucideIcons.locateFixed,
            'Current location',
            'Use where you are right now',
            _locating ? null : _useCurrent,
            trailing: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : null,
          ),
          tile(LucideIcons.qrCode, 'Scan or pick a QR code',
              'Camera, or a QR image from your gallery', _scan),
          if (cards.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('SAVED CARDS',
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppTheme.mutedColor(context))),
            const SizedBox(height: 4),
            for (final c in cards)
              tile(
                LucideIcons.bookmark,
                c.title,
                c.digipin,
                () {
                  final p = _placeFromPin(c.digipin, label: c.title);
                  if (p != null) Navigator.pop(context, p);
                },
              ),
          ],
          if (RoutingService.isConfigured)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'Place search by openrouteservice.org (HeiGIT) · © OpenStreetMap contributors',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 11, color: AppTheme.mutedColor(context)),
              ),
            ),
        ],
      ),
    );
  }
}
