import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/providers.dart';
import '../screens/settings_drawer.dart';

/// Wraps the main tabs in a persistent, floating pill-shaped bottom bar:
///
///   Home · Scan · [ + ] · Cards · Compass
///
/// The centre "+" is an action (create a card), not a tab, so the shell has
/// four branches while the bar has five slots. Each tab keeps its own
/// navigation stack via [navigationShell].
///
/// The settings Drawer lives here (not on the nested tab Scaffolds) so it
/// paints above the floating bar — a Drawer only overlays its own Scaffold's
/// bottomNavigationBar, and the bar belongs to this outer one.
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  // bar slot -> shell branch (slot 2 is the "+" action, no branch)
  static const _slotToBranch = {0: 0, 1: 1, 3: 2, 4: 3};

  int get _selectedSlot {
    final i = navigationShell.currentIndex;
    return _slotToBranch.entries.firstWhere((e) => e.value == i).key;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: ref.watch(scaffoldKeyProvider),
      extendBody: true,
      drawer: const SettingsDrawer(),
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _FloatingNavBar(
          selectedSlot: _selectedSlot,
          onSlot: (slot) {
            if (slot == 2) {
              HapticFeedback.mediumImpact();
              context.push('/create');
              return;
            }
            final branch = _slotToBranch[slot]!;
            navigationShell.goBranch(
              branch,
              initialLocation: branch == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int selectedSlot;
  final ValueChanged<int> onSlot;
  const _FloatingNavBar({required this.selectedSlot, required this.onSlot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: selectedSlot == 0,
                    onTap: () => onSlot(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan',
                    selected: selectedSlot == 1,
                    onTap: () => onSlot(1),
                  ),
                ),
                const SizedBox(width: 68), // room for the raised "+"
                Expanded(
                  child: _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Cards',
                    selected: selectedSlot == 3,
                    onTap: () => onSlot(3),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.explore_rounded,
                    label: 'Compass',
                    selected: selectedSlot == 4,
                    onTap: () => onSlot(4),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: _AddButton(onTap: () => onSlot(2)),
          ),
        ],
      ),
    );
  }
}

/// Raised, rounded "+" in the middle of the bar.
class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New address card',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.9 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor, width: 4),
              boxShadow: const [
                BoxShadow(
                    color: AppTheme.orangeGlow,
                    blurRadius: 22,
                    offset: Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.orange : Theme.of(context).hintColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!selected) HapticFeedback.selectionClick();
        onTap();
      },
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppTheme.orangeSubtle : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
