import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/providers.dart';
import '../widgets/logout.dart';
import '../widgets/user_avatar.dart';

/// Side menu: account stuff only (profile, settings, share, logout) — the
/// tabs live in the bottom bar, so nothing is duplicated here. Preferences
/// live on the Settings page and
/// Logout is pinned to the bottom (with a confirmation) so it can't be hit
/// by accident. Rows deliberately give no ripple / sound / haptic feedback.
class SettingsDrawer extends ConsumerWidget {
  const SettingsDrawer({super.key});

  void _go(BuildContext context, WidgetRef ref, String location,
      {bool push = false}) {
    ref.read(scaffoldKeyProvider).currentState?.closeDrawer();
    if (push) {
      context.push(location);
    } else {
      context.go(location);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Theme(
        // Kill every touch effect inside the drawer.
        data: theme.copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _go(context, ref, '/profile', push: true),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.orangeGlow,
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: UserAvatar(user: user, size: 56),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Your profile',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),

              // ── Navigation ───────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    _DrawerItem(
                      icon: LucideIcons.user,
                      label: 'Profile',
                      onTap: () => _go(context, ref, '/profile', push: true),
                    ),
                    _DrawerItem(
                      icon: LucideIcons.settings,
                      label: 'Settings',
                      onTap: () => _go(context, ref, '/settings', push: true),
                    ),
                    _DrawerItem(
                      icon: LucideIcons.share2,
                      label: 'Share DigiRoutes',
                      onTap: () {
                        ref.read(scaffoldKeyProvider).currentState?.closeDrawer();
                        Share.share(
                            'Share your exact doorstep with DigiRoutes — '
                            'https://github.com/kushkumarkashyap7280/digiroutes_app/releases/latest');
                      },
                    ),
                  ],
                ),
              ),

              // ── Logout (bottom, confirmed) ───────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => confirmAndLogout(context, ref),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.danger.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.logOut,
                            color: AppTheme.danger, size: 20),
                        const SizedBox(width: 10),
                        Text('Log out',
                            style: GoogleFonts.outfit(
                              color: AppTheme.danger,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppTheme.textSecColor(context)),
            const SizedBox(width: 16),
            Text(label,
                style: GoogleFonts.outfit(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor(context),
                )),
          ],
        ),
      ),
    );
  }
}
