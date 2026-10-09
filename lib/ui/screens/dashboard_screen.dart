import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/sound.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/address_card.dart';
import '../../logic/providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();
  bool _onlyFavorites = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cardsProvider.notifier).loadCards();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(cardsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardsProvider);
    final q = _query.trim().toLowerCase();
    final visible = cards.cards.where((c) {
      if (_onlyFavorites && !c.isFavorite) return false;
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          c.digipin.toLowerCase().contains(q) ||
          c.humanAddress.toLowerCase().contains(q);
    }).toList()
      // favorites float to the top, otherwise keep server (newest-first) order
      ..sort((a, b) => (b.isFavorite ? 1 : 0) - (a.isFavorite ? 1 : 0));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () =>
              ref.read(scaffoldKeyProvider).currentState?.openDrawer(),
        ),
        title: Text('My Cards',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
            )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => context.push('/create'),
              icon: const Icon(Icons.add, size: 18),
              label: Text('New',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.orange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: cards.isLoading
          ? _ShimmerGrid()
          : cards.cards.isEmpty
              ? const _EmptyState()
              : Column(
                  children: [
                    _SearchBar(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      onlyFavorites: _onlyFavorites,
                      favCount: cards.cards.where((c) => c.isFavorite).length,
                      onToggleFavorites: (v) =>
                          setState(() => _onlyFavorites = v),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? _NoMatches(onlyFavorites: _onlyFavorites)
                          : RefreshIndicator(
                              color: AppTheme.orange,
                              onRefresh: () =>
                                  ref.read(cardsProvider.notifier).loadCards(),
                              child: GridView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.78,
                                ),
                                itemCount: visible.length +
                                    (cards.isLoadingMore ? 2 : 0),
                                itemBuilder: (ctx, i) {
                                  if (i >= visible.length) {
                                    return _ShimmerCardItem();
                                  }
                                  final card = visible[i];
                                  return _CardItem(
                                    key: ValueKey(card.id),
                                    card: card,
                                    index: i,
                                    onTap: () =>
                                        context.push('/card/${card.digipin}'),
                                    onFavorite: () => _toggleFavorite(card),
                                    onMenu: () => _showActions(card),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _toggleFavorite(AddressCard card) async {
    AppSound.tap(ref);
    final wasFav = card.isFavorite;
    final ok = await ref.read(cardsProvider.notifier).toggleFavorite(card);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(
        ok
            ? (wasFav
                ? 'Removed "${card.title}" from favorites'
                : 'Added "${card.title}" to favorites')
            : 'Could not update favorite. Try again.',
        style: GoogleFonts.outfit(),
      ),
      backgroundColor: ok ? AppTheme.success : AppTheme.danger,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _showActions(AddressCard card) async {
    HapticFeedback.mediumImpact();
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                  card.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: AppTheme.orange),
              title: Text(card.isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites'),
              onTap: () => Navigator.pop(ctx, 'fav'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppTheme.orange),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: AppTheme.orange),
              title: const Text('Share'),
              onTap: () => Navigator.pop(ctx, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.danger),
              title: const Text('Delete',
                  style: TextStyle(color: AppTheme.danger)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'fav':
        await _toggleFavorite(card);
      case 'edit':
        await context.push('/edit', extra: card);
      case 'share':
        await Share.share(
          '${card.title}\nDIGIPIN: ${card.digipin}\n${card.shareUrl}',
          subject: card.title,
        );
      case 'delete':
        await _confirmDelete(card);
    }
  }

  Future<void> _confirmDelete(AddressCard card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Card',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Delete "${card.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: Text('Delete',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(cardsProvider.notifier).deleteCard(card.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Deleted "${card.title}"', style: GoogleFonts.outfit()),
          duration: const Duration(seconds: 2),
        ));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete card.', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }
}

// ─── Card item ────────────────────────────────────────────────────────────────

class _CardItem extends StatefulWidget {
  final AddressCard card;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onMenu;

  const _CardItem({
    super.key,
    required this.card,
    required this.index,
    required this.onTap,
    required this.onFavorite,
    required this.onMenu,
  });

  @override
  State<_CardItem> createState() => _CardItemState();
}

class _CardItemState extends State<_CardItem> {
  bool _pressed = false;

  AddressCard get card => widget.card;
  int get index => widget.index;
  VoidCallback get onTap => widget.onTap;
  VoidCallback get onFavorite => widget.onFavorite;
  VoidCallback get onMenu => widget.onMenu;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onMenu,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: AppTheme.cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo / placeholder
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(15)),
                      child: card.photoUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: card.photoUrls.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (_, __) => Container(
                                color: AppTheme.surface2Color(context),
                                child: Center(
                                  child: Icon(Icons.image_outlined,
                                      color: AppTheme.mutedColor(context),
                                      size: 32),
                                ),
                              ),
                              errorWidget: (_, __, ___) => _PlaceholderPhoto(),
                            )
                          : _PlaceholderPhoto(),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (c, a) =>
                                ScaleTransition(scale: a, child: c),
                            child: Icon(
                              card.isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              key: ValueKey(card.isFavorite),
                              size: 20,
                              color: card.isFavorite
                                  ? AppTheme.orange
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            card.digipin,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.orange,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: onMenu,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(Icons.more_horiz_rounded,
                                size: 18, color: AppTheme.mutedColor(context)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: 50 * index))
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, end: 0),
      ),
    );
  }
}

class _PlaceholderPhoto extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface2Color(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_rounded,
                color: AppTheme.orange.withValues(alpha: 0.4), size: 36),
            const SizedBox(height: 4),
            Text('No photo',
                style: GoogleFonts.outfit(
                    color: AppTheme.mutedColor(context), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─── Search + filter ──────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool onlyFavorites;
  final int favCount;
  final ValueChanged<bool> onToggleFavorites;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onlyFavorites,
    required this.favCount,
    required this.onToggleFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search title, address or DIGIPIN',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: !onlyFavorites,
                  onSelected: (_) => onToggleFavorites(false),
                  selectedColor: AppTheme.orangeSubtle,
                ),
                ChoiceChip(
                  avatar: Icon(Icons.star_rounded,
                      size: 16, color: onlyFavorites ? AppTheme.orange : null),
                  label: Text('Favorites ($favCount)'),
                  selected: onlyFavorites,
                  onSelected: (_) => onToggleFavorites(true),
                  selectedColor: AppTheme.orangeSubtle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  final bool onlyFavorites;
  const _NoMatches({required this.onlyFavorites});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        onlyFavorites
            ? 'No favorites yet — tap the star on a card.'
            : 'No cards match your search.',
        style: GoogleFonts.outfit(color: AppTheme.mutedColor(context)),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: const Icon(Icons.add_location_alt_outlined,
                  color: AppTheme.orange, size: 48),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text('No address cards yet',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor(context),
                )).animate(delay: 150.ms).fadeIn(),
            const SizedBox(height: 8),
            Text(
                'Create your first card to share\nyour exact doorstep location.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textSecColor(context),
                  height: 1.5,
                )).animate(delay: 200.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer loading ──────────────────────────────────────────────────────────

class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _ShimmerCardItem(),
    );
  }
}

class _ShimmerCardItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceColor(context),
      highlightColor: AppTheme.surface2Color(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
