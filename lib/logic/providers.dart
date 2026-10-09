import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';
import '../data/models/address_card.dart';
import '../data/models/cards_page.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cards_repository.dart';
import '../data/local/token_storage.dart';
import '../data/local/settings_storage.dart';

// ─── Shell ───────────────────────────────────────────────────────────────────

/// Shared with the outer [AppShell] Scaffold so nested screens (Home, Cards)
/// can open its Drawer, which must live on the outer Scaffold to paint above
/// the floating bottom nav bar.
final scaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});

// ─── Repositories ─────────────────────────────────────────────────────────────

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());
final cardsRepositoryProvider =
    Provider<CardsRepository>((ref) => CardsRepository());

// ─── Auth State ────────────────────────────────────────────────────────────────

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith(
          {AppUser? user,
          bool? isLoading,
          String? error,
          bool clearUser = false}) =>
      AuthState(
        user: clearUser ? null : user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    if (!await TokenStorage.hasToken()) {
      state = const AuthState();
      return;
    }
    try {
      final user = await _repo.getMe();
      if (user == null) {
        // The server rejected the token (expired / invalid): sign out.
        await TokenStorage.clear();
        await UserCache.clear();
        state = const AuthState();
      } else {
        await UserCache.save(user);
        state = AuthState(user: user);
      }
    } catch (_) {
      // Offline or the server hiccuped: keep the token and stay signed in
      // with the last known profile instead of kicking the user out.
      final cached = await UserCache.load();
      state = cached != null ? AuthState(user: cached) : const AuthState();
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.login(email, password);
      await UserCache.save(user);
      state = AuthState(user: user);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong.');
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.signup(name, email, password);
      await UserCache.save(user);
      state = AuthState(user: user);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong.');
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    await UserCache.clear();
    state = const AuthState();
  }

  /// Deletes the account on the server, then signs out locally.
  /// Throws [AuthException] (e.g. wrong password) and leaves the user signed in.
  Future<void> deleteAccount(String password) async {
    await _repo.deleteAccount(password);
    await UserCache.clear();
    state = const AuthState();
  }

  /// Updates name and/or avatar. Throws [AuthException] on failure.
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    String? avatarId,
  }) async {
    final user = await _repo.updateProfile(
      name: name,
      avatarUrl: avatarUrl,
      avatarId: avatarId,
    );
    await UserCache.save(user);
    state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// ─── Cards State ─────────────────────────────────────────────────────────────

class CardsState {
  final List<AddressCard> cards;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  /// Current server-side search text and filter ('all' | 'fav' | category id).
  final String query;
  final String filter;

  /// Counts for the chips/empty states, independent of the current filter.
  final int allCount;
  final int favoriteCount;
  final List<String> categories;

  const CardsState({
    this.cards = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.query = '',
    this.filter = 'all',
    this.allCount = 0,
    this.favoriteCount = 0,
    this.categories = const [],
  });

  bool get isFiltered => query.trim().isNotEmpty || filter != 'all';

  CardsState copyWith({
    List<AddressCard>? cards,
    String? nextCursor,
    bool clearCursor = false,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? query,
    String? filter,
    int? allCount,
    int? favoriteCount,
    List<String>? categories,
  }) =>
      CardsState(
        cards: cards ?? this.cards,
        nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
        hasMore: hasMore ?? this.hasMore,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        query: query ?? this.query,
        filter: filter ?? this.filter,
        allCount: allCount ?? this.allCount,
        favoriteCount: favoriteCount ?? this.favoriteCount,
        categories: categories ?? this.categories,
      );
}

class CardsNotifier extends StateNotifier<CardsState> {
  final CardsRepository _repo;
  CardsNotifier(this._repo) : super(const CardsState());

  int _loadId = 0; // drop responses that arrive after a newer search/filter

  /// (Re)loads the first page for the current search + filter.
  Future<void> loadCards() async {
    final id = ++_loadId;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final page = await _repo.getCards(q: state.query, filter: state.filter);
      if (id != _loadId) return;
      state = state.copyWith(
        cards: page.cards,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasMore: page.hasMore,
        isLoading: false,
        isLoadingMore: false,
        // An older backend doesn't send counts: fall back to what we can see.
        allCount: page.allCount ?? page.cards.length,
        favoriteCount:
            page.favoriteCount ?? page.cards.where((c) => c.isFavorite).length,
        categories: page.categories ??
            page.cards.map((c) => c.category).where((c) => c.isNotEmpty).toSet().toList(),
      );
    } on CardsException catch (e) {
      if (id == _loadId) state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      if (id == _loadId) {
        state = state.copyWith(isLoading: false, error: 'Failed to load cards.');
      }
    }
  }

  Future<void> setQuery(String query) async {
    if (query.trim() == state.query.trim()) return;
    state = state.copyWith(query: query.trim());
    await loadCards();
  }

  Future<void> setFilter(String filter) async {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter);
    await loadCards();
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    final id = _loadId;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repo.getCards(
          cursor: state.nextCursor, q: state.query, filter: state.filter);
      if (id != _loadId) return; // a new search started meanwhile
      state = state.copyWith(
        cards: [...state.cards, ...page.cards],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      if (id == _loadId) state = state.copyWith(isLoadingMore: false);
    }
  }

  bool _matches(AddressCard c) =>
      cardMatches(c, filter: state.filter, query: state.query);

  Future<AddressCard?> createCard({
    required String digipin,
    required String title,
    String humanAddress = '',
    List<String> photoUrls = const [],
    List<String> photoIds = const [],
    String category = '',
    String deliveryNote = '',
    String contactPhone = '',
  }) async {
    try {
      final card = await _repo.createCard(
        digipin: digipin,
        title: title,
        humanAddress: humanAddress,
        photoUrls: photoUrls,
        photoIds: photoIds,
        category: category,
        deliveryNote: deliveryNote,
        contactPhone: contactPhone,
      );
      state = state.copyWith(
        cards: _matches(card) ? [card, ...state.cards] : state.cards,
        allCount: state.allCount + 1,
        favoriteCount: state.favoriteCount + (card.isFavorite ? 1 : 0),
        categories: card.category.isEmpty || state.categories.contains(card.category)
            ? state.categories
            : [...state.categories, card.category],
      );
      return card;
    } on CardsException {
      rethrow; // message is shown to the user by the create screen
    } catch (_) {
      throw const CardsException('Could not save the card. Please try again.');
    }
  }

  /// Replaces [card] in the list, or drops it when it no longer matches the
  /// active filter (e.g. unfavorited while viewing Favorites).
  void _replace(AddressCard card) {
    final keep = _matches(card);
    state = state.copyWith(
      cards: [
        for (final c in state.cards)
          if (c.id != card.id) c else if (keep) card,
      ],
    );
  }

  Future<AddressCard?> updateCard(
    String id, {
    String? title,
    String? humanAddress,
    List<String>? photoUrls,
    List<String>? photoIds,
    String? category,
    String? deliveryNote,
    String? contactPhone,
  }) async {
    final card = await _repo.updateCard(
      id,
      title: title,
      humanAddress: humanAddress,
      photoUrls: photoUrls,
      photoIds: photoIds,
      category: category,
      deliveryNote: deliveryNote,
      contactPhone: contactPhone,
    );
    _replace(card);
    return card;
  }

  /// Changes sharing settings (on/off, expiry, hide phone, reset link) and
  /// returns the updated card (which carries the new token after a reset).
  Future<AddressCard> updateSharing(
    String id, {
    bool? sharingEnabled,
    bool? hidePhone,
    String? shareExpiry,
    bool resetShareLink = false,
  }) async {
    final card = await _repo.updateCard(
      id,
      sharingEnabled: sharingEnabled,
      hidePhone: hidePhone,
      shareExpiry: shareExpiry,
      resetShareLink: resetShareLink,
    );
    _replace(card);
    return card;
  }

  /// Optimistically flips the favorite flag; rolls back if the request fails.
  Future<bool> toggleFavorite(AddressCard card) async {
    final next = !card.isFavorite;
    _replace(card.copyWith(isFavorite: next));
    state = state.copyWith(favoriteCount: state.favoriteCount + (next ? 1 : -1));
    try {
      await _repo.updateCard(card.id, isFavorite: next);
      return true;
    } catch (_) {
      // roll back list + count (re-insert at its old position is not needed:
      // a pull-to-refresh restores order; keep it simple and correct)
      final exists = state.cards.any((c) => c.id == card.id);
      state = state.copyWith(
        cards: exists
            ? [for (final c in state.cards) c.id == card.id ? card : c]
            : [card, ...state.cards],
        favoriteCount: state.favoriteCount + (next ? -1 : 1),
      );
      return false;
    }
  }

  Future<void> deleteCard(String id) async {
    final removed = state.cards.where((c) => c.id == id).toList();
    await _repo.deleteCard(id); // also deletes the card's photos server-side
    state = state.copyWith(
      cards: state.cards.where((c) => c.id != id).toList(),
      allCount: (state.allCount - 1).clamp(0, 1 << 30),
      favoriteCount: removed.isNotEmpty && removed.first.isFavorite
          ? (state.favoriteCount - 1).clamp(0, 1 << 30)
          : state.favoriteCount,
    );
  }

  /// Forget everything (used on logout / account deletion).
  void reset() {
    _loadId++;
    state = const CardsState();
  }
}

final cardsProvider = StateNotifierProvider<CardsNotifier, CardsState>((ref) {
  return CardsNotifier(ref.read(cardsRepositoryProvider));
});

// ─── Theme ───────────────────────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _init();
  }

  Future<void> _init() async {
    state = await SettingsStorage.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await SettingsStorage.setThemeMode(mode);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// ─── Sound ───────────────────────────────────────────────────────────────────

class SoundEnabledNotifier extends StateNotifier<bool> {
  SoundEnabledNotifier() : super(true) {
    _init();
  }

  Future<void> _init() async {
    state = await SettingsStorage.getSoundEnabled();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    state = enabled;
    await SettingsStorage.setSoundEnabled(enabled);
  }
}

final soundEnabledProvider =
    StateNotifierProvider<SoundEnabledNotifier, bool>((ref) {
  return SoundEnabledNotifier();
});
