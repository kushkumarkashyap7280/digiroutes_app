import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/map_widgets.dart';
import '../../core/sound.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/cards_repository.dart';
import '../../logic/digipin.dart';
import '../../logic/providers.dart';

class CreateCardScreen extends ConsumerStatefulWidget {
  const CreateCardScreen({super.key});

  @override
  ConsumerState<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends ConsumerState<CreateCardScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _titleCtrl    = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _picker       = ImagePicker();
  final _cardsRepo    = CardsRepository();

  DigipinCoords? _pickedLocation;
  String? _generatedDigipin;
  List<File> _photos = [];
  bool _isLocating = false;
  bool _isSaving   = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text('New Address Card',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Step 1: Location ──────────────────────────────────────
              _StepHeader(number: '1', label: 'Pick Location'),
              const SizedBox(height: 12),

              // Map preview
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 220,
                  child: _pickedLocation != null
                      ? AppMapEmbed(
                          key: ValueKey(
                              '${_pickedLocation!.latitude.toStringAsFixed(5)},${_pickedLocation!.longitude.toStringAsFixed(5)}'),
                          lat: _pickedLocation!.latitude,
                          lon: _pickedLocation!.longitude,
                        )
                      : Container(
                          color: AppTheme.surface2Color(context),
                          alignment: Alignment.center,
                          child: Icon(Icons.location_searching_rounded,
                              color: AppTheme.mutedColor(context).withOpacity(0.6),
                              size: 40),
                        ),
                ),
              ).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLocating ? null : _useCurrentLocation,
                      icon: _isLocating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppTheme.orange))
                          : const Icon(Icons.my_location_rounded, size: 16),
                      label: Text(
                          _isLocating ? 'Locating...' : 'Use Current Location',
                          style: GoogleFonts.outfit(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_generatedDigipin != null)
                    Chip(
                      label: Text(_generatedDigipin!,
                          style: GoogleFonts.outfit(
                              color: AppTheme.orange,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                      backgroundColor: AppTheme.orangeSubtle,
                      side: const BorderSide(color: AppTheme.orangeGlow),
                    ),
                ],
              ).animate(delay: 150.ms).fadeIn(),

              if (_generatedDigipin == null && _pickedLocation == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Tap "Use Current Location" to set the pin.',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppTheme.mutedColor(context)),
                  ),
                ),

              const SizedBox(height: 28),

              // ── Step 2: Details ───────────────────────────────────────
              _StepHeader(number: '2', label: 'Card Details'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Card Title (e.g. Home, Office entrance)',
                  prefixIcon: Icon(Icons.label_outline, size: 20),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required.'
                    : null,
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 14),

              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Human address (optional, for display only)',
                  prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                ),
                maxLines: 2,
              ).animate(delay: 250.ms).fadeIn(),

              const SizedBox(height: 28),

              // ── Step 3: Photos ─────────────────────────────────────────
              _StepHeader(number: '3', label: 'Entrance Photos (max 2)'),
              const SizedBox(height: 12),

              Row(
                children: [
                  ..._photos.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                e.value,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _photos.removeAt(e.key)),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.danger,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (_photos.length < 2)
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.surface2Color(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.borderColor(context),
                              style: BorderStyle.solid),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined,
                            color: AppTheme.orange, size: 30),
                      ),
                    ),
                ],
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 32),

              // ── Error ──────────────────────────────────────────────────
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
                  ),
                  child: Text(_error!,
                      style: GoogleFonts.outfit(
                          color: AppTheme.danger, fontSize: 13)),
                ).animate().fadeIn(),

              // ── Save button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isSaving || _generatedDigipin == null)
                      ? null
                      : _saveCard,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    _generatedDigipin == null
                        ? 'Pick a location first'
                        : (_isSaving ? 'Saving...' : 'Save Card'),
                    style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ).animate(delay: 350.ms).fadeIn(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _pickedLocation = DigipinCoords(latitude: pos.latitude, longitude: pos.longitude);
        try {
          _generatedDigipin = getDigiPin(pos.latitude, pos.longitude);
        } catch (_) {
          _generatedDigipin = null;
        }
      });
    } finally {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _pickPhoto() async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppTheme.orange),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.orange),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result == null) return;
    final xFile = await _picker.pickImage(
      source: result,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (xFile == null) return;

    final file = File(xFile.path);
    const maxBytes = 2 * 1024 * 1024;
    if (await file.length() > maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Image is too large — please pick one under 2MB.',
              style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.danger,
        ));
      }
      return;
    }

    setState(() => _photos.add(file));
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    if (_generatedDigipin == null) return;

    setState(() { _isSaving = true; _error = null; });

    try {
      // Upload photos
      final photoUrls = <String>[];
      final photoIds  = <String>[];

      for (final photo in _photos) {
        final result = await _cardsRepo.uploadImage(photo);
        photoUrls.add(result.url);
        photoIds.add(result.publicId);
      }

      // Create card
      final card = await ref.read(cardsProvider.notifier).createCard(
        digipin:      _generatedDigipin!,
        title:        _titleCtrl.text.trim(),
        humanAddress: _addressCtrl.text.trim(),
        photoUrls:    photoUrls,
        photoIds:     photoIds,
      );

      if (card != null && mounted) {
        AppSound.tap(ref);
        context.pushReplacement('/card/${card.digipin}');
      } else {
        setState(() => _error = 'Failed to save card. Please try again.');
      }
    } catch (e) {
      setState(() => _error = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }
}

class _StepHeader extends StatelessWidget {
  final String number;
  final String label;
  const _StepHeader({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(number,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            )),
      ],
    );
  }
}
