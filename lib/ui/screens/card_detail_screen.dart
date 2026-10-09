import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/card_categories.dart';
import '../../core/card_share.dart';
import '../../core/map_widgets.dart';
import '../../core/sound.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/address_card.dart';
import '../../data/repositories/cards_repository.dart';
import '../../logic/digipin.dart';
import '../../logic/providers.dart';
import '../widgets/qr_sheet.dart';

class CardDetailScreen extends ConsumerStatefulWidget {
  final String digipin;
  const CardDetailScreen({super.key, required this.digipin});

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  final _repo = CardsRepository();
  AddressCard? _card;
  DigipinCoords? _coords;
  bool _loading = true;
  String? _error;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    try {
      final card = await _repo.getCardByDigipin(widget.digipin);
      DigipinCoords? coords;
      try {
        coords = getLatLngFromDigiPin(widget.digipin);
      } catch (_) {}

      setState(() {
        _card = card;
        _coords = coords;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load card.';
        _loading = false;
      });
    }
  }

  bool get _isOwner {
    final user = ref.read(authProvider).user;
    return user != null && _card != null && _card!.ownerId == user.id;
  }

  Future<void> _toggleFavorite() async {
    final card = _card;
    if (card == null) return;
    AppSound.tap(ref);
    setState(() => _card = card.copyWith(isFavorite: !card.isFavorite));
    final ok = await ref.read(cardsProvider.notifier).toggleFavorite(card);
    if (!mounted) return;
    if (!ok) {
      setState(() => _card = card);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Could not update favorite.', style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.danger,
      ));
    }
  }

  Future<void> _edit() async {
    final card = _card;
    if (card == null) return;
    final updated = await context.push<AddressCard>('/edit', extra: card);
    if (updated != null && mounted) setState(() => _card = updated);
  }

  Future<void> _delete() async {
    final card = _card;
    if (card == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Card',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Delete "${card.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(cardsProvider.notifier).deleteCard(card.id);
      if (mounted) context.canPop() ? context.pop() : context.go('/dashboard');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete card.', style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          // Opened from a link there may be nothing to pop back to.
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          _card?.title ?? widget.digipin,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_isOwner)
            IconButton(
              icon: Icon(
                _card!.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: AppTheme.orange,
              ),
              onPressed: _toggleFavorite,
              tooltip: _card!.isFavorite ? 'Unfavorite' : 'Favorite',
            ),
          if (_card != null)
            IconButton(
              icon: const Icon(LucideIcons.qrCode, color: AppTheme.orange),
              onPressed: _showQr,
              tooltip: 'QR code',
            ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.orange),
            onPressed: _share,
            tooltip: 'Share',
          ),
          if (_isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) => v == 'edit' ? _edit() : _delete(),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: AppTheme.danger),
                    title: Text('Delete',
                        style: TextStyle(color: AppTheme.danger)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.orange))
          : _error != null
              ? _ErrorView(message: _error!)
              : _CardBody(
                  card: _card,
                  digipin: widget.digipin,
                  coords: _coords,
                  photoIndex: _photoIndex,
                  onPhotoTap: (i) => setState(() => _photoIndex = i),
                  onCopy: _copyDigipin,
                  onNavigate: _navigate,
                  onShare: _share,
                  onQr: _showQr,
                  onCall: () => _launch(Uri(scheme: 'tel', path: _card!.contactPhone)),
                  onWhatsApp: () => _launch(Uri.parse(
                      'https://wa.me/${_card!.whatsappNumber}?text=${Uri.encodeComponent('Hi, I am at ${_card!.title} (DIGIPIN ${_card!.digipin}).')}')),
                ),
    );
  }

  void _copyDigipin() {
    AppSound.tap(ref);
    Clipboard.setData(ClipboardData(text: widget.digipin));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('DIGIPIN copied!', style: GoogleFonts.outfit()),
      backgroundColor: AppTheme.success,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _share() async {
    final card = _card;
    if (card == null) {
      Share.share(
          'DIGIPIN: ${widget.digipin}\nhttps://digiroutes.vercel.app/card/${widget.digipin}');
      return;
    }
    AppSound.tap(ref);
    await shareCardRich(card);
  }

  void _showQr() {
    final card = _card;
    if (card != null) showCardQrSheet(context, card);
  }

  Future<void> _launch(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not open that app.', style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.danger,
      ));
    }
  }

  Future<void> _navigate() async {
    if (_coords == null) return;
    final uri = Uri.parse(
        'https://www.google.com/maps?q=${_coords!.latitude},${_coords!.longitude}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _CardBody extends StatelessWidget {
  final AddressCard? card;
  final String digipin;
  final DigipinCoords? coords;
  final int photoIndex;
  final ValueChanged<int> onPhotoTap;
  final VoidCallback onCopy;
  final VoidCallback onNavigate;
  final VoidCallback onShare;
  final VoidCallback onQr;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const _CardBody({
    required this.card,
    required this.digipin,
    required this.coords,
    required this.photoIndex,
    required this.onPhotoTap,
    required this.onCopy,
    required this.onNavigate,
    required this.onShare,
    required this.onQr,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final photos = card?.photoUrls ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo carousel ───────────────────────────────────────────
          if (photos.isNotEmpty) ...[
            SizedBox(
              height: 260,
              child: PageView.builder(
                itemCount: photos.length,
                onPageChanged: onPhotoTap,
                itemBuilder: (_, i) => CachedNetworkImage(
                  imageUrl: photos[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Container(
                    color: AppTheme.surface2Color(context),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.orange),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.surface2Color(context),
                    child: Icon(Icons.broken_image_outlined,
                        color: AppTheme.mutedColor(context), size: 48),
                  ),
                ),
              ),
            ).animate().fadeIn(),
            if (photos.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    photos.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: photoIndex == i ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: photoIndex == i
                            ? AppTheme.orange
                            : AppTheme.surface2Color(context),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ] else
            Container(
              height: 200,
              width: double.infinity,
              color: AppTheme.surfaceColor(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_rounded,
                      color: AppTheme.orange.withValues(alpha: 0.4), size: 56),
                  const SizedBox(height: 8),
                  Text('No entrance photo',
                      style: GoogleFonts.outfit(
                          color: AppTheme.mutedColor(context), fontSize: 14)),
                ],
              ),
            ).animate().fadeIn(),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── DIGIPIN chip ─────────────────────────────────────────
                GestureDetector(
                  onTap: onCopy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.orangeSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.orangeGlow),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.grid_on_rounded,
                            color: AppTheme.orange, size: 18),
                        const SizedBox(width: 8),
                        Text(digipin,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.orange,
                              letterSpacing: 2,
                            )),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy,
                            color: AppTheme.orange, size: 14),
                      ],
                    ),
                  ),
                )
                    .animate(delay: 100.ms)
                    .fadeIn()
                    .scale(begin: const Offset(0.9, 0.9)),

                const SizedBox(height: 6),
                Text('Tap to copy · ~4m precision',
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: AppTheme.mutedColor(context))),

                // ── Title & address ────────────────────────────────────────
                if (card?.title != null) ...[
                  const SizedBox(height: 20),
                  Text(card!.title,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor(context),
                      )).animate(delay: 150.ms).fadeIn(),
                ],
                if (card?.humanAddress != null &&
                    card!.humanAddress.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_city_outlined,
                          color: AppTheme.mutedColor(context), size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(card!.humanAddress,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textSecColor(context),
                            )),
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(),
                ],

                if (CardCategories.byId(card?.category ?? '') != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: Icon(CardCategories.byId(card!.category)!.icon,
                          size: 16, color: AppTheme.orange),
                      label: Text(CardCategories.byId(card!.category)!.label),
                      backgroundColor: AppTheme.orangeSubtle,
                      side: BorderSide.none,
                    ),
                  ).animate(delay: 220.ms).fadeIn(),
                ],

                if ((card?.deliveryNote ?? '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.orangeSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.orangeGlow),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_outlined,
                            color: AppTheme.orange, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(card!.deliveryNote,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                height: 1.4,
                                color: AppTheme.textColor(context),
                              )),
                        ),
                      ],
                    ),
                  ).animate(delay: 240.ms).fadeIn().slideY(begin: 0.1),
                ],

                const SizedBox(height: 24),

                // ── Map ────────────────────────────────────────────────────
                if (coords != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      child: AppMapEmbed(
                        lat: coords!.latitude,
                        lon: coords!.longitude,
                      ),
                    ),
                  ).animate(delay: 250.ms).fadeIn(),
                  const SizedBox(height: 10),
                  Text(
                    '${coords!.latitude.toStringAsFixed(6)}, ${coords!.longitude.toStringAsFixed(6)}',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppTheme.mutedColor(context)),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Action buttons ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation_rounded, size: 20),
                    label: Text('Navigate with Google Maps',
                        style: GoogleFonts.outfit(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ).animate(delay: 300.ms).fadeIn(),

                if ((card?.contactPhone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCall,
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: Text('Call',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onWhatsApp,
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: Text('WhatsApp',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF16A34A),
                            side: const BorderSide(color: Color(0xFF16A34A)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 330.ms).fadeIn(),
                ],

                const SizedBox(height: 12),

                Row(
                  children: [
                    if (card != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onQr,
                          icon: const Icon(LucideIcons.qrCode, size: 18),
                          label: Text('QR code',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: Text('Share',
                            style:
                                GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 350.ms).fadeIn(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message,
          style: GoogleFonts.outfit(color: AppTheme.danger, fontSize: 16)),
    );
  }
}
