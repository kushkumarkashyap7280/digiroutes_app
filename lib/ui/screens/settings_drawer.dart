import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/sound.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/providers.dart';

class SettingsDrawer extends ConsumerWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ── Profile ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    auth.user?.name ?? 'Profile',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 12),

            // ── Theme ────────────────────────────────────────────────
            _SectionLabel('Theme'),
            const SizedBox(height: 10),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Light')),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Dark')),
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.settings_suggest_outlined),
                    label: Text('Auto')),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).setThemeMode(s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 24),

            // ── Sound ────────────────────────────────────────────────
            _SectionLabel('Sound'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Tap feedback',
                  style: GoogleFonts.outfit(
                      color: theme.textTheme.bodyLarge?.color)),
              subtitle: Text('Haptic + click on key actions',
                  style:
                      GoogleFonts.outfit(fontSize: 12, color: theme.hintColor)),
              activeThumbColor: AppTheme.orange,
              value: soundEnabled,
              onChanged: (v) async {
                await ref
                    .read(soundEnabledProvider.notifier)
                    .setSoundEnabled(v);
                if (v) AppSound.tap(ref);
              },
            ),
            const SizedBox(height: 12),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 12),

            // ── Logout ───────────────────────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout, color: AppTheme.danger),
              title: Text('Logout',
                  style: GoogleFonts.outfit(
                      color: AppTheme.danger, fontWeight: FontWeight.w600)),
              onTap: () async {
                AppSound.tap(ref);
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: Theme.of(context).hintColor,
      ),
    );
  }
}
