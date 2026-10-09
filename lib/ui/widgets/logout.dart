import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/providers.dart';

/// Asks for confirmation, then logs out and returns to the login screen.
Future<void> confirmAndLogout(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.logOut,
            color: AppTheme.danger, size: 28),
      ),
      title: const Text('Log out?'),
      content: const Text(
          "You'll need to sign in again to see and manage your cards.",
          textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Stay signed in', style: GoogleFonts.outfit()),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
          child: Text('Log out', style: GoogleFonts.outfit()),
        ),
      ],
    ),
  );
  if (ok != true) return;
  await ref.read(authProvider.notifier).logout();
  ref.invalidate(cardsProvider);
  if (context.mounted) context.go('/login');
}
