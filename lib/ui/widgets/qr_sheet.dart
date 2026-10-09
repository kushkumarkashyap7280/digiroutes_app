import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/card_share.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/address_card.dart';

/// Bottom sheet that shows a scannable QR code for [card] with share/copy.
Future<void> showCardQrSheet(BuildContext context, AddressCard card) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _QrSheet(card: card),
  );
}

class _QrSheet extends StatefulWidget {
  final AddressCard card;
  const _QrSheet({required this.card});

  @override
  State<_QrSheet> createState() => _QrSheetState();
}

class _QrSheetState extends State<_QrSheet> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  Future<void> _shareImage() async {
    setState(() => _busy = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 4);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        await shareCardQr(widget.card, bytes.buffer.asUint8List());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(card.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Scan to open this location in DigiRoutes',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppTheme.textSecColor(context))),
            const SizedBox(height: 18),
            // White card with quiet zone: needed so the code scans reliably,
            // also in dark mode and when saved as an image.
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: card.shareUrl,
                      size: 230,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                      eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square, color: Colors.black),
                      dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Text(card.digipin,
                        style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: card.shareUrl));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text('Link copied', style: GoogleFonts.outfit())));
                    },
                    icon: const Icon(LucideIcons.copy, size: 16),
                    label: const Text('Copy link'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _shareImage,
                    icon: const Icon(LucideIcons.share2, size: 16),
                    label: Text(_busy ? 'Preparing…' : 'Share QR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
