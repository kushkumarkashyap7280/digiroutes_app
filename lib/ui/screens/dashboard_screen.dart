import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              : RefreshIndicator(
                  color: AppTheme.orange,
                  onRefresh: () => ref.read(cardsProvider.notifier).loadCards(),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: cards.cards.length +
                        (cards.isLoadingMore ? 2 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= cards.cards.length) {
                        return _ShimmerCardItem();
                      }
                      return _CardItem(
                        card: cards.cards[i],
                        index: i,
                        onTap: () => context.push(
                            '/card/${cards.cards[i].digipin}'),
                        onDelete: () => _confirmDelete(cards.cards[i]),
                      );
                    },
                  ),
                ),
    );
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
      await ref.read(cardsProvider.notifier).deleteCard(card.id);
    }
  }
}

// ─── Card item ────────────────────────────────────────────────────────────────

class _CardItem extends StatelessWidget {
  final AddressCard card;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CardItem({
    required this.card,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppTheme.cardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo / placeholder
            Expanded(
              child: ClipRRect(
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
                                color: AppTheme.mutedColor(context), size: 32),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _PlaceholderPhoto(),
                      )
                    : _PlaceholderPhoto(),
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
                        onTap: onDelete,
                        child: Icon(Icons.delete_outline,
                            size: 16, color: AppTheme.mutedColor(context)),
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
                color: AppTheme.orange.withOpacity(0.4), size: 36),
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
            Text('Create your first card to share\nyour exact doorstep location.',
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
