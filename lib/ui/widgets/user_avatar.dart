import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user.dart';

/// Circular profile picture; falls back to gradient initials.
class UserAvatar extends StatelessWidget {
  final AppUser? user;
  final double size;
  final bool ring;
  const UserAvatar({super.key, required this.user, this.size = 48, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final url = user?.avatarUrl ?? '';
    final inner = ring ? size - 8 : size;

    final face = ClipOval(
      child: SizedBox(
        width: inner,
        height: inner,
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 250),
                placeholder: (_, __) => _Initials(user: user, size: inner),
                errorWidget: (_, __, ___) => _Initials(user: user, size: inner),
              )
            : _Initials(user: user, size: inner),
      ),
    );

    if (!ring) return face;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.accentGradient,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: face,
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final AppUser? user;
  final double size;
  const _Initials({required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.accentGradient),
      alignment: Alignment.center,
      child: Text(
        user?.initials ?? '?',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
