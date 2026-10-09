import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/sound.dart';
import '../../core/theme/app_theme.dart';
import '../../core/update_checker.dart';
import '../../core/widgets/backdrop.dart';
import '../../logic/providers.dart';
import '../widgets/delete_account.dart';
import '../widgets/logout.dart';
import '../widgets/user_avatar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _version = p.version);
    });
  }

  Future<void> _checkUpdates() async {
    setState(() => _checking = true);
    final info = await UpdateChecker.check();
    if (!mounted) return;
    setState(() => _checking = false);
    if (info == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("You're on the latest version.",
            style: GoogleFonts.outfit()),
      ));
    } else {
      await maybePromptUpdate(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final themeMode = ref.watch(themeModeProvider);
    final sound = ref.watch(soundEnabledProvider);

    final sections = <Widget>[
      // ── Account ────────────────────────────────────────────────────
      _Group(
        label: 'Account',
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/profile'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  UserAvatar(user: user, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '',
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textColor(context))),
                        Text(user?.email ?? '',
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppTheme.textSecColor(context))),
                      ],
                    ),
                  ),
                  Text('Edit',
                      style: GoogleFonts.outfit(
                          color: AppTheme.orange,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.chevronRight,
                      size: 16, color: AppTheme.orange),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Appearance ─────────────────────────────────────────────────
      _Group(
        label: 'Appearance',
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _ThemeTile(
                  label: 'Light',
                  icon: LucideIcons.sun,
                  selected: themeMode == ThemeMode.light,
                  previewBg: Colors.white,
                  previewFg: AppTheme.lightText,
                  onTap: () => _setTheme(ThemeMode.light),
                ),
                const SizedBox(width: 10),
                _ThemeTile(
                  label: 'Dark',
                  icon: LucideIcons.moon,
                  selected: themeMode == ThemeMode.dark,
                  previewBg: AppTheme.darkBg,
                  previewFg: Colors.white,
                  onTap: () => _setTheme(ThemeMode.dark),
                ),
                const SizedBox(width: 10),
                _ThemeTile(
                  label: 'Auto',
                  icon: LucideIcons.smartphone,
                  selected: themeMode == ThemeMode.system,
                  previewBg: null,
                  previewFg: Colors.white,
                  onTap: () => _setTheme(ThemeMode.system),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Preferences ────────────────────────────────────────────────
      _Group(
        label: 'Preferences',
        children: [
          _SwitchRow(
            icon: LucideIcons.volume2,
            title: 'Sound & haptics',
            subtitle: 'Subtle click and vibration on key actions',
            value: sound,
            onChanged: (v) async {
              await ref.read(soundEnabledProvider.notifier).setSoundEnabled(v);
              if (v && mounted) AppSound.tap(ref);
            },
          ),
        ],
      ),

      // ── About ──────────────────────────────────────────────────────
      _Group(
        label: 'About',
        children: [
          _ActionRow(
            icon: LucideIcons.refreshCw,
            title: 'Check for updates',
            trailing: _checking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.orange))
                : null,
            onTap: _checking ? null : _checkUpdates,
          ),
          const Divider(height: 1, indent: 58),
          _ActionRow(
            icon: LucideIcons.info,
            title: 'Version',
            trailing: Text(_version.isEmpty ? '—' : 'v$_version',
                style: GoogleFonts.outfit(
                    color: AppTheme.textSecColor(context))),
          ),
        ],
      ),

      // ── Session ────────────────────────────────────────────────────
      _Group(
        label: 'Session & data',
        children: [
          _ActionRow(
            icon: LucideIcons.userX,
            title: 'Delete account',
            danger: true,
            onTap: () => confirmAndDeleteAccount(context, ref),
          ),
          const Divider(height: 1, indent: 58),
          _ActionRow(
            icon: LucideIcons.logOut,
            title: 'Log out',
            danger: true,
            onTap: () => confirmAndLogout(context, ref),
          ),
        ],
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: AppBackdrop(
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 64, 20, 32),
            itemCount: sections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 22),
            itemBuilder: (_, i) => sections[i]
                .animate(delay: Duration(milliseconds: 60 * i))
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          ),
        ),
      ),
    );
  }

  void _setTheme(ThemeMode m) {
    HapticFeedback.selectionClick();
    ref.read(themeModeProvider.notifier).setThemeMode(m);
  }
}

class _Group extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _Group({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(label.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppTheme.mutedColor(context),
              )),
        ),
        Container(
          decoration: AppTheme.cardDecoration(context),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final bool danger;
  const _IconChip({required this.icon, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final c = danger ? AppTheme.danger : AppTheme.orange;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 19, color: c),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool danger;
  final VoidCallback? onTap;
  const _ActionRow({
    required this.icon,
    required this.title,
    this.trailing,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            _IconChip(icon: icon, danger: danger),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.outfit(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: danger
                        ? AppTheme.danger
                        : AppTheme.textColor(context),
                  )),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _IconChip(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textColor(context))),
                Text(subtitle,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppTheme.mutedColor(context))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.orange,
          ),
        ],
      ),
    );
  }
}

/// Mini preview of a theme; the selected one gets an orange ring + check.
class _ThemeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color? previewBg; // null => split light/dark (Auto)
  final Color previewFg;
  final VoidCallback onTap;
  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.previewBg,
    required this.previewFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? AppTheme.orange
                      : AppTheme.borderColor(context),
                  width: selected ? 2.2 : 1,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(color: AppTheme.orangeGlow, blurRadius: 14)
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    previewBg != null
                        ? ColoredBox(color: previewBg!)
                        : Row(children: [
                            const Expanded(child: ColoredBox(color: Colors.white)),
                            Expanded(child: ColoredBox(color: AppTheme.darkBg)),
                          ]),
                    Center(
                      child: Icon(
                        icon,
                        size: 26,
                        color: previewBg == Colors.white
                            ? AppTheme.orange
                            : (previewBg == null
                                ? AppTheme.orange
                                : AppTheme.orangeLight),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                              color: AppTheme.orange, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.check,
                              size: 11, color: Colors.white),
                        ).animate().scale(
                            duration: 250.ms, curve: Curves.easeOutBack),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppTheme.orange
                      : AppTheme.textSecColor(context),
                )),
          ],
        ),
      ),
    );
  }
}
