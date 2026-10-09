import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../logic/providers.dart';

/// Confirms with the user's password, then deletes the account on the server
/// (all cards, photos and the avatar go with it) and returns to the login screen.
Future<void> confirmAndDeleteAccount(BuildContext context, WidgetRef ref) async {
  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DeleteAccountDialog(),
  );
  if (deleted != true) return;
  ref.read(cardsProvider.notifier).reset();
  if (context.mounted) {
    context.go('/login');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Your account was deleted.', style: GoogleFonts.outfit())),
    );
  }
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _pw = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_pw.text.isEmpty) {
      setState(() => _error = 'Enter your password to continue.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).deleteAccount(_pw.text);
      if (mounted) Navigator.pop(context, true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.userX, color: AppTheme.danger, size: 28),
      ),
      title: const Text('Delete your account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This permanently deletes your profile, every address card, all '
              'photos and your profile picture. It cannot be undone.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  height: 1.4, color: AppTheme.textSecColor(context)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pw,
              obscureText: _obscure,
              enabled: !_busy,
              onSubmitted: (_) => _delete(),
              decoration: InputDecoration(
                labelText: 'Confirm with your password',
                errorText: _error,
                errorMaxLines: 2,
                prefixIcon: const Icon(LucideIcons.lock, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text('Cancel', style: GoogleFonts.outfit()),
        ),
        FilledButton(
          onPressed: _busy ? null : _delete,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Delete forever', style: GoogleFonts.outfit()),
        ),
      ],
    );
  }
}
