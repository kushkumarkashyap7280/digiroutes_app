import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/backdrop.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cards_repository.dart';
import '../../logic/providers.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _picker = ImagePicker();
  final _cardsRepo = CardsRepository();
  late final TextEditingController _nameCtrl;
  bool _uploading = false;
  bool _savingName = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: ref.read(authProvider).user?.name ?? '');
    // Stats need the card list; load it if the Cards tab hasn't yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(cardsProvider);
      if (s.cards.isEmpty && !s.isLoading) {
        ref.read(cardsProvider.notifier).loadCards();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: error ? AppTheme.danger : AppTheme.success,
      ));
  }

  Future<void> _changePhoto() async {
    final user = ref.read(authProvider).user;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera,
                  color: AppTheme.orange),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image,
                  color: AppTheme.orange),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (user != null && user.avatarUrl.isNotEmpty)
              ListTile(
                leading: const Icon(LucideIcons.trash2,
                    color: AppTheme.danger),
                title: const Text('Remove photo',
                    style: TextStyle(color: AppTheme.danger)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    final notifier = ref.read(authProvider.notifier);

    if (choice == 'remove') {
      setState(() => _uploading = true);
      try {
        await notifier.updateProfile(avatarUrl: '', avatarId: '');
        _toast('Profile photo removed');
      } on AuthException catch (e) {
        _toast(e.message, error: true);
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
      return;
    }

    final xFile = await _picker.pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (xFile == null) return;

    final file = File(xFile.path);
    if (await file.length() > CardsRepository.maxImageBytes) {
      _toast('Image is too large — please pick one under 4MB.', error: true);
      return;
    }

    setState(() => _uploading = true);
    try {
      final up = await _cardsRepo.uploadImage(file);
      try {
        await notifier.updateProfile(avatarUrl: up.url, avatarId: up.publicId);
      } catch (_) {
        // Saved to Cloudinary but not to the profile: don't leave it orphaned.
        await _cardsRepo.discardUploads([up.publicId]);
        rethrow;
      }
      HapticFeedback.mediumImpact();
      _toast('Profile photo updated');
    } on CardsException catch (e) {
      _toast(e.message, error: true);
    } on AuthException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Something went wrong. Try again.', error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    FocusScope.of(context).unfocus();
    setState(() => _savingName = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(name: name);
      _toast('Name updated');
    } on AuthException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not update name.', error: true);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final cards = ref.watch(cardsProvider).cards;
    final favs = cards.where((c) => c.isFavorite).length;
    final nameChanged =
        _nameCtrl.text.trim().isNotEmpty && _nameCtrl.text.trim() != user?.name;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile'),
      ),
      body: AppBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
            child: Column(
              children: [
                // ── Avatar ───────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _uploading ? null : _changePhoto,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        UserAvatar(user: user, size: 132, ring: true),
                        if (_uploading)
                          Container(
                            width: 124,
                            height: 124,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.45),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 2,
                          bottom: 6,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Theme.of(context)
                                      .scaffoldBackgroundColor,
                                  width: 3),
                            ),
                            child: const Icon(LucideIcons.camera,
                                color: Colors.white, size: 17),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().scale(
                    begin: const Offset(0.85, 0.85),
                    duration: 500.ms,
                    curve: Curves.easeOutBack).fadeIn(),

                const SizedBox(height: 16),
                Text(user?.name ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColor(context),
                          letterSpacing: -0.5,
                        ))
                    .animate(delay: 100.ms)
                    .fadeIn()
                    .slideY(begin: 0.2),
                const SizedBox(height: 2),
                Text(user?.email ?? '',
                        style: GoogleFonts.outfit(
                            color: AppTheme.textSecColor(context)))
                    .animate(delay: 150.ms)
                    .fadeIn(),

                const SizedBox(height: 24),

                // ── Stats ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.pin_drop_rounded,
                        value: '${cards.length}',
                        label: 'Cards',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.star_rounded,
                        value: '$favs',
                        label: 'Favorites',
                      ),
                    ),
                  ],
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.15),

                const SizedBox(height: 24),

                // ── Details ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppTheme.cardDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DETAILS',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppTheme.mutedColor(context),
                          )),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon:
                              Icon(LucideIcons.user, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: ValueKey(user?.email),
                        initialValue: user?.email ?? '',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon:
                              Icon(LucideIcons.mail, size: 20),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: nameChanged
                            ? Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _savingName ? null : _saveName,
                                    child: _savingName
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : const Text('Save changes'),
                                  ),
                                ),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.12),

                const SizedBox(height: 16),
                Text('Tap your photo to change it · max 4MB',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppTheme.mutedColor(context))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatTile(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.orangeSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.orange, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor(context),
                    height: 1.1,
                  )),
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 12.5, color: AppTheme.textSecColor(context))),
            ],
          ),
        ],
      ),
    );
  }
}
